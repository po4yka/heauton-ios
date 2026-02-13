import CoreSpotlight
import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

/// Service for indexing quotes in Core Spotlight for system-wide search
actor SpotlightIndexingService: SpotlightIndexingServiceProtocol {
    // MARK: - Properties

    /// Shared instance
    static let shared = SpotlightIndexingService()
    /// Note: Prefer using AppDependencyContainer for dependency injection

    /// Spotlight search index
    private let searchableIndex = CSSearchableIndex.default()

    /// Domain identifier for app content
    private let domainIdentifier = "com.heauton.quotes"

    /// Batch size for indexing operations
    private let batchSize = 50

    // MARK: - Initialization

    init() {}

    // MARK: - Indexing Operations

    /// Indexes a single quote in Spotlight
    /// - Parameter quote: Quote to index
    func indexQuote(_ quote: Quote) async throws {
        let searchableItem = createSearchableItem(from: quote)
        try await indexItems([searchableItem])
    }

    /// Indexes multiple quotes in Spotlight
    /// - Parameter quotes: Array of quotes to index
    func indexQuotes(_ quotes: [Quote]) async throws {
        // Process in batches to avoid overwhelming the system
        for batch in quotes.chunked(into: batchSize) {
            let searchableItems = batch.map { createSearchableItem(from: $0) }
            try await indexItems(searchableItems)
        }
    }

    /// Updates a quote in the Spotlight index
    /// - Parameter quote: Quote to update
    func updateQuote(_ quote: Quote) async throws {
        // Spotlight handles updates the same as inserts
        try await indexQuote(quote)
    }

    /// Removes a quote from the Spotlight index
    /// - Parameter quoteId: ID of the quote to remove
    func removeQuote(id quoteId: UUID) async throws {
        let identifier = quoteId.uuidString
        try await deleteItems(withIdentifiers: [identifier])
    }

    /// Removes multiple quotes from the Spotlight index
    /// - Parameter quoteIds: Array of quote IDs to remove
    func removeQuotes(ids quoteIds: [UUID]) async throws {
        let identifiers = quoteIds.map(\.uuidString)
        try await deleteItems(withIdentifiers: identifiers)
    }

    /// Removes all quotes from the Spotlight index
    func removeAllQuotes() async throws {
        try await deleteItems(inDomain: domainIdentifier)
    }

    /// Reindexes all quotes
    /// - Parameter quotes: All quotes to reindex
    func reindexAll(quotes: [Quote]) async throws {
        // Remove all existing items
        try await removeAllQuotes()

        // Index all quotes
        try await indexQuotes(quotes)
    }

    // MARK: - Searchable Item Creation

    /// Creates a CSSearchableItem from a Quote
    /// - Parameter quote: Quote to convert
    /// - Returns: Searchable item for Spotlight
    private func createSearchableItem(from quote: Quote) -> CSSearchableItem {
        // Create attribute set
        let attributeSet = CSSearchableItemAttributeSet(
            contentType: .text
        )

        // Set core attributes
        attributeSet.title = truncate(quote.text, to: 200)
        attributeSet.contentDescription = quote.author
        attributeSet.displayName = quote.author

        // Set detailed content
        attributeSet.textContent = quote.text
        // Note: author is set via authorNames array below

        // Set keywords for better search
        let keywords = generateKeywords(from: quote)
        attributeSet.keywords = keywords

        // Set dates
        attributeSet.contentCreationDate = quote.createdAt
        attributeSet.contentModificationDate = quote.updatedAt

        // Set rating for favorites
        if quote.isFavorite {
            attributeSet.rating = NSNumber(value: 5)
        }

        // Add source if available
        if let source = quote.source {
            attributeSet.comment = source
            attributeSet.version = source // Using version field for source
        }

        // Add metadata
        attributeSet.identifier = quote.id.uuidString

        // Create searchable item
        let item = CSSearchableItem(
            uniqueIdentifier: quote.id.uuidString,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )

        // Set expiration date (far in the future, effectively never expires)
        item.expirationDate = Date.distantFuture

        return item
    }

    /// Generates search keywords from a quote
    /// - Parameter quote: Quote to extract keywords from
    /// - Returns: Array of keywords
    private func generateKeywords(from quote: Quote) -> [String] {
        var keywords: [String] = []

        // Add author as keyword
        keywords.append(quote.author)

        // Add source if available
        if let source = quote.source {
            keywords.append(source)
        }

        // Extract important words from the text
        let tokens = TextNormalizer.extractTokens(from: quote.text)

        // Filter out common words and keep meaningful ones
        let meaningfulTokens = tokens.filter { token in
            token.count > 3 && !commonWords.contains(token.lowercased())
        }

        // Add top keywords (limit to avoid bloat)
        keywords.append(contentsOf: meaningfulTokens.prefix(20))

        // Add "favorite" keyword if applicable
        if quote.isFavorite {
            keywords.append("favorite")
            keywords.append("starred")
        }

        return keywords
    }

    /// Common words to exclude from keywords
    private let commonWords: Set<String> = [
        "the", "and", "for", "are", "but", "not", "you", "all",
        "can", "her", "was", "one", "our", "out", "day", "get",
        "has", "him", "his", "how", "man", "new", "now", "old",
        "see", "two", "way", "who", "boy", "did", "its", "let",
        "put", "say", "she", "too", "use", "with", "from", "have",
        "this", "that", "what", "when", "where", "which", "about",
    ]

    // MARK: - Low-Level Operations

    /// Indexes items in Spotlight
    /// - Parameter items: Searchable items to index
    private func indexItems(_ items: [CSSearchableItem]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            searchableIndex.indexSearchableItems(items) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Deletes items from Spotlight by identifiers
    /// - Parameter identifiers: Array of unique identifiers
    private func deleteItems(withIdentifiers identifiers: [String]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            searchableIndex.deleteSearchableItems(withIdentifiers: identifiers) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Deletes all items in a domain
    /// - Parameter domain: Domain identifier
    private func deleteItems(inDomain domain: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            searchableIndex.deleteSearchableItems(withDomainIdentifiers: [domain]) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Utilities

    /// Truncates text to a maximum length
    /// - Parameters:
    ///   - text: Text to truncate
    ///   - length: Maximum length
    /// - Returns: Truncated text
    private func truncate(_ text: String, to length: Int) -> String {
        if text.count <= length {
            return text
        }

        let endIndex = text.index(text.startIndex, offsetBy: length)
        return String(text[..<endIndex]) + "..."
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    /// Splits array into chunks of specified size
    /// - Parameter size: Size of each chunk
    /// - Returns: Array of chunks
    nonisolated func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - UTType Extension

extension UTType {
    /// Custom type for quote content
    nonisolated static let quote = UTType(exportedAs: "com.heauton.quote")

    /// Text type for general content
    nonisolated static var text: UTType {
        UTType.plainText
    }
}
