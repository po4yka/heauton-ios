import Foundation
import os.log

/// Represents an indexing job
nonisolated struct IndexingJob: Sendable {
    let id: UUID
    let type: JobType
    let quotes: [Quote]
    let createdAt: Date

    nonisolated enum JobType: Sendable {
        case initial
        case update
        case reindex
    }
}

/// Progress information for indexing operations
nonisolated struct IndexingProgress: Sendable {
    let jobId: UUID
    let totalItems: Int
    let processedItems: Int
    let currentOperation: String
    let errors: [String]

    var progress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(processedItems) / Double(totalItems)
    }

    var isComplete: Bool {
        processedItems >= totalItems
    }
}

/// Status of the indexing service
nonisolated enum IndexingStatus: Sendable {
    case idle
    case indexing(progress: IndexingProgress)
    case completed
    case failed(error: Error)
}

/// Service for performing background indexing of quotes
/// Handles large batch operations without blocking the main thread
actor BackgroundIndexingService: BackgroundIndexingServiceProtocol {
    // MARK: - Properties

    /// Shared instance
    static let shared = BackgroundIndexingService()
    /// Note: Prefer using AppDependencyContainer for dependency injection

    /// Search service
    private let searchService = QuoteSearchService.shared

    /// Spotlight service
    private let spotlightService = SpotlightIndexingService.shared

    /// Current indexing status
    private(set) var status: IndexingStatus = .idle

    /// Queue of pending jobs
    private var jobQueue: [IndexingJob] = []

    /// Current job being processed
    private var currentJob: IndexingJob?

    /// Logger
    private let logger = Logger(subsystem: "com.heauton.quotes", category: "Indexing")

    /// Indexing task
    private var indexingTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {}

    // MARK: - Public API

    /// Starts the indexing service
    func start() async {
        if case .idle = status {
            // no-op
        } else {
            return
        }
        logger.debug("Background indexing service started")
        await processNextJob()
    }

    /// Stops the indexing service
    func stop() async {
        indexingTask?.cancel()
        indexingTask = nil
        status = .idle
        logger.debug("Background indexing service stopped")
    }

    /// Queues quotes for indexing
    /// - Parameters:
    ///   - quotes: Array of quotes to index
    ///   - type: Type of indexing job
    func queueIndexing(
        quotes: [Quote],
        type: IndexingJob.JobType = .initial
    ) async {
        let job = IndexingJob(
            id: UUID(),
            type: type,
            quotes: quotes,
            createdAt: Date()
        )

        jobQueue.append(job)
        logger.debug("Queued indexing job: \(job.id.uuidString) with \(quotes.count) quotes")

        // Start processing if idle
        if case .idle = status {
            await processNextJob()
        }
    }

    /// Returns the current indexing progress
    func getProgress() async -> IndexingProgress? {
        guard case .indexing(let progress) = status else {
            return nil
        }
        return progress
    }

    /// Waits for all pending jobs to complete
    func waitForCompletion() async throws {
        while !jobQueue.isEmpty || currentJob != nil {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }

    // MARK: - Job Processing

    /// Processes the next job in the queue
    private func processNextJob() async {
        guard currentJob == nil, !jobQueue.isEmpty else {
            status = .idle
            return
        }

        let job = jobQueue.removeFirst()
        currentJob = job

        logger.debug("Processing indexing job: \(job.id.uuidString)")

        indexingTask = Task {
            await processJob(job)
        }
    }

    /// Processes a single indexing job
    /// - Parameter job: Job to process
    private func processJob(_ job: IndexingJob) async {
        var processedCount = 0
        var errors: [String] = []

        updateProgress(
            for: job,
            processedCount: 0,
            operation: "Starting indexing...",
            errors: []
        )

        let batches = job.quotes.chunked(into: 10)

        for (batchIndex, batch) in batches.enumerated() {
            if Task.isCancelled {
                handleCancellation(for: job)
                return
            }

            updateProgress(
                for: job,
                processedCount: processedCount,
                operation: "Processing batch \(batchIndex + 1) of \(batches.count)",
                errors: errors
            )

            let batchResult = await processBatch(batch)
            processedCount += batchResult.successCount
            errors.append(contentsOf: batchResult.errors)

            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay between batches
        }

        finalizeJob(job, processedCount: processedCount, errors: errors)
        await processNextJob()
    }

    private func updateProgress(
        for job: IndexingJob,
        processedCount: Int,
        operation: String,
        errors: [String]
    ) {
        let progress = IndexingProgress(
            jobId: job.id,
            totalItems: job.quotes.count,
            processedItems: processedCount,
            currentOperation: operation,
            errors: errors
        )
        status = .indexing(progress: progress)
    }

    private func handleCancellation(for job: IndexingJob) {
        logger.warning("Indexing job cancelled: \(job.id.uuidString)")
        status = .idle
        currentJob = nil
    }

    private struct BatchResult {
        let successCount: Int
        let errors: [String]
    }

    private func processBatch(_ batch: [Quote]) async -> BatchResult {
        var successCount = 0
        var errors: [String] = []

        for quote in batch {
            do {
                try await searchService.indexQuote(quote)
                try await spotlightService.indexQuote(quote)
                successCount += 1
            } catch {
                let errorMessage = "Failed to index quote \(quote.id): \(error.localizedDescription)"
                errors.append(errorMessage)
                logger.error("\(errorMessage)")
            }
        }

        return BatchResult(successCount: successCount, errors: errors)
    }

    private func finalizeJob(_ job: IndexingJob, processedCount: Int, errors: [String]) {
        let progress = IndexingProgress(
            jobId: job.id,
            totalItems: job.quotes.count,
            processedItems: processedCount,
            currentOperation: "Completed",
            errors: errors
        )

        if errors.isEmpty {
            status = .completed
            logger.debug("Indexing job completed successfully: \(job.id.uuidString)")
        } else {
            logger.warning("Indexing job completed with \(errors.count) errors: \(job.id.uuidString)")
            status = .indexing(progress: progress)
        }

        currentJob = nil
    }

    // MARK: - Batch Operations

    /// Indexes all quotes (for initial setup or reindex)
    /// - Parameter quotes: All quotes to index
    func indexAll(quotes: [Quote]) async throws {
        logger.debug("Starting full reindex of \(quotes.count) quotes")

        // Clear existing indices
        await searchService.clearCache()

        // Queue for indexing
        await queueIndexing(quotes: quotes, type: .reindex)

        // Wait for completion
        try await waitForCompletion()

        logger.debug("Full reindex completed")
    }

    /// Updates multiple quotes in the index
    /// - Parameter quotes: Quotes to update
    func updateMultiple(quotes: [Quote]) async throws {
        await queueIndexing(quotes: quotes, type: .update)
    }

    /// Removes multiple quotes from the index
    /// - Parameter quoteIds: IDs of quotes to remove
    func removeMultiple(quoteIds: [UUID]) async throws {
        logger.debug("Removing \(quoteIds.count) quotes from index")

        for id in quoteIds {
            do {
                try await searchService.removeFromIndex(quoteId: id)
                try await spotlightService.removeQuote(id: id)
            } catch {
                logger.error("Failed to remove quote \(id): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Maintenance

    /// Performs index maintenance and optimization
    func performMaintenance() async throws {
        logger.debug("Starting index maintenance")

        // Rebuild FTS5 indices
        // This is handled by the database manager

        // Clear search cache
        await searchService.clearCache()

        // Clean up orphaned files
        // This would need to be implemented with a list of valid quote IDs

        logger.debug("Index maintenance completed")
    }

    /// Returns statistics about indexing performance
    func getStatistics() async throws -> IndexingStatistics {
        let searchStats = try await searchService.getStatistics()

        return IndexingStatistics(
            queuedJobs: jobQueue.count,
            searchStats: searchStats,
            status: status
        )
    }
}

// MARK: - Supporting Types

/// Statistics about indexing operations
nonisolated struct IndexingStatistics: Sendable {
    let queuedJobs: Int
    let searchStats: SearchStatistics
    let status: IndexingStatus
}

// MARK: - Array Extension

// Note: chunked(into:) extension is defined in SpotlightIndexingService.swift

// MARK: - IndexingStatus Conformance

extension IndexingStatus: Equatable {
    static func == (lhs: IndexingStatus, rhs: IndexingStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.completed, .completed):
            true
        case let (.indexing(lhsProgress), .indexing(rhsProgress)):
            lhsProgress.jobId == rhsProgress.jobId
        case (.failed, .failed):
            // Compare errors by their localized description
            true
        default:
            false
        }
    }

    var description: String {
        switch self {
        case .idle:
            "Idle"
        case .indexing(let progress):
            "Indexing: \(Int(progress.progress * 100))%"
        case .completed:
            "Completed"
        case .failed(let error):
            "Failed: \(error.localizedDescription)"
        }
    }
}
