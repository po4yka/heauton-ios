import Foundation
import SwiftData

/// Daily snapshot of user's wellness activity progress
@Model
final class ProgressSnapshot: @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID

    /// Date of this snapshot (should be start of day)
    var date: Date

    // MARK: - Activity Counts

    /// Number of quotes added this day
    var quotesAdded: Int

    /// Number of journal entries created this day
    var journalEntries: Int

    /// Total meditation minutes this day
    var meditationMinutes: Int

    /// Number of breathing sessions this day
    var breathingSessions: Int

    // MARK: - Streaks

    /// Current streak (consecutive days with activity)
    var currentStreak: Int

    // MARK: - Mood

    /// Average mood for the day (optional)
    var averageMood: JournalMood?

    init(
        id: UUID = UUID(),
        date: Date,
        quotesAdded: Int = 0,
        journalEntries: Int = 0,
        meditationMinutes: Int = 0,
        breathingSessions: Int = 0,
        currentStreak: Int = 0,
        averageMood: JournalMood? = nil
    ) {
        self.id = id
        self.date = date
        self.quotesAdded = quotesAdded
        self.journalEntries = journalEntries
        self.meditationMinutes = meditationMinutes
        self.breathingSessions = breathingSessions
        self.currentStreak = currentStreak
        self.averageMood = averageMood
    }

    // MARK: - Helper Methods

    /// Total activity count for the day
    var totalActivities: Int {
        quotesAdded + journalEntries + meditationMinutes / 5 + breathingSessions
    }

    /// Whether there was any activity this day
    var hasActivity: Bool {
        totalActivities > 0
    }

    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
