@testable import Heauton
import XCTest

/// Unit tests for QuoteFileStorage - Advanced operations (chunks, storage, cleanup, concurrency, performance)
final class QuoteFileStorageAdvancedTests: XCTestCase {
    var storage: QuoteFileStorage!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create a unique temporary directory for each test
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuoteFileStorageTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        tempDirectory = tempDir
        storage = QuoteFileStorage(baseURL: tempDir)

        // Give the storage time to initialize directories
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }

    override func tearDown() async throws {
        // Clean up test files
        try await cleanupTestFiles()

        // Remove temporary directory
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
        }

        try await super.tearDown()
    }

    // MARK: - Chunk Storage Tests

    func testSaveAndLoadChunk() async throws {
        let quoteId = UUID()
        let chunk = TextChunk(
            parentId: quoteId,
            index: 0,
            totalChunks: 1,
            content: "This is a test chunk.",
            wordCount: 5,
            range: "test".startIndex..<"test".endIndex
        )

        // Save chunk
        let path = try await storage.saveChunk(chunk, quoteId: quoteId)
        XCTAssertFalse(path.isEmpty)

        // Load chunk
        let loadedContent = try await storage.loadChunk(chunkId: chunk.id, quoteId: quoteId)
        XCTAssertEqual(loadedContent, chunk.content)

        // Cleanup
        try await storage.deleteChunks(for: quoteId)
    }

    func testSaveMultipleChunks() async throws {
        let quoteId = UUID()
        let chunks = [
            TextChunk(
                parentId: quoteId,
                index: 0,
                totalChunks: 3,
                content: "First chunk",
                wordCount: 2,
                range: "test".startIndex..<"test".endIndex
            ),
            TextChunk(
                parentId: quoteId,
                index: 1,
                totalChunks: 3,
                content: "Second chunk",
                wordCount: 2,
                range: "test".startIndex..<"test".endIndex
            ),
            TextChunk(
                parentId: quoteId,
                index: 2,
                totalChunks: 3,
                content: "Third chunk",
                wordCount: 2,
                range: "test".startIndex..<"test".endIndex
            ),
        ]

        // Save all chunks
        let paths = try await storage.saveChunks(chunks, for: quoteId)
        XCTAssertEqual(paths.count, 3)

        // Load each chunk
        for chunk in chunks {
            let loadedContent = try await storage.loadChunk(chunkId: chunk.id, quoteId: quoteId)
            XCTAssertEqual(loadedContent, chunk.content)
        }

        // Cleanup
        try await storage.deleteChunks(for: quoteId)
    }

    func testDeleteAllChunksForQuote() async throws {
        let quoteId = UUID()
        let chunks = [
            TextChunk(
                parentId: quoteId,
                index: 0,
                totalChunks: 2,
                content: "Chunk 1",
                wordCount: 2,
                range: "test".startIndex..<"test".endIndex
            ),
            TextChunk(
                parentId: quoteId,
                index: 1,
                totalChunks: 2,
                content: "Chunk 2",
                wordCount: 2,
                range: "test".startIndex..<"test".endIndex
            ),
        ]

        _ = try await storage.saveChunks(chunks, for: quoteId)

        // Delete all chunks
        try await storage.deleteChunks(for: quoteId)

        // Try to load should fail
        do {
            _ = try await storage.loadChunk(chunkId: chunks[0].id, quoteId: quoteId)
            XCTFail("Should not be able to load deleted chunk")
        } catch {
            // Expected
        }
    }

    // MARK: - Storage Size Tests

    func testCalculateStorageSize() async throws {
        let quoteId1 = UUID()
        let quoteId2 = UUID()

        let text1 = String(repeating: "A", count: 1000)
        let text2 = String(repeating: "B", count: 2000)

        _ = try await storage.saveQuoteText(text1, for: quoteId1)
        _ = try await storage.saveQuoteText(text2, for: quoteId2)

        let size = try await storage.calculateStorageSize()

        XCTAssertGreaterThan(size, 0, "Storage size should be greater than 0")
        XCTAssertGreaterThanOrEqual(
            size,
            Int64(text1.count + text2.count),
            "Storage size should at least equal text sizes"
        )

        // Cleanup
        try await storage.deleteQuoteText(for: quoteId1)
        try await storage.deleteQuoteText(for: quoteId2)
    }

    func testStorageSizeAfterDeletion() async throws {
        let quoteId = UUID()
        let text = String(repeating: "X", count: 10000)

        _ = try await storage.saveQuoteText(text, for: quoteId)
        let sizeWithFile = try await storage.calculateStorageSize()

        try await storage.deleteQuoteText(for: quoteId)
        let sizeAfterDeletion = try await storage.calculateStorageSize()

        XCTAssertLessThan(
            sizeAfterDeletion,
            sizeWithFile,
            "Storage size should decrease after deletion"
        )
    }

    // MARK: - Cleanup Orphaned Files Tests

    func testCleanupOrphanedFiles() async throws {
        let validId1 = UUID()
        let validId2 = UUID()
        let orphanId = UUID()

        // Save files for all IDs
        _ = try await storage.saveQuoteText("Valid 1", for: validId1)
        _ = try await storage.saveQuoteText("Valid 2", for: validId2)
        _ = try await storage.saveQuoteText("Orphan", for: orphanId)

        // Only validId1 and validId2 are "valid"
        let validIds: Set<UUID> = [validId1, validId2]

        // Cleanup orphans
        try await storage.cleanupOrphanedFiles(validQuoteIds: validIds)

        // Valid files should still exist
        let exists1 = try await storage.quoteTextExists(for: validId1)
        XCTAssertTrue(exists1)
        let exists2 = try await storage.quoteTextExists(for: validId2)
        XCTAssertTrue(exists2)

        // Orphan should be deleted
        let orphanExists = try await storage.quoteTextExists(for: orphanId)
        XCTAssertFalse(orphanExists)

        // Cleanup
        try await storage.deleteQuoteText(for: validId1)
        try await storage.deleteQuoteText(for: validId2)
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentSaves() async throws {
        let quoteIds = (0..<10).map { _ in UUID() }

        // Save multiple quotes concurrently
        await withTaskGroup(of: Void.self) { group in
            for (index, quoteId) in quoteIds.enumerated() {
                group.addTask {
                    try? await self.storage.saveQuoteText("Quote \(index)", for: quoteId)
                }
            }
        }

        // Verify all were saved
        for (index, quoteId) in quoteIds.enumerated() {
            let text = try await storage.loadQuoteText(for: quoteId)
            XCTAssertEqual(text, "Quote \(index)")
        }

        // Cleanup
        for quoteId in quoteIds {
            try await storage.deleteQuoteText(for: quoteId)
        }
    }

    func testConcurrentReads() async throws {
        let quoteId = UUID()
        let text = "Concurrent read test"

        _ = try await storage.saveQuoteText(text, for: quoteId)

        // Read concurrently
        await withTaskGroup(of: String?.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try? await self.storage.loadQuoteText(for: quoteId)
                }
            }

            for await result in group {
                XCTAssertEqual(result, text)
            }
        }

        try await storage.deleteQuoteText(for: quoteId)
    }

    // MARK: - Performance Tests

    func testSavePerformance() async throws {
        let quoteIds = (0..<100).map { _ in UUID() }
        let text = String(repeating: "Test ", count: 100)

        measure {
            Task {
                for quoteId in quoteIds {
                    try? await self.storage.saveQuoteText(text, for: quoteId)
                }
            }
        }

        // Cleanup
        for quoteId in quoteIds {
            try await storage.deleteQuoteText(for: quoteId)
        }
    }

    func testLoadPerformance() async throws {
        let quoteIds = (0..<100).map { _ in UUID() }
        let text = "Performance test"

        // Setup
        for quoteId in quoteIds {
            _ = try await storage.saveQuoteText(text, for: quoteId)
        }

        measure {
            Task {
                for quoteId in quoteIds {
                    _ = try? await self.storage.loadQuoteText(for: quoteId)
                }
            }
        }

        // Cleanup
        for quoteId in quoteIds {
            try await storage.deleteQuoteText(for: quoteId)
        }
    }

    // MARK: - Helper Methods

    private func cleanupTestFiles() async throws {}
}
