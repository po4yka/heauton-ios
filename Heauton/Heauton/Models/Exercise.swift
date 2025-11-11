import Foundation
import SwiftData

/// Type of wellness exercise
enum ExerciseType: String, Codable, CaseIterable, Sendable {
    case meditation
    case breathing
    case visualization
    case bodyScan

    var displayName: String {
        switch self {
        case .meditation: "Meditation"
        case .breathing: "Breathing"
        case .visualization: "Visualization"
        case .bodyScan: "Body Scan"
        }
    }

    var icon: String {
        switch self {
        case .meditation: "brain.head.profile"
        case .breathing: "wind"
        case .visualization: "eye"
        case .bodyScan: "figure.stand"
        }
    }
}

/// Difficulty level of exercise
enum Difficulty: String, Codable, CaseIterable, Sendable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }

    var color: String {
        switch self {
        case .beginner: "green"
        case .intermediate: "orange"
        case .advanced: "red"
        }
    }
}

/// Model for wellness exercises
@Model
final class Exercise: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID

    /// Exercise title
    var title: String

    /// Detailed description
    var exerciseDescription: String

    /// Type of exercise
    var type: ExerciseType

    /// Duration in seconds
    var duration: Int

    /// Difficulty level
    var difficulty: Difficulty

    /// Step-by-step instructions
    var instructions: [String]

    /// Optional audio file name for guided exercises
    var audioFileName: String?

    /// Optional related quote for inspiration
    var linkedQuoteId: UUID?

    /// Whether exercise is favorited
    var isFavorite: Bool

    /// Category for organization (e.g., "Stress Relief", "Focus")
    var category: String

    /// Creation date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        exerciseDescription: String,
        type: ExerciseType,
        duration: Int,
        difficulty: Difficulty,
        instructions: [String],
        audioFileName: String? = nil,
        linkedQuoteId: UUID? = nil,
        isFavorite: Bool = false,
        category: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.exerciseDescription = exerciseDescription
        self.type = type
        self.duration = duration
        self.difficulty = difficulty
        self.instructions = instructions
        self.audioFileName = audioFileName
        self.linkedQuoteId = linkedQuoteId
        self.isFavorite = isFavorite
        self.category = category
        self.createdAt = createdAt
    }

    // MARK: - Helper Methods

    /// Formatted duration string
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        if minutes > 0, seconds > 0 {
            return "\(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "\(seconds) sec"
        }
    }
}
