import Foundation
@testable import Heauton
import SwiftData
import Testing

@Suite("QuotesListViewModel Tests")
@MainActor
struct QuotesListViewModelTests {
    @Test("Initial state is correct")
    func initialState() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Quote.self, configurations: config)
        let context = ModelContext(container)

        let viewModel = QuotesListViewModel(modelContext: context)

        #expect(viewModel.showFavoritesOnly == false)
        #expect(viewModel.selectedQuote == nil)
        #expect(viewModel.showSettings == false)
        #expect(viewModel.searchQuery.isEmpty)
        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.isSearching == false)
        #expect(viewModel.searchError == nil)
        #expect(viewModel.isSearchActive == false)
    }

    @Test("Favorites filter works correctly")
    func favoritesFilter() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Quote.self, configurations: config)
        let context = ModelContext(container)

        let viewModel = QuotesListViewModel(modelContext: context)

        // Create sample quotes
        let favoriteQuote = Quote(
            author: "Socrates",
            text: "The unexamined life is not worth living.",
            source: "Apology"
        )
        favoriteQuote.isFavorite = true

        let regularQuote = Quote(
            author: "Plato",
            text: "The first and greatest victory is to conquer yourself.",
            source: "Laws"
        )

        let quotes = [favoriteQuote, regularQuote]

        // Test without filter
        let allQuotes = viewModel.filteredQuotes(from: quotes)
        #expect(allQuotes.count == 2)

        // Enable favorites filter
        viewModel.showFavoritesOnly = true
        let favQuotes = viewModel.filteredQuotes(from: quotes)
        #expect(favQuotes.count == 1)
        #expect(favQuotes.first?.isFavorite == true)
    }

    @Test("Toggle favorites filter")
    func toggleFavoritesFilter() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Quote.self, configurations: config)
        let context = ModelContext(container)

        let viewModel = QuotesListViewModel(modelContext: context)

        #expect(viewModel.showFavoritesOnly == false)

        viewModel.toggleFavoritesFilter()
        #expect(viewModel.showFavoritesOnly == true)

        viewModel.toggleFavoritesFilter()
        #expect(viewModel.showFavoritesOnly == false)
    }

    @Test("Add sample quote inserts into context")
    func addSampleQuote() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Quote.self, configurations: config)
        let context = ModelContext(container)

        let viewModel = QuotesListViewModel(modelContext: context)

        // Add a sample quote
        viewModel.addSampleQuote()

        // Verify quote was inserted
        let descriptor = FetchDescriptor<Quote>()
        let quotes = try context.fetch(descriptor)
        #expect(quotes.count == 1)
        #expect(quotes.first != nil)
    }

    @Test("Delete quotes removes from context")
    func deleteQuotes() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Quote.self, configurations: config)
        let context = ModelContext(container)

        let viewModel = QuotesListViewModel(modelContext: context)

        // Create test quotes
        let quote1 = Quote(author: "Author 1", text: "Text 1")
        let quote2 = Quote(author: "Author 2", text: "Text 2")
        let quote3 = Quote(author: "Author 3", text: "Text 3")

        context.insert(quote1)
        context.insert(quote2)
        context.insert(quote3)
        try context.save()

        let quotes = [quote1, quote2, quote3]

        // Delete the second quote (index 1)
        let offsets = IndexSet(integer: 1)
        viewModel.deleteQuotes(at: offsets, from: quotes)

        // Verify deletion
        let descriptor = FetchDescriptor<Quote>()
        let remainingQuotes = try context.fetch(descriptor)
        #expect(remainingQuotes.count == 2)
    }

    @Test("Clear search resets all search state")
    func clearSearch() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Quote.self, configurations: config)
        let context = ModelContext(container)

        let viewModel = QuotesListViewModel(modelContext: context)

        // Set search state
        viewModel.searchQuery = "test"
        viewModel.searchResults = [
            SearchResult(
                quoteId: UUID(),
                author: "Test Author",
                snippet: "test",
                relevanceScore: 1.0,
                matchType: .exactMatch
            ),
        ]
        viewModel.isSearching = true

        // Clear search
        viewModel.clearSearch()

        #expect(viewModel.searchQuery.isEmpty)
        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.isSearching == false)
        #expect(viewModel.searchError == nil)
    }

    @Test("isSearchActive returns correct value")
    func isSearchActive() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Quote.self, configurations: config)
        let context = ModelContext(container)

        let viewModel = QuotesListViewModel(modelContext: context)

        // Initially not active
        #expect(viewModel.isSearchActive == false)

        // With query but no results
        viewModel.searchQuery = "test"
        #expect(viewModel.isSearchActive == false)

        // With query and results
        viewModel.searchResults = [
            SearchResult(
                quoteId: UUID(),
                author: "Test Author",
                snippet: "test",
                relevanceScore: 1.0,
                matchType: .exactMatch
            ),
        ]
        #expect(viewModel.isSearchActive == true)

        // Clear query
        viewModel.searchQuery = ""
        #expect(viewModel.isSearchActive == false)
    }

    @Test("Display quotes returns sorted search results when search is active")
    func displayQuotesWithSearch() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Quote.self, configurations: config)
        let context = ModelContext(container)

        let viewModel = QuotesListViewModel(modelContext: context)

        // Create test quotes
        let quote1 = Quote(author: "Author 1", text: "Text 1")
        let quote2 = Quote(author: "Author 2", text: "Text 2")
        let quote3 = Quote(author: "Author 3", text: "Text 3")

        context.insert(quote1)
        context.insert(quote2)
        context.insert(quote3)
        try context.save()

        let allQuotes = [quote1, quote2, quote3]

        // Set up search results (quote2 with higher score than quote1)
        viewModel.searchQuery = "test"
        viewModel.searchResults = [
            SearchResult(
                quoteId: quote2.id,
                author: "Author 2",
                snippet: "test",
                relevanceScore: 0.9,
                matchType: .exactMatch
            ),
            SearchResult(
                quoteId: quote1.id,
                author: "Author 1",
                snippet: "test",
                relevanceScore: 0.5,
                matchType: .contentMatch
            ),
        ]

        let displayQuotes = viewModel.displayQuotes(from: allQuotes)

        // Should only include quotes in search results
        #expect(displayQuotes.count == 2)

        // Should be sorted by relevance score (highest first)
        #expect(displayQuotes.first?.id == quote2.id)
        #expect(displayQuotes.last?.id == quote1.id)
    }
}
