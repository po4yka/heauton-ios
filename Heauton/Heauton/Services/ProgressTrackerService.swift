import Foundation
import SwiftData

/// Service for tracking user progress across all wellness activities
actor ProgressTrackerService: ProgressTrackerServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Streaks

    func getCurrentStreak(type: ActivityType) async throws -> Int {
        let snapshots = try await getRecentSnapshots(days: 365)
        return StreakCalculator.calculateCurrentStreak(from: snapshots, type: type)
    }

    func getLongestStreak(type: ActivityType) async throws -> Int {
        let snapshots = try await getRecentSnapshots(days: 365)
        return StreakCalculator.calculateLongestStreak(from: snapshots, type: type)
    }

    // MARK: - Aggregations

    func getTotalStats() async throws -> ProgressStats {
        let allData = try fetchAllData()
        let exerciseStats = ProgressStatsCalculator.calculateExerciseStats(from: allData.exerciseSessions)
        let streaks = try await calculateStreaks()
        let averageMood = ProgressStatsCalculator.calculateAverageMood(from: allData.journalEntries)
        let favoriteActivity = ProgressStatsCalculator.determineFavoriteActivity(
            quotesCount: allData.quotes.count,
            journalCount: allData.journalEntries.count,
            exerciseStats: exerciseStats
        )

        return ProgressStats(
            totalQuotes: allData.quotes.count,
            totalJournalEntries: allData.journalEntries.count,
            totalMeditationMinutes: exerciseStats.meditationMinutes,
            totalBreathingSessions: exerciseStats.breathingSessions,
            totalShares: allData.shares.count,
            currentStreak: streaks.current,
            longestStreak: streaks.longest,
            averageMood: averageMood,
            favoriteActivity: favoriteActivity
        )
    }

    private struct AllUserData {
        let quotes: [Quote]
        let journalEntries: [JournalEntry]
        let exerciseSessions: [ExerciseSession]
        let shares: [Share]
    }

    private func fetchAllData() throws -> AllUserData {
        let quotes = try modelContext.fetch(FetchDescriptor<Quote>())
        let journalEntries = try modelContext.fetch(FetchDescriptor<JournalEntry>())
        let exerciseSessions = try modelContext.fetch(FetchDescriptor<ExerciseSession>())
        let shares = try modelContext.fetch(FetchDescriptor<Share>())

        return AllUserData(
            quotes: quotes,
            journalEntries: journalEntries,
            exerciseSessions: exerciseSessions,
            shares: shares
        )
    }

    private func calculateStreaks() async throws -> (current: Int, longest: Int) {
        let current = try await getCurrentStreak(type: .any)
        let longest = try await getLongestStreak(type: .any)
        return (current, longest)
    }

    func getStatsForPeriod(start: Date, end: Date) async throws -> ProgressStats {
        let snapshots = try modelContext.fetch(
            FetchDescriptor<ProgressSnapshot>(
                predicate: #Predicate { $0.date >= start && $0.date <= end }
            )
        )

        return ProgressStats(
            totalQuotes: snapshots.reduce(0) { $0 + $1.quotesAdded },
            totalJournalEntries: snapshots.reduce(0) { $0 + $1.journalEntries },
            totalMeditationMinutes: snapshots.reduce(0) { $0 + $1.meditationMinutes },
            totalBreathingSessions: snapshots.reduce(0) { $0 + $1.breathingSessions },
            totalShares: 0,
            currentStreak: 0,
            longestStreak: 0,
            averageMood: nil,
            favoriteActivity: nil
        )
    }

    // MARK: - Achievements

    func checkAndUnlockAchievements() async throws -> [Achievement] {
        let achievements = try modelContext.fetch(FetchDescriptor<Achievement>())
        let stats = try await getTotalStats()
        var unlockedAchievements: [Achievement] = []

        for achievement in achievements where !achievement.isUnlocked {
            if AchievementChecker.updateAchievement(achievement, with: stats) {
                achievement.unlock()
                unlockedAchievements.append(achievement)
            }
        }

        try modelContext.save()
        return unlockedAchievements
    }

    func getAchievements() async throws -> [Achievement] {
        try modelContext.fetch(
            FetchDescriptor<Achievement>(
                sortBy: [SortDescriptor(\.unlockedAt, order: .reverse)]
            )
        )
    }

    func updateAchievementProgress(
        _ achievement: Achievement,
        progress: Int
    ) async throws {
        achievement.progress = progress
        if progress >= achievement.requirement, !achievement.isUnlocked {
            achievement.unlock()
        }
        try modelContext.save()
    }

    // MARK: - Daily Snapshots

    func createOrUpdateTodaySnapshot() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        let todaySnapshot = try getTodaySnapshot(for: today)
        let activities = try fetchTodayActivities(since: today)

        try await updateSnapshot(todaySnapshot, with: activities)
        try modelContext.save()
    }

    private func getTodaySnapshot(for today: Date) throws -> ProgressSnapshot {
        let descriptor = FetchDescriptor<ProgressSnapshot>(
            predicate: #Predicate { snapshot in snapshot.date >= today }
        )
        let existingSnapshots = try modelContext.fetch(descriptor)

        if let existing = existingSnapshots.first {
            return existing
        }

        let snapshot = ProgressSnapshot(date: today)
        modelContext.insert(snapshot)
        return snapshot
    }

    private struct TodayActivities {
        let quotes: [Quote]
        let journalEntries: [JournalEntry]
        let exerciseSessions: [ExerciseSession]
    }

    private func fetchTodayActivities(since today: Date) throws -> TodayActivities {
        let quotes = try modelContext.fetch(
            FetchDescriptor<Quote>(predicate: #Predicate { $0.createdAt >= today })
        )
        let journalEntries = try modelContext.fetch(
            FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.createdAt >= today })
        )
        let exerciseSessions = try modelContext.fetch(
            FetchDescriptor<ExerciseSession>(
                predicate: #Predicate { $0.startedAt >= today && $0.wasCompleted }
            )
        )

        return TodayActivities(
            quotes: quotes,
            journalEntries: journalEntries,
            exerciseSessions: exerciseSessions
        )
    }

    private func updateSnapshot(
        _ snapshot: ProgressSnapshot,
        with activities: TodayActivities
    ) async throws {
        snapshot.quotesAdded = activities.quotes.count
        snapshot.journalEntries = activities.journalEntries.count

        let exerciseStats = ProgressStatsCalculator.calculateExerciseStats(from: activities.exerciseSessions)
        snapshot.meditationMinutes = exerciseStats.meditationMinutes
        snapshot.breathingSessions = exerciseStats.breathingSessions
        snapshot.currentStreak = try await getCurrentStreak(type: .any)

        let moods = activities.journalEntries.compactMap(\.mood)
        snapshot.averageMood = moods.isEmpty ? nil : moods.randomElement()
    }

    func getRecentSnapshots(days: Int) async throws -> [ProgressSnapshot] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date.now) ?? Date.now
        return try modelContext.fetch(
            FetchDescriptor<ProgressSnapshot>(
                predicate: #Predicate { $0.date >= startDate },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
        )
    }
}
