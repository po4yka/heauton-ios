import Foundation
import OSLog
import SwiftData
import UniformTypeIdentifiers

/// Service for exporting user data to various formats
actor DataExportService: DataExportServiceProtocol {
    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "DataExport")
    private let journalService: JournalServiceProtocol
    private let modelContext: ModelContext

    init(journalService: JournalServiceProtocol, modelContext: ModelContext) {
        self.journalService = journalService
        self.modelContext = modelContext
    }

    // MARK: - Export Operations

    /// Exports all user data to a complete backup file
    func exportCompleteBackup() async throws -> URL {
        logger.debug("Starting complete backup export")

        let backup = try await CompleteBackup(
            metadata: BackupMetadata(
                version: "1.0",
                exportDate: Date.now,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ),
            journals: exportJournals(),
            quotes: exportQuotes(),
            exercises: exportExercises(),
            progress: exportProgress(),
            achievements: exportAchievements()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(backup)
        return try saveToTemporaryFile(data: data, filename: "heauton_backup_\(dateString()).json")
    }

    /// Exports journal entries only
    func exportJournals() async throws -> [ExportedJournalEntry] {
        logger.debug("Exporting journal entries")

        let fetchDescriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\JournalEntry.createdAt, order: .reverse)]
        )

        let entries = try modelContext.fetch(fetchDescriptor)

        // Decrypt entries if encrypted
        var exportedEntries: [ExportedJournalEntry] = []

        for entry in entries {
            let decryptedContent: String
            if entry.isEncrypted {
                do {
                    if let decryptedEntry = try await journalService.fetchEntry(id: entry.id) {
                        decryptedContent = decryptedEntry.decryptedContent
                    } else {
                        decryptedContent = "[ENCRYPTED - Entry not found]"
                    }
                } catch {
                    logger.error("Failed to decrypt journal entry \(entry.id): \(error.localizedDescription)")
                    decryptedContent = "[ENCRYPTED - Could not decrypt]"
                }
            } else {
                decryptedContent = entry.content
            }

            let exported = ExportedJournalEntry(
                id: entry.id.uuidString,
                title: entry.title,
                content: decryptedContent,
                createdAt: entry.createdAt,
                updatedAt: entry.updatedAt,
                mood: entry.mood?.rawValue,
                tags: entry.tags,
                wordCount: entry.wordCount,
                isPinned: entry.isPinned,
                isFavorite: entry.isFavorite
            )
            exportedEntries.append(exported)
        }

        logger.debug("Exported \(exportedEntries.count) journal entries")
        return exportedEntries
    }

    /// Exports quotes
    func exportQuotes() async throws -> [ExportedQuote] {
        logger.debug("Exporting quotes")

        let fetchDescriptor = FetchDescriptor<Quote>(
            sortBy: [SortDescriptor(\Quote.createdAt, order: .reverse)]
        )

        let quotes = try modelContext.fetch(fetchDescriptor)

        let exported = quotes.map { quote in
            ExportedQuote(
                id: quote.id.uuidString,
                author: quote.author,
                text: quote.text,
                source: quote.source,
                category: quote.categories?.first,
                tags: quote.tags ?? [],
                isFavorite: quote.isFavorite,
                createdAt: quote.createdAt,
                lastAccessedAt: quote.lastReadAt
            )
        }

        logger.debug("Exported \(exported.count) quotes")
        return exported
    }

    /// Exports exercises
    func exportExercises() async throws -> [ExportedExercise] {
        logger.debug("Exporting exercises")

        let fetchDescriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\Exercise.createdAt, order: .reverse)]
        )

        let exercises = try modelContext.fetch(fetchDescriptor)

        let exported = exercises.map { exercise in
            ExportedExercise(
                id: exercise.id.uuidString,
                title: exercise.title,
                description: exercise.exerciseDescription,
                type: exercise.type.rawValue,
                duration: exercise.duration,
                difficulty: exercise.difficulty.rawValue,
                instructions: exercise.instructions,
                category: exercise.category,
                isFavorite: exercise.isFavorite,
                createdAt: exercise.createdAt
            )
        }

        logger.debug("Exported \(exported.count) exercises")
        return exported
    }

    /// Exports progress snapshots
    func exportProgress() async throws -> [ExportedProgressSnapshot] {
        logger.debug("Exporting progress data")

        let fetchDescriptor = FetchDescriptor<ProgressSnapshot>(
            sortBy: [SortDescriptor(\ProgressSnapshot.date, order: .reverse)]
        )

        let snapshots = try modelContext.fetch(fetchDescriptor)

        let exported = snapshots.map { snapshot in
            ExportedProgressSnapshot(
                id: snapshot.id.uuidString,
                date: snapshot.date,
                quotesAdded: snapshot.quotesAdded,
                journalEntries: snapshot.journalEntries,
                meditationMinutes: snapshot.meditationMinutes,
                breathingSessions: snapshot.breathingSessions,
                currentStreak: snapshot.currentStreak,
                averageMood: snapshot.averageMood?.rawValue
            )
        }

        logger.debug("Exported \(exported.count) progress snapshots")
        return exported
    }

    /// Exports achievements
    func exportAchievements() async throws -> [ExportedAchievement] {
        logger.debug("Exporting achievements")

        let fetchDescriptor = FetchDescriptor<Achievement>(
            sortBy: [SortDescriptor(\Achievement.unlockedAt)]
        )

        let achievements = try modelContext.fetch(fetchDescriptor)

        let exported = achievements.map { achievement in
            ExportedAchievement(
                id: achievement.id.uuidString,
                title: achievement.title,
                description: achievement.achievementDescription,
                icon: achievement.icon,
                isUnlocked: achievement.isUnlocked,
                unlockedAt: achievement.unlockedAt,
                currentProgress: achievement.progress,
                targetProgress: achievement.requirement
            )
        }

        logger.debug("Exported \(exported.count) achievements")
        return exported
    }

    // MARK: - Format-Specific Exports

    /// Exports journals as CSV
    func exportJournalsAsCSV() async throws -> URL {
        logger.debug("Exporting journals as CSV")

        let journals = try await exportJournals()

        var csvContent = "ID,Title,Content,Created At,Updated At,Mood,Tags,Word Count,Pinned,Favorite\n"

        for journal in journals {
            let row = [
                journal.id,
                escapeCSV(journal.title),
                escapeCSV(journal.content),
                ISO8601DateFormatter().string(from: journal.createdAt),
                journal.updatedAt.map { ISO8601DateFormatter().string(from: $0) } ?? "",
                journal.mood ?? "",
                escapeCSV(journal.tags.joined(separator: ", ")),
                "\(journal.wordCount)",
                journal.isPinned ? "Yes" : "No",
                journal.isFavorite ? "Yes" : "No",
            ].joined(separator: ",")

            csvContent += row + "\n"
        }

        let data = csvContent.data(using: .utf8) ?? Data()
        return try saveToTemporaryFile(data: data, filename: "heauton_journals_\(dateString()).csv")
    }

    /// Exports quotes as CSV
    func exportQuotesAsCSV() async throws -> URL {
        logger.debug("Exporting quotes as CSV")

        let quotes = try await exportQuotes()

        var csvContent = "ID,Author,Quote,Source,Category,Tags,Favorite,Created At\n"

        for quote in quotes {
            let row = [
                quote.id,
                escapeCSV(quote.author),
                escapeCSV(quote.text),
                escapeCSV(quote.source ?? ""),
                escapeCSV(quote.category ?? ""),
                escapeCSV(quote.tags.joined(separator: ", ")),
                quote.isFavorite ? "Yes" : "No",
                ISO8601DateFormatter().string(from: quote.createdAt),
            ].joined(separator: ",")

            csvContent += row + "\n"
        }

        let data = csvContent.data(using: .utf8) ?? Data()
        return try saveToTemporaryFile(data: data, filename: "heauton_quotes_\(dateString()).csv")
    }

    // MARK: - Storage Info

    /// Gets storage information
    func getStorageInfo() async throws -> StorageInfo {
        logger.debug("Calculating storage info")

        let journalCount = try modelContext.fetchCount(FetchDescriptor<JournalEntry>())
        let quoteCount = try modelContext.fetchCount(FetchDescriptor<Quote>())
        let exerciseCount = try modelContext.fetchCount(FetchDescriptor<Exercise>())
        let snapshotCount = try modelContext.fetchCount(FetchDescriptor<ProgressSnapshot>())

        // Estimate database size (rough calculation)
        let estimatedSize = calculateEstimatedDatabaseSize(
            journals: journalCount,
            quotes: quoteCount,
            exercises: exerciseCount,
            snapshots: snapshotCount
        )

        return StorageInfo(
            journalEntryCount: journalCount,
            quoteCount: quoteCount,
            exerciseCount: exerciseCount,
            progressSnapshotCount: snapshotCount,
            estimatedDatabaseSize: estimatedSize,
            lastCalculated: Date.now
        )
    }

    // MARK: - Helper Methods

    private func saveToTemporaryFile(data: Data, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        try data.write(to: fileURL)
        logger.debug("Saved export to: \(fileURL.path)")

        return fileURL
    }

    private func escapeCSV(_ string: String) -> String {
        let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date.now)
    }

    private func calculateEstimatedDatabaseSize(
        journals: Int,
        quotes: Int,
        exercises: Int,
        snapshots: Int
    ) -> Int64 {
        // Rough estimates:
        // - Journal entry: ~2KB average
        // - Quote: ~500 bytes average
        // - Exercise: ~1KB average
        // - Snapshot: ~200 bytes average

        let journalSize = Int64(journals) * 2048
        let quoteSize = Int64(quotes) * 512
        let exerciseSize = Int64(exercises) * 1024
        let snapshotSize = Int64(snapshots) * 200

        return journalSize + quoteSize + exerciseSize + snapshotSize
    }
}

// MARK: - Export Data Models

nonisolated struct CompleteBackup: Codable {
    let metadata: BackupMetadata
    let journals: [ExportedJournalEntry]
    let quotes: [ExportedQuote]
    let exercises: [ExportedExercise]
    let progress: [ExportedProgressSnapshot]
    let achievements: [ExportedAchievement]
}

nonisolated struct BackupMetadata: Codable {
    let version: String
    let exportDate: Date
    let appVersion: String
}

nonisolated struct ExportedJournalEntry: Codable {
    let id: String
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date?
    let mood: String?
    let tags: [String]
    let wordCount: Int
    let isPinned: Bool
    let isFavorite: Bool
}

nonisolated struct ExportedQuote: Codable {
    let id: String
    let author: String
    let text: String
    let source: String?
    let category: String?
    let tags: [String]
    let isFavorite: Bool
    let createdAt: Date
    let lastAccessedAt: Date?
}

nonisolated struct ExportedExercise: Codable {
    let id: String
    let title: String
    let description: String
    let type: String
    let duration: Int
    let difficulty: String
    let instructions: [String]
    let category: String
    let isFavorite: Bool
    let createdAt: Date
}

nonisolated struct ExportedProgressSnapshot: Codable {
    let id: String
    let date: Date
    let quotesAdded: Int
    let journalEntries: Int
    let meditationMinutes: Int
    let breathingSessions: Int
    let currentStreak: Int
    let averageMood: String?
}

nonisolated struct ExportedAchievement: Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let unlockedAt: Date?
    let currentProgress: Int
    let targetProgress: Int
}

nonisolated struct StorageInfo: Sendable {
    let journalEntryCount: Int
    let quoteCount: Int
    let exerciseCount: Int
    let progressSnapshotCount: Int
    let estimatedDatabaseSize: Int64
    let lastCalculated: Date

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: estimatedDatabaseSize, countStyle: .file)
    }

    var totalItemCount: Int {
        journalEntryCount + quoteCount + exerciseCount + progressSnapshotCount
    }
}

// MARK: - Export Errors

nonisolated enum DataExportError: Error, LocalizedError {
    case exportFailed(String)
    case encryptionError
    case fileWriteError

    var errorDescription: String? {
        switch self {
        case .exportFailed(let reason):
            "Export failed: \(reason)"
        case .encryptionError:
            "Failed to decrypt journal entries"
        case .fileWriteError:
            "Failed to write export file"
        }
    }
}
