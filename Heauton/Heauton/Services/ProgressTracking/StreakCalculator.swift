import Foundation

/// Helper for calculating activity streaks
nonisolated enum StreakCalculator {
    /// Checks if a snapshot has activity for the given type
    static func hasActivity(for type: ActivityType, in snapshot: ProgressSnapshot) -> Bool {
        switch type {
        case .quotes:
            snapshot.quotesAdded > 0
        case .journaling:
            snapshot.journalEntries > 0
        case .meditation:
            snapshot.meditationMinutes > 0
        case .breathing:
            snapshot.breathingSessions > 0
        case .any:
            snapshot.hasActivity
        }
    }

    /// Calculates current streak from sorted snapshots (most recent first)
    static func calculateCurrentStreak(
        from snapshots: [ProgressSnapshot],
        type: ActivityType
    ) -> Int {
        guard !snapshots.isEmpty else { return 0 }

        var streak = 0
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date.now)

        for snapshot in snapshots.sorted(by: { $0.date > $1.date }) {
            let snapshotDate = calendar.startOfDay(for: snapshot.date)

            if calendar.isDate(snapshotDate, inSameDayAs: currentDate) {
                if hasActivity(for: type, in: snapshot) {
                    streak += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            }
        }

        return streak
    }

    /// Calculates longest streak from snapshots
    static func calculateLongestStreak(
        from snapshots: [ProgressSnapshot],
        type: ActivityType
    ) -> Int {
        guard !snapshots.isEmpty else { return 0 }

        var longestStreak = 0
        var currentStreak = 0

        let sortedSnapshots = snapshots.sorted { $0.date < $1.date }

        for snapshot in sortedSnapshots {
            if hasActivity(for: type, in: snapshot) {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return longestStreak
    }
}
