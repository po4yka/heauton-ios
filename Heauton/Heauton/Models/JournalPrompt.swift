import Foundation
import SwiftData

/// Category for journal prompts
enum PromptCategory: String, Codable, CaseIterable, Sendable {
    case reflection
    case gratitude
    case growth
    case goals
    case mindfulness
    case relationships
    case creativity
    case challenges

    var displayName: String {
        switch self {
        case .reflection: "Reflection"
        case .gratitude: "Gratitude"
        case .growth: "Personal Growth"
        case .goals: "Goals & Dreams"
        case .mindfulness: "Mindfulness"
        case .relationships: "Relationships"
        case .creativity: "Creativity"
        case .challenges: "Challenges"
        }
    }

    var icon: String {
        switch self {
        case .reflection: "lightbulb.fill"
        case .gratitude: "heart.fill"
        case .growth: "leaf.fill"
        case .goals: "target"
        case .mindfulness: "figure.mind.and.body"
        case .relationships: "person.2.fill"
        case .creativity: "paintbrush.fill"
        case .challenges: "mountain.2.fill"
        }
    }
}

/// Model for journal prompts
@Model
final class JournalPrompt: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID

    /// Prompt text
    var text: String

    /// Category
    var category: PromptCategory

    /// Is this prompt active?
    var isActive: Bool

    /// Number of times used
    var usageCount: Int

    /// Last used date
    var lastUsedAt: Date?

    /// Creation date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        category: PromptCategory,
        isActive: Bool = true,
        usageCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.isActive = isActive
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
    }

    // MARK: - Helper Methods

    /// Mark prompt as used
    func markAsUsed() {
        usageCount += 1
        lastUsedAt = Date.now
    }

    /// Was used recently (within last 7 days)
    var wasUsedRecently: Bool {
        guard let lastUsed = lastUsedAt else {
            return false
        }
        let daysSinceUse = Calendar.current.dateComponents(
            [.day],
            from: lastUsed,
            to: Date.now
        ).day ?? 0
        return daysSinceUse < 7
    }
}
