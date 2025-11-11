import Foundation
import SwiftData

/// Model for tracking exercise sessions
@Model
final class ExerciseSession: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID

    /// Exercise that was performed
    var linkedExerciseId: UUID

    /// When the session started
    var startedAt: Date

    /// When the session completed (nil if not yet completed)
    var completedAt: Date?

    /// Actual duration in seconds spent on exercise
    var actualDuration: Int

    /// Whether the session was completed successfully
    var wasCompleted: Bool

    /// Mood before starting the exercise
    var moodBefore: JournalMood?

    /// Mood after completing the exercise
    var moodAfter: JournalMood?

    /// Optional notes about the session
    var notes: String?

    init(
        id: UUID = UUID(),
        linkedExerciseId: UUID,
        startedAt: Date = .now,
        completedAt: Date? = nil,
        actualDuration: Int = 0,
        wasCompleted: Bool = false,
        moodBefore: JournalMood? = nil,
        moodAfter: JournalMood? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.linkedExerciseId = linkedExerciseId
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.actualDuration = actualDuration
        self.wasCompleted = wasCompleted
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.notes = notes
    }

    // MARK: - Helper Methods

    /// Formatted session date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startedAt)
    }

    /// Formatted duration
    var formattedDuration: String {
        let minutes = actualDuration / 60
        let seconds = actualDuration % 60
        if minutes > 0, seconds > 0 {
            return "\(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "\(seconds) sec"
        }
    }
}
