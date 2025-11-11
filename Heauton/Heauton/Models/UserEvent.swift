import Foundation
import SwiftData

/// Represents different types of user events that can be tracked
enum EventType: String, Codable, Sendable {
    case firstLogin = "first_login"
    case meditation
    case journalEntry = "journal_entry"
    case quoteAdded = "quote_added"
    case milestone
    case reflection
    case habit
    case mood
    case exercise
    case reading

    var displayName: String {
        switch self {
        case .firstLogin: "LIFE EVENT"
        case .meditation: "MEDITATION"
        case .journalEntry: "JOURNAL"
        case .quoteAdded: "QUOTE"
        case .milestone: "MILESTONE"
        case .reflection: "REFLECTION"
        case .habit: "HABIT"
        case .mood: "MOOD"
        case .exercise: "EXERCISE"
        case .reading: "READING"
        }
    }

    var iconName: String {
        switch self {
        case .firstLogin: "lightbulb.fill"
        case .meditation: "figure.mind.and.body"
        case .journalEntry: "book.fill"
        case .quoteAdded: "quote.bubble.fill"
        case .milestone: "flag.fill"
        case .reflection: "sparkles"
        case .habit: "checkmark.circle.fill"
        case .mood: "face.smiling"
        case .exercise: "figure.walk"
        case .reading: "book.closed.fill"
        }
    }
}

/// Model for tracking user events and activities
@Model
final class UserEvent: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID
    var type: EventType
    var title: String
    var eventDescription: String?
    var createdAt: Date
    var duration: Int? // Duration in minutes (for meditation, exercise, etc.)
    var value: Double? // Numeric value (for tracking metrics)
    var metadata: String? // JSON string for additional data

    init(
        id: UUID = UUID(),
        type: EventType,
        title: String,
        eventDescription: String? = nil,
        createdAt: Date = .now,
        duration: Int? = nil,
        value: Double? = nil,
        metadata: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.eventDescription = eventDescription
        self.createdAt = createdAt
        self.duration = duration
        self.value = value
        self.metadata = metadata
    }
}
