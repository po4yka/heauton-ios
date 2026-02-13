import Foundation

/// Helper for calculating progress statistics
nonisolated enum ProgressStatsCalculator {
    nonisolated struct ExerciseStats {
        let meditationMinutes: Int
        let breathingSessions: Int
    }

    /// Calculates meditation minutes and breathing sessions from exercise sessions
    /// Sessions longer than 180 seconds are considered meditation
    static func calculateExerciseStats(from sessions: [ExerciseSession]) -> ExerciseStats {
        var meditationMinutes = 0
        var breathingSessions = 0

        for session in sessions {
            if session.actualDuration > 180 {
                meditationMinutes += session.actualDuration / 60
            } else {
                breathingSessions += 1
            }
        }

        return ExerciseStats(
            meditationMinutes: meditationMinutes,
            breathingSessions: breathingSessions
        )
    }

    /// Calculates average mood from journal entries
    /// Returns a random mood from entries if available
    static func calculateAverageMood(from entries: [JournalEntry]) -> JournalMood? {
        let moods = entries.compactMap(\.mood)
        return moods.isEmpty ? nil : moods.randomElement()
    }

    /// Determines the most frequently used activity type
    static func determineFavoriteActivity(
        quotesCount: Int,
        journalCount: Int,
        exerciseStats: ExerciseStats
    ) -> ActivityType? {
        let activityCounts = [
            ActivityType.quotes: quotesCount,
            ActivityType.journaling: journalCount,
            ActivityType.meditation: exerciseStats.meditationMinutes,
            ActivityType.breathing: exerciseStats.breathingSessions,
        ]
        return activityCounts.max { $0.value < $1.value }?.key
    }
}
