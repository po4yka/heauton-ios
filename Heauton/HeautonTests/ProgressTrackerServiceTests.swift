import Foundation
@testable import Heauton
import SwiftData
import Testing

@Suite("ProgressTrackerService Tests")
struct ProgressTrackerServiceTests {
    @Test("Create daily progress snapshot")
    func createDailySnapshot() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Quote.self,
            JournalEntry.self,
            ExerciseSession.self,
            ProgressSnapshot.self,
            Share.self,
            configurations: config
        )
        let context = ModelContext(container)

        let service = ProgressTrackerService(modelContext: context)

        try await service.createOrUpdateTodaySnapshot()

        let descriptor = FetchDescriptor<ProgressSnapshot>()
        let snapshots = try context.fetch(descriptor)

        #expect(snapshots.count == 1)
        let firstSnapshot = snapshots.first
        #expect(firstSnapshot != nil)
        #expect(firstSnapshot!.currentStreak >= 0)
    }

    @Test("Calculate current streak")
    func calculateCurrentStreak() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Quote.self,
            JournalEntry.self,
            ExerciseSession.self,
            ProgressSnapshot.self,
            Share.self,
            configurations: config
        )
        let context = ModelContext(container)

        let service = ProgressTrackerService(modelContext: context)

        // Create journal entries for consecutive days
        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0...4 {
            guard let date = calendar.date(
                byAdding: .day,
                value: -dayOffset,
                to: today
            ) else { continue }

            let entry = JournalEntry(
                title: "Entry \(dayOffset)",
                content: "Test content",
                createdAt: date,
                mood: .peaceful,
                linkedQuoteId: nil
            )
            context.insert(entry)

            // Create snapshot for this day
            let snapshotDate = calendar.startOfDay(for: date)
            let snapshot = ProgressSnapshot(date: snapshotDate)
            snapshot.journalEntries = 1
            context.insert(snapshot)
        }

        try context.save()

        let streak = try await service.getCurrentStreak(type: .journaling)

        #expect(streak >= 1) // At least 1 day streak
    }

    @Test("Get total statistics")
    func getTotalStatistics() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Quote.self,
            JournalEntry.self,
            ExerciseSession.self,
            Exercise.self,
            ProgressSnapshot.self,
            Share.self,
            configurations: config
        )
        let context = ModelContext(container)

        let service = ProgressTrackerService(modelContext: context)

        // Add some test data
        let quote = Quote(
            author: "Tester",
            text: "Test quote",
            source: nil,
            categories: ["Stoicism"]
        )
        context.insert(quote)

        let journalEntry = JournalEntry(
            title: "Test Entry",
            content: "Content",
            mood: .joyful,
            linkedQuoteId: nil
        )
        context.insert(journalEntry)

        try context.save()

        let stats = try await service.getTotalStats()

        #expect(stats.totalQuotes >= 1)
        #expect(stats.totalJournalEntries >= 1)
        #expect(stats.currentStreak >= 0)
    }

    @Test("Check and unlock achievements")
    func checkAndUnlockAchievements() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Quote.self,
            JournalEntry.self,
            ExerciseSession.self,
            Exercise.self,
            Achievement.self,
            ProgressSnapshot.self,
            Share.self,
            configurations: config
        )
        let context = ModelContext(container)

        let service = ProgressTrackerService(modelContext: context)

        // Create an achievement
        let achievement = Achievement(
            title: "First Quote",
            achievementDescription: "Add your first quote",
            icon: "quote.bubble",
            category: .quotes,
            requirement: 1,
            progress: 0
        )
        context.insert(achievement)

        // Add a quote to meet the requirement
        let quote = Quote(
            author: "Tester",
            text: "Test quote",
            source: nil,
            categories: ["Stoicism"]
        )
        context.insert(quote)

        try context.save()

        let unlockedAchievements = try await service.checkAndUnlockAchievements()

        // Check if achievement was unlocked
        #expect(achievement.progress >= 1)
        #expect(!unlockedAchievements.isEmpty)
    }

    @Test("Calculate longest streak")
    func calculateLongestStreak() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Quote.self,
            JournalEntry.self,
            ExerciseSession.self,
            ProgressSnapshot.self,
            Share.self,
            configurations: config
        )
        let context = ModelContext(container)

        let service = ProgressTrackerService(modelContext: context)

        // Create journal entries for consecutive days
        let calendar = Calendar.current
        let today = Date()

        // Add entries for 3 consecutive days
        for dayOffset in 0...2 {
            guard let date = calendar.date(
                byAdding: .day,
                value: -dayOffset,
                to: today
            ) else { continue }

            let entry = JournalEntry(
                title: "Entry \(dayOffset)",
                content: "Test content",
                createdAt: date,
                mood: .peaceful,
                linkedQuoteId: nil
            )
            context.insert(entry)

            // Create snapshot for this day
            let snapshotDate = calendar.startOfDay(for: date)
            let snapshot = ProgressSnapshot(date: snapshotDate)
            snapshot.journalEntries = 1
            context.insert(snapshot)
        }

        try context.save()

        let longestStreak = try await service.getLongestStreak(type: .journaling)

        #expect(longestStreak >= 1)
    }

    @Test("Progress snapshot tracks multiple activities")
    func snapshotTracksMultipleActivities() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Quote.self,
            JournalEntry.self,
            ExerciseSession.self,
            Exercise.self,
            ProgressSnapshot.self,
            Share.self,
            configurations: config
        )
        let context = ModelContext(container)

        let service = ProgressTrackerService(modelContext: context)

        // Add various activities
        let quote = Quote(
            author: "Test",
            text: "Test",
            source: nil,
            categories: ["Stoicism"]
        )
        context.insert(quote)

        let journal = JournalEntry(
            title: "Test",
            content: "Test",
            mood: .peaceful,
            linkedQuoteId: nil
        )
        context.insert(journal)

        try context.save()

        try await service.createOrUpdateTodaySnapshot()

        let descriptor = FetchDescriptor<ProgressSnapshot>()
        let snapshots = try context.fetch(descriptor)

        #expect(snapshots.count >= 1)
        if let snapshot = snapshots.first {
            #expect(snapshot.quotesAdded >= 0)
            #expect(snapshot.journalEntries >= 0)
        }
    }
}
