@testable import Heauton
import SwiftData
import XCTest

/// Unit tests for SwiftDataQuotesRepository - Repository operations
@MainActor
final class SwiftDataQuotesRepositoryOperationTests: XCTestCase {
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

    // MARK: - Repository Operations

    func testFetchAllQuotesEmpty() async throws {
        let quotes = try await repository.fetchAllQuotes()
        XCTAssertTrue(quotes.isEmpty, "Should return empty array when no quotes exist")
    }

    func testFetchAllQuotesMultiple() async throws {
        // Insert test quotes
        let quote1 = Quote(author: "Plato", text: "Quote 1")
        let quote2 = Quote(author: "Aristotle", text: "Quote 2")
        let quote3 = Quote(author: "Socrates", text: "Quote 3")

        context.insert(quote1)
        context.insert(quote2)
        context.insert(quote3)
        try context.save()

        let quotes = try await repository.fetchAllQuotes()

        XCTAssertEqual(quotes.count, 3)
    }

    func testFetchAllQuotesSortedByDate() async throws {
        // Insert quotes with different dates
        let old = Quote(author: "Old", text: "Old quote", createdAt: Date(timeIntervalSince1970: 1000))
        let middle = Quote(author: "Middle", text: "Middle quote", createdAt: Date(timeIntervalSince1970: 2000))
        let new = Quote(author: "New", text: "New quote", createdAt: Date(timeIntervalSince1970: 3000))

        context.insert(old)
        context.insert(middle)
        context.insert(new)
        try context.save()

        let quotes = try await repository.fetchAllQuotes()

        // Should be sorted newest first
        XCTAssertEqual(quotes[0].author, "New")
        XCTAssertEqual(quotes[1].author, "Middle")
        XCTAssertEqual(quotes[2].author, "Old")
    }

    func testFetchFavoriteQuotesEmpty() async throws {
        let favorites = try await repository.fetchFavoriteQuotes()
        XCTAssertTrue(favorites.isEmpty)
    }

    func testFetchFavoriteQuotesFiltered() async throws {
        let favorite1 = Quote(author: "Fav1", text: "Text1", isFavorite: true)
        let notFavorite = Quote(author: "NotFav", text: "Text2", isFavorite: false)
        let favorite2 = Quote(author: "Fav2", text: "Text3", isFavorite: true)

        context.insert(favorite1)
        context.insert(notFavorite)
        context.insert(favorite2)
        try context.save()

        let favorites = try await repository.fetchFavoriteQuotes()

        XCTAssertEqual(favorites.count, 2)
        XCTAssertTrue(favorites.allSatisfy(\.isFavorite))
    }

    func testFetchQuoteById() async throws {
        let quote = Quote(author: "Test", text: "Test quote")
        context.insert(quote)
        try context.save()

        let fetched = try await repository.fetchQuote(id: quote.id)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, quote.id)
        XCTAssertEqual(fetched?.author, "Test")
    }

    func testFetchQuoteByIdNotFound() async throws {
        let nonExistentId = UUID()

        let fetched = try await repository.fetchQuote(id: nonExistentId)

        XCTAssertNil(fetched)
    }

    func testUpsertNewQuote() async throws {
        let quote = Quote(author: "New Author", text: "New text")

        try await repository.upsertQuotes([quote])

        let allQuotes = try await repository.fetchAllQuotes()
        XCTAssertEqual(allQuotes.count, 1)
        XCTAssertEqual(allQuotes.first?.author, "New Author")
    }

    func testUpsertUpdateExistingQuote() async throws {
        // Insert original quote
        let originalQuote = Quote(author: "Original", text: "Original text")
        context.insert(originalQuote)
        try context.save()

        // Create updated version with same ID
        let updatedQuote = Quote(
            id: originalQuote.id,
            author: "Updated",
            text: "Updated text",
            source: "New source"
        )

        try await repository.upsertQuotes([updatedQuote])

        let fetched = try await repository.fetchQuote(id: originalQuote.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.author, "Updated")
        XCTAssertEqual(fetched?.text, "Updated text")
        XCTAssertEqual(fetched?.source, "New source")
        XCTAssertNotNil(fetched?.updatedAt)
    }

    func testUpsertMultipleQuotes() async throws {
        let quotes = [
            Quote(author: "Author1", text: "Text1"),
            Quote(author: "Author2", text: "Text2"),
            Quote(author: "Author3", text: "Text3"),
        ]

        try await repository.upsertQuotes(quotes)

        let allQuotes = try await repository.fetchAllQuotes()
        XCTAssertEqual(allQuotes.count, 3)
    }

    func testUpsertMixedNewAndExisting() async throws {
        // Insert existing quote
        let existing = Quote(author: "Existing", text: "Existing text")
        context.insert(existing)
        try context.save()

        // Prepare upsert with one update and one new
        let updated = Quote(
            id: existing.id,
            author: "Updated",
            text: "Updated text"
        )
        let new = Quote(author: "New", text: "New text")

        try await repository.upsertQuotes([updated, new])

        let allQuotes = try await repository.fetchAllQuotes()
        XCTAssertEqual(allQuotes.count, 2)

        let updatedQuote = try await repository.fetchQuote(id: existing.id)
        XCTAssertEqual(updatedQuote?.author, "Updated")
    }

    func testToggleFavoriteNotFound() async throws {
        let nonExistentId = UUID()

        do {
            try await repository.toggleFavorite(id: nonExistentId)
            XCTFail("Should throw error for non-existent quote")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, RepositoryError.quoteNotFound)
        }
    }

    func testDeleteQuoteNotFound() async throws {
        let nonExistentId = UUID()

        do {
            try await repository.deleteQuote(id: nonExistentId)
            XCTFail("Should throw error for non-existent quote")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, RepositoryError.quoteNotFound)
        }
    }

    func testUpsertEmptyArray() async throws {
        try await repository.upsertQuotes([])

        let quotes = try await repository.fetchAllQuotes()
        XCTAssertTrue(quotes.isEmpty)
    }

    func testUpdatedAtSetOnUpsert() async throws {
        let original = Quote(author: "Original", text: "Original")
        context.insert(original)
        try context.save()

        let updated = Quote(
            id: original.id,
            author: "Updated",
            text: "Updated"
        )

        try await repository.upsertQuotes([updated])

        let fetched = try await repository.fetchQuote(id: original.id)
        XCTAssertNotNil(fetched?.updatedAt)
    }

    func testRepositoryErrorEquality() {
        let error1 = RepositoryError.quoteNotFound
        let error2 = RepositoryError.quoteNotFound

        XCTAssertEqual(error1, error2)
    }
}
