import Foundation
import OSLog
import SwiftData
import SwiftUI

/// ViewModel for QuotesListView following MVVM + @Observable pattern
/// Handles search, filtering, and quote management logic
@Observable
@MainActor
final class QuotesListViewModel {
    // MARK: - Dependencies

    private let logger = Logger(subsystem: "com.heauton.app", category: "QuotesList")
    private let modelContext: ModelContext

    // MARK: - Published State

    var showFavoritesOnly = false
    var selectedQuote: Quote?
    var showSettings = false

    // Search State
    var searchQuery = ""
    var searchResults: [SearchResult] = []
    var isSearching = false
    var searchError: Error?

    // MARK: - Validation

    private let maxSearchQueryLength = 500
    private let minSearchQueryLength = 2

    // MARK: - Computed Properties

    var isSearchActive: Bool {
        !searchQuery.isEmpty && !searchResults.isEmpty
    }

    var isValidSearchQuery: Bool {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minSearchQueryLength && trimmed.count <= maxSearchQueryLength
    }

    var searchQueryValidationError: String? {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        if !searchQuery.isEmpty, trimmed.isEmpty {
            return "Search query cannot be only whitespace"
        }
        if !trimmed.isEmpty, trimmed.count < minSearchQueryLength {
            return "Search query must be at least \(minSearchQueryLength) characters"
        }
        if trimmed.count > maxSearchQueryLength {
            return "Search query is too long (max \(maxSearchQueryLength) characters)"
        }
        return nil
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// Returns filtered quotes based on favorites filter
    func filteredQuotes(from quotes: [Quote]) -> [Quote] {
        if showFavoritesOnly {
            return quotes.filter(\.isFavorite)
        }
        return quotes
    }

    /// Returns display quotes based on search state and filters
    func displayQuotes(from quotes: [Quote]) -> [Quote] {
        if isSearchActive {
            // Filter quotes based on search results
            let resultIds = Set(searchResults.map(\.quoteId))
            return quotes.filter { resultIds.contains($0.id) }
                .sorted { quote1, quote2 in
                    // Sort by relevance score from search results
                    let score1 = searchResults.first { $0.quoteId == quote1.id }?.relevanceScore ?? 0
                    let score2 = searchResults.first { $0.quoteId == quote2.id }?.relevanceScore ?? 0
                    return score1 > score2
                }
        }
        return filteredQuotes(from: quotes)
    }

    /// Performs search with debouncing and validation
    func performSearch(query: String) async {
        // Clear results if query is empty
        guard !query.isEmpty else {
            searchResults = []
            searchError = nil
            return
        }

        // Validate query length
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minSearchQueryLength else {
            searchResults = []
            searchError = nil
            return
        }

        guard trimmed.count <= maxSearchQueryLength else {
            searchResults = []
            searchError = ValidationError.searchQueryTooLong
            return
        }

        // Debounce search to avoid excessive queries
        try? await Task.sleep(for: .milliseconds(300))

        // Check if query is still current after debounce
        guard query == searchQuery else { return }

        isSearching = true
        searchError = nil

        do {
            let repository = SwiftDataQuotesRepository(modelContext: modelContext)
            let options = SearchOptions(
                limit: 50,
                minRelevance: 0.0,
                searchAuthors: true,
                searchContent: true,
                searchSources: true,
                favoritesOnly: showFavoritesOnly
            )

            searchResults = try await repository.search(
                query: query,
                options: options
            )
        } catch {
            searchError = error
            searchResults = []
        }

        isSearching = false
    }

    /// Toggle favorites filter
    func toggleFavoritesFilter() {
        showFavoritesOnly.toggle()
    }

    /// Delete quotes at given offsets
    func deleteQuotes(at offsets: IndexSet, from quotes: [Quote]) {
        for index in offsets {
            modelContext.delete(quotes[index])
        }
    }

    /// Add a random sample quote
    func addSampleQuote() {
        let sampleQuotes = [
            Quote(
                author: "Socrates",
                text: "The unexamined life is not worth living.",
                source: "Apology"
            ),
            Quote(
                author: "René Descartes",
                text: "Cogito, ergo sum. (I think, therefore I am.)",
                source: "Discourse on the Method"
            ),
            Quote(
                author: "Friedrich Nietzsche",
                text: "He who has a why to live can bear almost any how.",
                source: "Twilight of the Idols"
            ),
            Quote(
                author: "Aristotle",
                text: "We are what we repeatedly do. Excellence, then, is not an act, but a habit."
            ),
            Quote(
                author: "Marcus Aurelius",
                text:
                "You have power over your mind - not outside events. " +
                    "Realize this, and you will find strength.",
                source: "Meditations"
            ),
        ]

        guard let randomQuote = sampleQuotes.randomElement() else {
            logger.error("No sample quotes available")
            return
        }
        modelContext.insert(randomQuote)
    }

    /// Reset search state
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        searchError = nil
        isSearching = false
    }
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case searchQueryTooLong
    case searchQueryTooShort
    case invalidInput(String)

    var errorDescription: String? {
        switch self {
        case .searchQueryTooLong:
            "Search query is too long"
        case .searchQueryTooShort:
            "Search query is too short"
        case .invalidInput(let message):
            message
        }
    }
}
