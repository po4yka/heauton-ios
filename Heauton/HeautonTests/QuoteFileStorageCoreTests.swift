@testable import Heauton
import XCTest

/// Unit tests for QuoteFileStorage - Core operations (save, load, delete, exists)
final class QuoteFileStorageCoreTests: XCTestCase {
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

    // MARK: - Save and Load Quote Text Tests

    func testSaveAndLoadQuoteText() async throws {
        let quoteId = UUID()
        let text = "This is a test quote from Marcus Aurelius about the nature of life."

        // Save text
        let path = try await storage.saveQuoteText(text, for: quoteId)
        XCTAssertFalse(path.isEmpty, "Path should not be empty")

        // Load text
        let loadedText = try await storage.loadQuoteText(for: quoteId)
        XCTAssertEqual(loadedText, text, "Loaded text should match saved text")

        // Cleanup
        try await storage.deleteQuoteText(for: quoteId)
    }

    func testSaveLongQuoteText() async throws {
        let quoteId = UUID()
        let longText = String(repeating: "Long philosophical meditation. ", count: 1000)

        let path = try await storage.saveQuoteText(longText, for: quoteId)
        XCTAssertFalse(path.isEmpty)

        let loadedText = try await storage.loadQuoteText(for: quoteId)
        XCTAssertEqual(loadedText, longText)

        try await storage.deleteQuoteText(for: quoteId)
    }

    func testSaveQuoteTextWithUnicode() async throws {
        let quoteId = UUID()
        let text = "Café naïve résumé 你好世界"

        let path = try await storage.saveQuoteText(text, for: quoteId)
        let loadedText = try await storage.loadQuoteText(for: quoteId)

        XCTAssertEqual(loadedText, text, "Should handle Unicode correctly")

        try await storage.deleteQuoteText(for: quoteId)
    }

    func testSaveEmptyQuoteText() async throws {
        let quoteId = UUID()
        let text = ""

        let path = try await storage.saveQuoteText(text, for: quoteId)
        let loadedText = try await storage.loadQuoteText(for: quoteId)

        XCTAssertEqual(loadedText, text, "Should handle empty string")

        try await storage.deleteQuoteText(for: quoteId)
    }

    func testLoadNonexistentQuoteText() async throws {
        let quoteId = UUID()

        do {
            _ = try await storage.loadQuoteText(for: quoteId)
            XCTFail("Should throw error for nonexistent file")
        } catch let error as FileStorageError {
            if case .fileNotFound(let id) = error {
                XCTAssertEqual(id, quoteId)
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testOverwriteQuoteText() async throws {
        let quoteId = UUID()
        let originalText = "Original text"
        let newText = "Updated text"

        // Save original
        _ = try await storage.saveQuoteText(originalText, for: quoteId)

        // Overwrite
        _ = try await storage.saveQuoteText(newText, for: quoteId)

        // Load should return new text
        let loadedText = try await storage.loadQuoteText(for: quoteId)
        XCTAssertEqual(loadedText, newText)

        try await storage.deleteQuoteText(for: quoteId)
    }

    // MARK: - Delete Quote Text Tests

    func testDeleteQuoteText() async throws {
        let quoteId = UUID()
        let text = "Test text"

        _ = try await storage.saveQuoteText(text, for: quoteId)

        // Delete
        try await storage.deleteQuoteText(for: quoteId)

        // Should not exist anymore
        let exists = try await storage.quoteTextExists(for: quoteId)
        XCTAssertFalse(exists, "Quote text should not exist after deletion")
    }

    func testDeleteNonexistentQuoteText() async throws {
        let quoteId = UUID()

        // Should not throw error when deleting non-existent file
        try await storage.deleteQuoteText(for: quoteId)
    }

    // MARK: - Quote Text Existence Tests

    func testQuoteTextExists() async throws {
        let quoteId = UUID()

        // Initially should not exist
        var exists = try await storage.quoteTextExists(for: quoteId)
        XCTAssertFalse(exists)

        // Save
        _ = try await storage.saveQuoteText("Test", for: quoteId)

        // Now should exist
        exists = try await storage.quoteTextExists(for: quoteId)
        XCTAssertTrue(exists)

        // Cleanup
        try await storage.deleteQuoteText(for: quoteId)
    }

    // MARK: - Error Handling Tests

    func testErrorOnInvalidData() async throws {
        // This test is harder to trigger since we control the data
        // But we can test the error types
        let error = FileStorageError.invalidData
        XCTAssertNotNil(error.errorDescription)
    }

    func testErrorDescriptions() {
        let errors: [FileStorageError] = [
            .appGroupNotFound,
            .fileNotFound(UUID()),
            .unableToCreateDirectory,
            .unableToWriteFile,
            .unableToReadFile,
            .invalidData,
        ]

        for error in errors {
            XCTAssertNotNil(
                error.errorDescription,
                "All errors should have descriptions"
            )
        }
    }

    // MARK: - Helper Methods

    private func cleanupTestFiles() async throws {}
}
