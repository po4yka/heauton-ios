import Foundation
import SwiftData

/// Search options for configuring search behavior
nonisolated struct SearchOptions: Sendable {
    /// Maximum number of results to return
    let limit: Int

    /// Minimum relevance score (0.0 - 1.0)
    let minRelevance: Double

    /// Search in author names
    let searchAuthors: Bool

    /// Search in quote content
    let searchContent: Bool

    /// Search in sources
    let searchSources: Bool

    /// Include only favorites
    let favoritesOnly: Bool

    /// Default search options
    static let `default` = SearchOptions(
        limit: 20,
        minRelevance: 0.0,
        searchAuthors: true,
        searchContent: true,
        searchSources: true,
        favoritesOnly: false
    )

    /// Options optimized for fast results
    static let fast = SearchOptions(
        limit: 10,
        minRelevance: 0.5,
        searchAuthors: true,
        searchContent: true,
        searchSources: false,
        favoritesOnly: false
    )

    /// Options for comprehensive search
    static let comprehensive = SearchOptions(
        limit: 100,
        minRelevance: 0.0,
        searchAuthors: true,
        searchContent: true,
        searchSources: true,
        favoritesOnly: false
    )
}

/// High-level service for searching quotes with full-text search
actor QuoteSearchService: QuoteSearchServiceProtocol {
    // MARK: - Properties

    /// Shared instance
    static let shared = QuoteSearchService()
    /// Note: Prefer using AppDependencyContainer for dependency injection

    /// Database manager
    private let databaseManager = SearchDatabaseManager.shared

    /// Model context for saving search history
    private var modelContext: ModelContext?

    /// Search cache
    private var searchCache: [String: CachedSearchResult] = [:]

    /// Cache expiration time (5 minutes)
    private let cacheExpirationInterval: TimeInterval = 300

    // MARK: - Initialization

    init() {}

    /// Sets the model context for search history tracking
    /// - Parameter context: ModelContext to use for saving search history
    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    /// Initializes the search service
    func initialize() async throws {
        try await databaseManager.initialize()
    }

    // MARK: - Search Operations

    /// Performs a full-text search for quotes
    /// - Parameters:
    ///   - query: Search query
    ///   - options: Search options
    /// - Returns: Array of search results with relevance scores
    func search(
        query: String,
        options: SearchOptions = .default
    ) async throws -> [SearchResult] {
        // Check cache first
        if let cached = getCachedResult(for: query) {
            return cached.results
        }

        // Perform search
        var allResults: [SearchResult] = []

        // Full-text search
        if options.searchContent {
            let contentResults = try await databaseManager.search(
                query: query,
                limit: options.limit
            )
            allResults.append(contentsOf: contentResults)
        }

        // Author search
        if options.searchAuthors {
            let authorResults = try await databaseManager.searchByAuthor(
                author: query,
                limit: options.limit
            )
            allResults.append(contentsOf: authorResults)
        }

        // Deduplicate and sort by relevance
        var uniqueResults: [UUID: SearchResult] = [:]
        for result in allResults {
            if let existing = uniqueResults[result.quoteId] {
                // Keep the result with higher relevance
                if result.relevanceScore > existing.relevanceScore {
                    uniqueResults[result.quoteId] = result
                }
            } else {
                uniqueResults[result.quoteId] = result
            }
        }

        // Filter by minimum relevance
        var filteredResults = uniqueResults.values.filter {
            $0.relevanceScore >= options.minRelevance
        }

        // Sort by relevance
        filteredResults.sort { $0.relevanceScore > $1.relevanceScore }

        // Limit results
        let limitedResults = Array(filteredResults.prefix(options.limit))

        // Cache results
        cacheResult(query: query, results: limitedResults)

        // Save search history
        if let modelContext, !query.isEmpty {
            let searchHistory = SearchHistory(
                query: query,
                resultCount: limitedResults.count,
                hadInteraction: false
            )
            modelContext.insert(searchHistory)
            try? modelContext.save()
        }

        return limitedResults
    }

    /// Searches for quotes by author
    /// - Parameters:
    ///   - author: Author name
    ///   - limit: Maximum results
    /// - Returns: Array of search results
    func searchByAuthor(
        author: String,
        limit: Int = 20
    ) async throws -> [SearchResult] {
        try await databaseManager.searchByAuthor(
            author: author,
            limit: limit
        )
    }

    /// Searches for quotes containing specific keywords
    /// - Parameters:
    ///   - keywords: Array of keywords
    ///   - matchAll: If true, all keywords must match; if false, any keyword can match
    ///   - options: Search options
    /// - Returns: Array of search results
    func searchByKeywords(
        keywords: [String],
        matchAll: Bool = false,
        options: SearchOptions = .default
    ) async throws -> [SearchResult] {
        let query = matchAll ?
            keywords.joined(separator: " AND ") :
            keywords.joined(separator: " OR ")

        return try await search(query: query, options: options)
    }

    /// Finds similar quotes to a given quote
    /// - Parameters:
    ///   - quoteId: ID of the reference quote
    ///   - limit: Maximum similar quotes to return
    /// - Returns: Array of similar quotes
    func findSimilar(
        to quoteId: UUID,
        limit: Int = 10
    ) async throws -> [SearchResult] {
        // Simplified similarity search based on author and common words
        // In a production system, you would use vector embeddings or TF-IDF

        // Get the reference quote from ModelContext
        guard let modelContext else {
            return []
        }

        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { quote in
                quote.id == quoteId
            }
        )
        let quotes = try modelContext.fetch(descriptor)
        guard let referenceQuote = quotes.first else {
            return []
        }

        // Extract significant words (simple keyword extraction)
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for"])
        let words = referenceQuote.text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 && !stopWords.contains($0) }

        // Search for quotes by the same author first
        var results: [SearchResult] = []
        let authorResults = try await search(
            query: referenceQuote.author,
            options: SearchOptions(
                limit: limit / 2,
                minRelevance: 0.0,
                searchAuthors: true,
                searchContent: false,
                searchSources: false,
                favoritesOnly: false
            )
        )
        results.append(contentsOf: authorResults.filter { $0.quoteId != quoteId })

        // Search for quotes with similar content
        if !words.isEmpty, results.count < limit {
            let contentResults = try await searchByKeywords(
                keywords: Array(words.prefix(5)),
                matchAll: false,
                options: SearchOptions(
                    limit: limit,
                    minRelevance: 0.3,
                    searchAuthors: false,
                    searchContent: true,
                    searchSources: false,
                    favoritesOnly: false
                )
            )
            results.append(contentsOf: contentResults.filter { result in
                result.quoteId != quoteId && !results.contains { $0.quoteId == result.quoteId }
            })
        }

        return Array(results.prefix(limit))
    }

    // MARK: - Search Suggestions

    /// Generates search suggestions based on partial query
    /// - Parameter partial: Partial search query
    /// - Returns: Array of suggested queries
    func getSuggestions(for partial: String) async throws -> [String] {
        guard partial.count >= 2 else { return [] }
        return []
    }

    /// Returns recent search queries
    /// - Parameter limit: Maximum number of queries to return
    /// - Returns: Array of recent queries
    func getRecentSearches(limit: Int = 10) async throws -> [String] {
        guard let modelContext else { return [] }

        var descriptor = FetchDescriptor<SearchHistory>(
            sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit * 2 // Fetch more to account for duplicates

        let history = try modelContext.fetch(descriptor)

        // Return unique queries, most recent first
        var uniqueQueries: [String] = []
        var seen = Set<String>()
        for item in history where !seen.contains(item.query) {
            uniqueQueries.append(item.query)
            seen.insert(item.query)
            if uniqueQueries.count >= limit {
                break
            }
        }

        return uniqueQueries
    }

    // MARK: - Indexing

    /// Indexes a quote for search
    /// - Parameter quote: Quote to index
    func indexQuote(_ quote: Quote) async throws {
        let wordCount = countWords(in: quote.text)
        let isLong = wordCount > 1000

        if isLong {
            // Chunk the text
            let chunks = TextChunker.chunk(
                quote.text,
                parentId: quote.id,
                config: .default
            )

            // Save chunks to file storage
            _ = try await QuoteFileStorage.shared.saveChunks(
                chunks,
                for: quote.id
            )

            // Save quote text to file
            let textPath = try await QuoteFileStorage.shared.saveQuoteText(
                quote.text,
                for: quote.id
            )

            // Index in database
            try await databaseManager.insertQuote(QuoteIndexData(
                id: quote.id,
                author: quote.author,
                text: quote.text,
                source: quote.source,
                isFavorite: quote.isFavorite,
                textFilePath: textPath,
                wordCount: wordCount,
                isChunked: true
            ))

            // Index chunks
            try await databaseManager.insertChunks(chunks, for: quote.id)
        } else {
            // Index directly
            try await databaseManager.insertQuote(QuoteIndexData(
                id: quote.id,
                author: quote.author,
                text: quote.text,
                source: quote.source,
                isFavorite: quote.isFavorite,
                textFilePath: nil,
                wordCount: wordCount,
                isChunked: false
            ))
        }
    }

    /// Updates a quote in the search index
    /// - Parameter quote: Quote to update
    func updateIndex(for quote: Quote) async throws {
        try await databaseManager.updateQuote(
            id: quote.id,
            author: quote.author,
            text: quote.text,
            source: quote.source,
            isFavorite: quote.isFavorite
        )

        // Invalidate cache entries that might contain this quote
        clearCache()
    }

    /// Removes a quote from the search index
    /// - Parameter quoteId: ID of the quote to remove
    func removeFromIndex(quoteId: UUID) async throws {
        try await databaseManager.deleteQuote(id: quoteId)

        // Clean up file storage
        try await QuoteFileStorage.shared.deleteQuoteText(for: quoteId)
        try await QuoteFileStorage.shared.deleteChunks(for: quoteId)

        // Invalidate cache
        clearCache()
    }

    /// Reindexes all quotes
    /// - Parameter quotes: Array of all quotes to reindex
    func reindexAll(quotes: [Quote]) async throws {
        for quote in quotes {
            try await indexQuote(quote)
        }

        // Rebuild FTS5 indices
        try await databaseManager.rebuildIndices()
    }

    // MARK: - Cache Management

    /// Cached search result
    private struct CachedSearchResult {
        let results: [SearchResult]
        let timestamp: Date
    }

    /// Gets a cached search result if available and not expired
    private func getCachedResult(for query: String) -> CachedSearchResult? {
        guard let cached = searchCache[query] else { return nil }

        let age = Date().timeIntervalSince(cached.timestamp)
        if age > cacheExpirationInterval {
            searchCache.removeValue(forKey: query)
            return nil
        }

        return cached
    }

    /// Caches a search result
    private func cacheResult(query: String, results: [SearchResult]) {
        searchCache[query] = CachedSearchResult(
            results: results,
            timestamp: Date()
        )

        // Limit cache size to 50 entries
        if searchCache.count > 50 {
            // Remove oldest entries
            let sortedKeys = searchCache.keys.sorted { key1, key2 in
                guard let cache1 = searchCache[key1],
                      let cache2 = searchCache[key2] else {
                    return false
                }
                return cache1.timestamp < cache2.timestamp
            }
            for key in sortedKeys.prefix(searchCache.count - 50) {
                searchCache.removeValue(forKey: key)
            }
        }
    }

    /// Clears the search cache
    func clearCache() {
        searchCache.removeAll()
    }

    // MARK: - Utilities

    /// Counts words in text
    private func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }

    // MARK: - Statistics

    /// Returns search statistics
    func getStatistics() async throws -> SearchStatistics {
        let dbStats = try await databaseManager.getStatistics()
        let storageSize = try await QuoteFileStorage.shared.calculateStorageSize()

        return SearchStatistics(
            totalQuotes: dbStats.totalQuotes,
            totalChunks: dbStats.totalChunks,
            totalSearches: dbStats.totalSearches,
            storageSize: storageSize,
            cacheSize: searchCache.count
        )
    }
}

// MARK: - Supporting Types

/// Search statistics
struct SearchStatistics: Sendable {
    let totalQuotes: Int
    let totalChunks: Int
    let totalSearches: Int
    let storageSize: Int64
    let cacheSize: Int

    var storageSizeMB: Double {
        Double(storageSize) / 1_048_576.0 // Convert bytes to MB
    }
}
