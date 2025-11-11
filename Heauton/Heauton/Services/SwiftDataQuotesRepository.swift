import Foundation
import SwiftData

/// SwiftData implementation of QuotesRepository
final class SwiftDataQuotesRepository: QuotesRepository {
    private let modelContext: ModelContext
    private let searchService = QuoteSearchService.shared
    private let backgroundIndexing = BackgroundIndexingService.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Initialize search service
        Task {
            try? await searchService.initialize()
        }
    }

    func fetchAllQuotes() async throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchFavoriteQuotes() async throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate {
                $0.isFavorite == true
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchQuote(id: UUID) async throws -> Quote? {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate {
                $0.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func upsertQuotes(_ quotes: [Quote]) async throws {
        var quotesToIndex: [Quote] = []

        for quote in quotes {
            // Check if quote already exists
            if let existingQuote = try await fetchQuote(id: quote.id) {
                // Update existing quote
                existingQuote.author = quote.author
                existingQuote.text = quote.text
                existingQuote.source = quote.source
                existingQuote.updatedAt = .now
                quotesToIndex.append(existingQuote)
            } else {
                // Insert new quote
                modelContext.insert(quote)
                quotesToIndex.append(quote)
            }
        }
        try modelContext.save()

        // Queue quotes for indexing in the background
        await backgroundIndexing.queueIndexing(
            quotes: quotesToIndex,
            type: quotesToIndex.count == quotes.count ? .initial : .update
        )
    }

    func toggleFavorite(id: UUID) async throws {
        guard let quote = try await fetchQuote(id: id) else {
            throw RepositoryError.quoteNotFound
        }
        quote.isFavorite.toggle()
        quote.updatedAt = .now
        try modelContext.save()

        // Update index
        try await searchService.updateIndex(for: quote)
    }

    func deleteQuote(id: UUID) async throws {
        guard let quote = try await fetchQuote(id: id) else {
            throw RepositoryError.quoteNotFound
        }
        modelContext.delete(quote)
        try modelContext.save()

        // Remove from index
        try await searchService.removeFromIndex(quoteId: id)
    }

    // MARK: - Search Operations

    func search(query: String, options: SearchOptions) async throws -> [SearchResult] {
        try await searchService.search(query: query, options: options)
    }

    func searchByAuthor(author: String, limit: Int) async throws -> [SearchResult] {
        try await searchService.searchByAuthor(author: author, limit: limit)
    }

    func searchByKeywords(
        keywords: [String],
        matchAll: Bool,
        options: SearchOptions
    ) async throws -> [SearchResult] {
        try await searchService.searchByKeywords(
            keywords: keywords,
            matchAll: matchAll,
            options: options
        )
    }

    // MARK: - Filter Operations

    func fetchQuotes(filter: QuoteFilter) async throws -> [Quote] {
        let descriptor = filter.makeFetchDescriptor()
        var quotes = try modelContext.fetch(descriptor)

        // Handle random sort (can't be done in FetchDescriptor)
        if filter.sortBy == .random {
            quotes.shuffle()
        }

        return quotes
    }

    func getAvailableCategories() async throws -> [String] {
        let quotes = try await fetchAllQuotes()
        let categories = quotes.compactMap(\.categories).flatMap { $0 }
        return Array(Set(categories)).sorted()
    }

    func getAvailableAuthors() async throws -> [String] {
        let quotes = try await fetchAllQuotes()
        let authors = quotes.map(\.author)
        return Array(Set(authors)).sorted()
    }

    func getAvailableTags() async throws -> [String] {
        let quotes = try await fetchAllQuotes()
        let tags = quotes.compactMap(\.tags).flatMap { $0 }
        return Array(Set(tags)).sorted()
    }

    func getAvailableMoods() async throws -> [String] {
        let quotes = try await fetchAllQuotes()
        let moods = quotes.compactMap(\.mood)
        return Array(Set(moods)).sorted()
    }
}

enum RepositoryError: Error {
    case quoteNotFound
}
