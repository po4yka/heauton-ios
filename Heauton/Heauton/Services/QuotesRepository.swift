import Foundation

/// Protocol defining the interface for quote persistence operations
protocol QuotesRepository {
    /// Fetch all quotes from the repository
    func fetchAllQuotes() async throws -> [Quote]

    /// Fetch only favorite quotes
    func fetchFavoriteQuotes() async throws -> [Quote]

    /// Fetch a single quote by ID
    func fetchQuote(id: UUID) async throws -> Quote?

    /// Add or update quotes in the repository
    func upsertQuotes(_ quotes: [Quote]) async throws

    /// Toggle the favorite status of a quote
    func toggleFavorite(id: UUID) async throws

    /// Delete a quote
    func deleteQuote(id: UUID) async throws

    // MARK: - Search Operations

    /// Search quotes using full-text search
    /// - Parameters:
    ///   - query: Search query
    ///   - options: Search options
    /// - Returns: Array of search results with relevance scores
    func search(query: String, options: SearchOptions) async throws -> [SearchResult]

    /// Search quotes by author
    /// - Parameters:
    ///   - author: Author name
    ///   - limit: Maximum results
    /// - Returns: Array of search results
    func searchByAuthor(author: String, limit: Int) async throws -> [SearchResult]

    /// Search quotes by keywords
    /// - Parameters:
    ///   - keywords: Array of keywords
    ///   - matchAll: Whether all keywords must match
    ///   - options: Search options
    /// - Returns: Array of search results
    func searchByKeywords(
        keywords: [String],
        matchAll: Bool,
        options: SearchOptions
    ) async throws -> [SearchResult]

    // MARK: - Filter Support

    /// Fetch quotes with filter
    func fetchQuotes(filter: QuoteFilter) async throws -> [Quote]

    /// Get all unique categories from quotes
    func getAvailableCategories() async throws -> [String]

    /// Get all unique authors from quotes
    func getAvailableAuthors() async throws -> [String]

    /// Get all unique tags from quotes
    func getAvailableTags() async throws -> [String]

    /// Get all unique moods from quotes
    func getAvailableMoods() async throws -> [String]
}
