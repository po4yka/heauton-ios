import Foundation
@testable import Heauton
import Testing

@Suite("ProgressDashboardViewModel Tests")
@MainActor
struct ProgressDashboardViewModelTests {
    @Test("Initial state")
    func initialState() async throws {
        let mockService = MockProgressTrackerService()
        let viewModel = ProgressDashboardViewModel(
            progressTrackerService: mockService
        )

        #expect(viewModel.stats == nil)
        #expect(viewModel.isLoading == true)
        #expect(viewModel.error == nil)
    }

    @Test("Load stats succeeds")
    func loadStatsSucceeds() async throws {
        let mockService = MockProgressTrackerService()

        let mockStats = ProgressStats(
            totalQuotes: 10,
            totalJournalEntries: 5,
            totalMeditationMinutes: 30,
            totalBreathingSessions: 8,
            totalShares: 3,
            currentStreak: 7,
            longestStreak: 12,
            averageMood: .joyful,
            favoriteActivity: .journaling
        )

        await mockService.setMockStats(mockStats)

        let viewModel = ProgressDashboardViewModel(
            progressTrackerService: mockService
        )

        await viewModel.loadStats()

        #expect(viewModel.stats != nil)
        #expect(viewModel.stats?.totalQuotes == 10)
        #expect(viewModel.stats?.currentStreak == 7)
        #expect(viewModel.stats?.longestStreak == 12)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test("Load stats fails with error")
    func loadStatsFails() async throws {
        let mockService = MockProgressTrackerService()
        await mockService.setShouldThrowError(true)

        let viewModel = ProgressDashboardViewModel(
            progressTrackerService: mockService
        )

        await viewModel.loadStats()

        #expect(viewModel.stats == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error != nil)
    }

    @Test("Refresh stats calls loadStats")
    func refreshStats() async throws {
        let mockService = MockProgressTrackerService()

        let mockStats = ProgressStats(
            totalQuotes: 5,
            totalJournalEntries: 3,
            totalMeditationMinutes: 15,
            totalBreathingSessions: 4,
            totalShares: 1,
            currentStreak: 3,
            longestStreak: 5,
            averageMood: .peaceful,
            favoriteActivity: .meditation
        )

        await mockService.setMockStats(mockStats)

        let viewModel = ProgressDashboardViewModel(
            progressTrackerService: mockService
        )

        await viewModel.refreshStats()

        #expect(viewModel.stats != nil)
        #expect(viewModel.stats?.totalQuotes == 5)
        #expect(viewModel.isLoading == false)
    }

    @Test("Unlocked achievements filtered correctly")
    func unlockedAchievements() async throws {
        let mockService = MockProgressTrackerService()
        let viewModel = ProgressDashboardViewModel(
            progressTrackerService: mockService
        )

        // Create test achievements
        let achievement1 = Achievement(
            title: "First Quote",
            achievementDescription: "Read your first quote",
            icon: "book",
            category: .quotes,
            requirement: 1,
            progress: 1,
            unlockedAt: Date().addingTimeInterval(-86400) // 1 day ago
        )

        let achievement2 = Achievement(
            title: "Week Streak",
            achievementDescription: "Maintain a 7-day streak",
            icon: "flame",
            category: .consistency,
            requirement: 7,
            progress: 7,
            unlockedAt: Date() // Now
        )

        let achievement3 = Achievement(
            title: "Locked Achievement",
            achievementDescription: "Not yet unlocked",
            icon: "lock",
            category: .quotes,
            requirement: 100,
            progress: 50,
            unlockedAt: nil
        )

        let allAchievements = [achievement1, achievement2, achievement3]

        let unlocked = viewModel.unlockedAchievements(from: allAchievements)

        #expect(unlocked.count == 2)
        // swiftformat:disable:next preferKeyPath
        #expect(unlocked.allSatisfy { $0.isUnlocked })

        // Should be sorted by unlock date (newest first)
        #expect(unlocked.first?.title == "Week Streak")
        #expect(unlocked.last?.title == "First Quote")
    }

    @Test("Recent achievements returns up to 5")
    func recentAchievements() async throws {
        let mockService = MockProgressTrackerService()
        let viewModel = ProgressDashboardViewModel(
            progressTrackerService: mockService
        )

        // Create 7 unlocked achievements
        var achievements: [Achievement] = []
        for index in 0..<7 {
            let achievement = Achievement(
                title: "Achievement \(index)",
                achievementDescription: "Description \(index)",
                icon: "star",
                category: .quotes,
                requirement: index + 1,
                progress: index + 1,
                unlockedAt: Date().addingTimeInterval(Double(-index * 3600)) // Each 1 hour apart
            )
            achievements.append(achievement)
        }

        let recent = viewModel.recentAchievements(from: achievements)

        // Should return only 5 achievements
        #expect(recent.count == 5)

        // Should be the most recent ones
        #expect(recent.first?.title == "Achievement 0")
        #expect(recent.last?.title == "Achievement 4")
    }

    @Test("Recent achievements with fewer than 5")
    func recentAchievementsLessThan5() async throws {
        let mockService = MockProgressTrackerService()
        let viewModel = ProgressDashboardViewModel(
            progressTrackerService: mockService
        )

        // Create only 3 achievements
        var achievements: [Achievement] = []
        for index in 0..<3 {
            let achievement = Achievement(
                title: "Achievement \(index)",
                achievementDescription: "Description \(index)",
                icon: "star",
                category: .quotes,
                requirement: index + 1,
                progress: index + 1,
                unlockedAt: Date()
            )
            achievements.append(achievement)
        }

        let recent = viewModel.recentAchievements(from: achievements)

        // Should return all 3
        #expect(recent.count == 3)
    }

    @Test("Empty achievements returns empty array")
    func emptyAchievements() async throws {
        let mockService = MockProgressTrackerService()
        let viewModel = ProgressDashboardViewModel(
            progressTrackerService: mockService
        )

        let unlocked = viewModel.unlockedAchievements(from: [])
        let recent = viewModel.recentAchievements(from: [])

        #expect(unlocked.isEmpty)
        #expect(recent.isEmpty)
    }
}

// Helper extensions for MockProgressTrackerService
extension MockProgressTrackerService {
    func setMockStats(_ stats: ProgressStats) async {
        mockStats = stats
    }

    func setShouldThrowError(_ value: Bool) async {
        shouldThrowError = value
    }
}
