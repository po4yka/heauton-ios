import Foundation
@testable import Heauton

/// Mock Progress Tracker Service for testing ViewModels
actor MockProgressTrackerService: ProgressTrackerServiceProtocol {
    var mockStats: ProgressStats?
    var mockAchievements: [Achievement] = []
    var shouldThrowError = false

    func getCurrentStreak(type _: ActivityType) async throws -> Int {
        if shouldThrowError {
            throw MockError.operationFailed
        }
        return mockStats?.currentStreak ?? 0
    }

    func getLongestStreak(type _: ActivityType) async throws -> Int {
        if shouldThrowError {
            throw MockError.operationFailed
        }
        return mockStats?.longestStreak ?? 0
    }

    func getTotalStats() async throws -> ProgressStats {
        if shouldThrowError {
            throw MockError.operationFailed
        }
        return mockStats ?? ProgressStats(
            totalQuotes: 0,
            totalJournalEntries: 0,
            totalMeditationMinutes: 0,
            totalBreathingSessions: 0,
            totalShares: 0,
            currentStreak: 0,
            longestStreak: 0,
            averageMood: nil,
            favoriteActivity: nil
        )
    }

    func getStatsForPeriod(start _: Date, end _: Date) async throws -> ProgressStats {
        if shouldThrowError {
            throw MockError.operationFailed
        }
        return mockStats ?? ProgressStats(
            totalQuotes: 0,
            totalJournalEntries: 0,
            totalMeditationMinutes: 0,
            totalBreathingSessions: 0,
            totalShares: 0,
            currentStreak: 0,
            longestStreak: 0,
            averageMood: nil,
            favoriteActivity: nil
        )
    }

    func checkAndUnlockAchievements() async throws -> [Achievement] {
        if shouldThrowError {
            throw MockError.operationFailed
        }
        return mockAchievements.filter(\.isUnlocked)
    }

    func getAchievements() async throws -> [Achievement] {
        if shouldThrowError {
            throw MockError.operationFailed
        }
        return mockAchievements
    }

    func updateAchievementProgress(
        _: Achievement,
        progress _: Int
    ) async throws {
        if shouldThrowError {
            throw MockError.operationFailed
        }
    }

    func createOrUpdateTodaySnapshot() async throws {
        if shouldThrowError {
            throw MockError.operationFailed
        }
    }

    func getRecentSnapshots(days _: Int) async throws -> [ProgressSnapshot] {
        if shouldThrowError {
            throw MockError.operationFailed
        }
        return []
    }
}
