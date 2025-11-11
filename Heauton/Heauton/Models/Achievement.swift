import Foundation
import SwiftData

/// Category of achievement
enum AchievementCategory: String, Codable, CaseIterable, Sendable {
    case quotes
    case journaling
    case meditation
    case breathing
    case consistency
    case social

    var displayName: String {
        switch self {
        case .quotes: "Quotes"
        case .journaling: "Journaling"
        case .meditation: "Meditation"
        case .breathing: "Breathing"
        case .consistency: "Consistency"
        case .social: "Social"
        }
    }

    var icon: String {
        switch self {
        case .quotes: "quote.bubble"
        case .journaling: "book.closed"
        case .meditation: "brain.head.profile"
        case .breathing: "wind"
        case .consistency: "calendar"
        case .social: "square.and.arrow.up"
        }
    }
}

/// Model for tracking user achievements
@Model
final class Achievement: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID

    /// Achievement title
    var title: String

    /// Detailed description
    var achievementDescription: String

    /// SF Symbol icon name
    var icon: String

    /// Category of achievement
    var category: AchievementCategory

    /// Requirement threshold to unlock
    var requirement: Int

    /// Current progress toward requirement
    var progress: Int

    /// Date when unlocked (nil if not yet unlocked)
    var unlockedAt: Date?

    /// Whether this is a hidden/secret achievement
    var isHidden: Bool

    init(
        id: UUID = UUID(),
        title: String,
        achievementDescription: String,
        icon: String,
        category: AchievementCategory,
        requirement: Int,
        progress: Int = 0,
        unlockedAt: Date? = nil,
        isHidden: Bool = false
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = achievementDescription
        self.icon = icon
        self.category = category
        self.requirement = requirement
        self.progress = progress
        self.unlockedAt = unlockedAt
        self.isHidden = isHidden
    }

    // MARK: - Helper Methods

    /// Whether the achievement is unlocked
    var isUnlocked: Bool {
        unlockedAt != nil
    }

    /// Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard requirement > 0 else { return 0.0 }
        return min(Double(progress) / Double(requirement), 1.0)
    }

    /// Formatted progress string
    var progressString: String {
        "\(progress) / \(requirement)"
    }

    /// Unlock the achievement
    func unlock() {
        guard !isUnlocked else { return }
        unlockedAt = Date.now
        progress = requirement
    }
}
