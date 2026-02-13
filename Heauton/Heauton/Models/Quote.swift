import Foundation
import SwiftData

/// Model for philosophical quotes
///
/// Thread Safety: This model is used across actor boundaries via SwiftData.
/// ALL MUTATIONS must occur on MainActor or within MainActor-isolated contexts.
/// See `Utilities/ThreadSafety.swift` for detailed thread safety documentation.
@Model
final class Quote: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID
    var author: String
    var text: String
    var source: String?
    var createdAt: Date
    var updatedAt: Date?
    var isFavorite: Bool

    // MARK: - Categorization & Discovery

    /// Categories for organizing quotes (e.g., "Stoicism", "Ethics", "Logic")
    var categories: [String]?

    /// User-added tags for personal organization
    var tags: [String]?

    /// Mood or tone of the quote (e.g., "Inspiring", "Reflective", "Challenging")
    var mood: String?

    /// Track how many times this quote has been viewed
    var readCount: Int

    /// Last time this quote was viewed
    var lastReadAt: Date?

    // MARK: - File Storage Support

    /// Path to the file containing the full text (for long quotes)
    /// If nil, text is stored directly in the text property
    var textFilePath: String?

    /// Indicates whether the text has been split into chunks
    var isChunked: Bool

    /// Word count of the text
    var wordCount: Int

    init(
        id: UUID = UUID(),
        author: String,
        text: String,
        source: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        isFavorite: Bool = false,
        categories: [String]? = nil,
        tags: [String]? = nil,
        mood: String? = nil,
        readCount: Int = 0,
        lastReadAt: Date? = nil,
        textFilePath: String? = nil,
        isChunked: Bool = false,
        wordCount: Int = 0
    ) {
        self.id = id
        self.author = author
        self.text = text
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
        self.categories = categories
        self.tags = tags
        self.mood = mood
        self.readCount = readCount
        self.lastReadAt = lastReadAt
        self.textFilePath = textFilePath
        self.isChunked = isChunked
        self.wordCount = wordCount == 0 ? Self.countWords(in: text) : wordCount
    }

    // MARK: - Helper Methods

    /// Returns whether this quote's text is stored in a file
    var isStoredInFile: Bool {
        textFilePath != nil
    }

    /// Returns whether this is a long quote (>1000 words)
    var isLongQuote: Bool {
        wordCount > 1000
    }

    /// Counts words in text
    private static func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }

    /// Increments read count and updates last read time
    func incrementReadCount() {
        readCount += 1
        lastReadAt = Date.now
    }
}
