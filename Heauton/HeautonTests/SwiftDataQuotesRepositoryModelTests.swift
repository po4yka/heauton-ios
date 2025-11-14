@testable import Heauton
import SwiftData
import XCTest

/// Unit tests for SwiftDataQuotesRepository - Quote model and edge cases
@MainActor
final class SwiftDataQuotesRepositoryModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var repository: SwiftDataQuotesRepository!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory container for testing
        let schema = Schema([Quote.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
        repository = SwiftDataQuotesRepository(modelContext: context)
    }

    override func tearDown() async throws {
        repository = nil
        context = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - Quote Model Tests

    func testQuoteModelDefaults() {
        let quote = Quote(author: "Test", text: "Test")

        XCTAssertNotNil(quote.id)
        XCTAssertEqual(quote.author, "Test")
        XCTAssertEqual(quote.text, "Test")
        XCTAssertNil(quote.source)
        XCTAssertNotNil(quote.createdAt)
        XCTAssertNil(quote.updatedAt)
        XCTAssertFalse(quote.isFavorite)
        XCTAssertNil(quote.textFilePath)
        XCTAssertFalse(quote.isChunked)
        XCTAssertGreaterThanOrEqual(quote.wordCount, 0)
    }

    func testQuoteWordCount() {
        let quote = Quote(author: "Test", text: "one two three four five")

        XCTAssertEqual(quote.wordCount, 5)
    }

    func testQuoteIsLongQuote() {
        let shortQuote = Quote(author: "Test", text: String(repeating: "word ", count: 500))
        let longQuote = Quote(author: "Test", text: String(repeating: "word ", count: 1500))

        XCTAssertFalse(shortQuote.isLongQuote)
        XCTAssertTrue(longQuote.isLongQuote)
    }

    func testQuoteIsStoredInFile() {
        let normalQuote = Quote(author: "Test", text: "Test")
        let fileQuote = Quote(
            author: "Test",
            text: "Test",
            textFilePath: "/path/to/file.txt"
        )

        XCTAssertFalse(normalQuote.isStoredInFile)
        XCTAssertTrue(fileQuote.isStoredInFile)
    }

    // MARK: - Edge Cases and Error Handling

    func testConcurrentFetches() async throws {
        // Insert test data
        let quotes = (0..<10).map { Quote(author: "Author\($0)", text: "Text\($0)") }
        for quote in quotes {
            context.insert(quote)
        }
        try context.save()

        // Fetch concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask { [weak self] in
                    _ = try? await self?.repository.fetchAllQuotes()
                }
            }
        }

        // Should not crash and data should be intact
        let allQuotes = try await repository.fetchAllQuotes()
        XCTAssertEqual(allQuotes.count, 10)
    }

    func testQuoteWithVeryLongText() async throws {
        let longText = String(repeating: "Lorem ipsum dolor sit amet. ", count: 10000)
        let quote = Quote(author: "Test", text: longText)

        context.insert(quote)
        try context.save()

        let fetched = try await repository.fetchQuote(id: quote.id)
        XCTAssertEqual(fetched?.text, longText)
    }

    func testQuoteWithSpecialCharacters() async throws {
        let quote = Quote(
            author: "René Descartes",
            text: "Je pense, donc je suis. @#$%^&*()",
            source: "Café & Bar"
        )

        context.insert(quote)
        try context.save()

        let fetched = try await repository.fetchQuote(id: quote.id)
        XCTAssertEqual(fetched?.author, "René Descartes")
        XCTAssertTrue(fetched?.text.contains("@#$%^&*()") ?? false)
    }

    func testQuoteWithEmptyText() async throws {
        let quote = Quote(author: "Test", text: "")

        context.insert(quote)
        try context.save()

        let fetched = try await repository.fetchQuote(id: quote.id)
        XCTAssertEqual(fetched?.text, "")
        XCTAssertEqual(fetched?.wordCount, 0)
    }

    func testQuoteUniqueIdAttribute() async throws {
        let id = UUID()
        let quote1 = Quote(id: id, author: "Author1", text: "Text1")
        let quote2 = Quote(id: id, author: "Author2", text: "Text2")

        context.insert(quote1)

        // Attempting to insert another quote with same ID should update
        try await repository.upsertQuotes([quote2])

        let quotes = try await repository.fetchAllQuotes()
        XCTAssertEqual(quotes.count, 1)
        XCTAssertEqual(quotes.first?.author, "Author2")
    }
}
