import Foundation
import SwiftData

/// Sample achievements for seeding the database
enum SampleAchievements {
    private struct AchievementData {
        let title: String
        let description: String
        let icon: String
        let category: AchievementCategory
        let requirement: Int
        let isHidden: Bool
    }

    @MainActor
    static func seedIfNeeded(in context: ModelContext) async {
        let fetchDescriptor = FetchDescriptor<Achievement>()
        let existingAchievements = (try? context.fetch(fetchDescriptor)) ?? []

        guard existingAchievements.isEmpty else {
            return // Already seeded
        }

        seedSampleAchievements(modelContext: context)
    }

    private static var achievementsData: [AchievementData] {
        [
            // Quotes
            AchievementData(
                title: "First Steps",
                description: "Add your first quote to your collection",
                icon: "quote.bubble",
                category: .quotes,
                requirement: 1,
                isHidden: false
            ),
            AchievementData(
                title: "Quote Collector",
                description: "Add 10 quotes to your collection",
                icon: "books.vertical",
                category: .quotes,
                requirement: 10,
                isHidden: false
            ),
            AchievementData(
                title: "Philosopher",
                description: "Add 100 quotes to your collection",
                icon: "brain.head.profile",
                category: .quotes,
                requirement: 100,
                isHidden: false
            ),
            // Journaling
            AchievementData(
                title: "First Entry",
                description: "Write your first journal entry",
                icon: "book.closed",
                category: .journaling,
                requirement: 1,
                isHidden: false
            ),
            AchievementData(
                title: "Reflective Mind",
                description: "Write 10 journal entries",
                icon: "book.pages",
                category: .journaling,
                requirement: 10,
                isHidden: false
            ),
            AchievementData(
                title: "Journaling Master",
                description: "Write 50 journal entries",
                icon: "books.vertical.fill",
                category: .journaling,
                requirement: 50,
                isHidden: false
            ),
            // Meditation
            AchievementData(
                title: "First Meditation",
                description: "Complete your first meditation session",
                icon: "figure.mind.and.body",
                category: .meditation,
                requirement: 1,
                isHidden: false
            ),
            AchievementData(
                title: "Mindful Practice",
                description: "Complete 10 meditation sessions",
                icon: "sparkles",
                category: .meditation,
                requirement: 10,
                isHidden: false
            ),
            AchievementData(
                title: "Zen Master",
                description: "Meditate for 100 minutes total",
                icon: "infinity",
                category: .meditation,
                requirement: 100,
                isHidden: false
            ),
            // Breathing
            AchievementData(
                title: "First Breath",
                description: "Complete your first breathing exercise",
                icon: "wind",
                category: .breathing,
                requirement: 1,
                isHidden: false
            ),
            AchievementData(
                title: "Breathing Practice",
                description: "Complete 10 breathing exercises",
                icon: "lungs",
                category: .breathing,
                requirement: 10,
                isHidden: false
            ),
            AchievementData(
                title: "Breath Master",
                description: "Complete 50 breathing exercises",
                icon: "wind.circle",
                category: .breathing,
                requirement: 50,
                isHidden: false
            ),
            // Consistency
            AchievementData(
                title: "Getting Started",
                description: "Build a 3-day streak",
                icon: "flame",
                category: .consistency,
                requirement: 3,
                isHidden: false
            ),
            AchievementData(
                title: "Week Warrior",
                description: "Build a 7-day streak",
                icon: "flame.fill",
                category: .consistency,
                requirement: 7,
                isHidden: false
            ),
            AchievementData(
                title: "Dedicated",
                description: "Build a 30-day streak",
                icon: "star.fill",
                category: .consistency,
                requirement: 30,
                isHidden: false
            ),
            AchievementData(
                title: "Unstoppable",
                description: "Build a 100-day streak",
                icon: "bolt.fill",
                category: .consistency,
                requirement: 100,
                isHidden: true
            ),
            // Social
            AchievementData(
                title: "First Share",
                description: "Share your first quote",
                icon: "square.and.arrow.up",
                category: .social,
                requirement: 1,
                isHidden: false
            ),
            AchievementData(
                title: "Inspiration Spreader",
                description: "Share 10 quotes",
                icon: "heart.circle",
                category: .social,
                requirement: 10,
                isHidden: false
            ),
        ]
    }

    private static func seedSampleAchievements(modelContext: ModelContext) {
        for achievement in achievementsData {
            let newAchievement = Achievement(
                title: achievement.title,
                achievementDescription: achievement.description,
                icon: achievement.icon,
                category: achievement.category,
                requirement: achievement.requirement,
                isHidden: achievement.isHidden
            )
            modelContext.insert(newAchievement)
        }
    }
}
