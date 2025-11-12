import Foundation

/// Helper for checking and updating achievement progress
enum AchievementChecker {
    /// Updates achievement progress based on stats and determines if it should be unlocked
    static func updateAchievement(
        _ achievement: Achievement,
        with stats: ProgressStats
    ) -> Bool {
        var shouldUnlock = false

        switch achievement.category {
        case .quotes:
            achievement.progress = stats.totalQuotes
            shouldUnlock = stats.totalQuotes >= achievement.requirement

        case .journaling:
            achievement.progress = stats.totalJournalEntries
            shouldUnlock = stats.totalJournalEntries >= achievement.requirement

        case .meditation:
            achievement.progress = stats.totalMeditationMinutes
            shouldUnlock = stats.totalMeditationMinutes >= achievement.requirement

        case .breathing:
            achievement.progress = stats.totalBreathingSessions
            shouldUnlock = stats.totalBreathingSessions >= achievement.requirement

        case .consistency:
            achievement.progress = stats.currentStreak
            shouldUnlock = stats.currentStreak >= achievement.requirement

        case .social:
            achievement.progress = stats.totalShares
            shouldUnlock = stats.totalShares >= achievement.requirement
        }

        return shouldUnlock
    }
}
