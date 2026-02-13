import Foundation
import SwiftData

/// Mood associated with a journal entry
enum JournalMood: String, Codable, CaseIterable, Sendable {
    case joyful
    case grateful
    case peaceful
    case reflective
    case motivated
    case anxious
    case sad
    case frustrated
    case neutral

    var displayName: String {
        switch self {
        case .joyful: "Joyful"
        case .grateful: "Grateful"
        case .peaceful: "Peaceful"
        case .reflective: "Reflective"
        case .motivated: "Motivated"
        case .anxious: "Anxious"
        case .sad: "Sad"
        case .frustrated: "Frustrated"
        case .neutral: "Neutral"
        }
    }

    var emoji: String {
        switch self {
        case .joyful: "J"
        case .grateful: "G"
        case .peaceful: "P"
        case .reflective: "R"
        case .motivated: "M"
        case .anxious: "A"
        case .sad: "S"
        case .frustrated: "F"
        case .neutral: "N"
        }
    }
}

/// Model for journal entries
///
/// Thread Safety: This model is used across actor boundaries via SwiftData.
/// ALL MUTATIONS must occur on MainActor or within MainActor-isolated contexts.
/// See `Utilities/ThreadSafety.swift` for detailed thread safety documentation.
@Model
final class JournalEntry: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID

    /// Entry title
    var title: String

    /// Entry content in Markdown format
    var content: String

    /// Encrypted content data (when encryption is enabled)
    var encryptedContentData: Data?

    /// Whether the content is currently encrypted
    var isEncrypted: Bool

    /// Creation date
    var createdAt: Date

    /// Last update date
    var updatedAt: Date?

    /// Associated mood
    var mood: JournalMood?

    /// Tags for categorization
    var tags: [String]

    /// Linked quote ID (optional)
    var linkedQuoteId: UUID?

    /// Linked prompt ID (optional)
    var linkedPromptId: UUID?

    /// Word count
    var wordCount: Int

    /// Whether entry is pinned
    var isPinned: Bool

    /// Whether entry is favorited
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        encryptedContentData: Data? = nil,
        isEncrypted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        mood: JournalMood? = nil,
        tags: [String] = [],
        linkedQuoteId: UUID? = nil,
        linkedPromptId: UUID? = nil,
        wordCount: Int = 0,
        isPinned: Bool = false,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.encryptedContentData = encryptedContentData
        self.isEncrypted = isEncrypted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.mood = mood
        self.tags = tags
        self.linkedQuoteId = linkedQuoteId
        self.linkedPromptId = linkedPromptId
        self.wordCount = wordCount == 0 ? Self.countWords(in: content) : wordCount
        self.isPinned = isPinned
        self.isFavorite = isFavorite
    }

    // MARK: - Helper Methods

    /// Update word count
    func updateWordCount() {
        wordCount = Self.countWords(in: content)
    }

    /// Counts words in text
    private static func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }

    /// Preview text (first 200 characters)
    var preview: String {
        if content.count <= 200 {
            return content
        }
        let index = content.index(content.startIndex, offsetBy: 200)
        return String(content[..<index]) + "..."
    }

    /// Formatted creation date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}
