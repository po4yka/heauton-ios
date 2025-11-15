import Foundation
import SwiftData

/// Sample journal prompts for seeding the database
enum SampleJournalPrompts {
    @MainActor
    static func seedIfNeeded(in context: ModelContext) async {
        let fetchDescriptor = FetchDescriptor<JournalPrompt>()
        let existingPrompts = (try? context.fetch(fetchDescriptor)) ?? []

        guard existingPrompts.isEmpty else {
            return // Already seeded
        }

        let prompts: [(String, PromptCategory)] = [
            // Reflection
            ("What did I learn about myself today?", .reflection),
            ("What challenged my perspective today?", .reflection),
            ("What moment today made me pause and think?", .reflection),

            // Gratitude
            ("What three things am I grateful for today?", .gratitude),
            ("Who made a positive impact on my day?", .gratitude),
            ("What simple pleasure brought me joy today?", .gratitude),

            // Growth
            ("What skill or knowledge did I develop today?", .growth),
            ("How did I step outside my comfort zone?", .growth),
            ("What mistake taught me something valuable?", .growth),

            // Goals
            ("What progress did I make toward my goals today?", .goals),
            ("What's one thing I want to accomplish this week?", .goals),
            ("How can I make tomorrow better than today?", .goals),

            // Mindfulness
            ("How am I feeling right now, and why?", .mindfulness),
            ("What sensations do I notice in my body?", .mindfulness),
            ("What emotions came up for me today?", .mindfulness),

            // Relationships
            ("How did I show kindness to someone today?", .relationships),
            ("What conversation had the biggest impact on me?", .relationships),
            ("Who do I need to reconnect with?", .relationships),

            // Creativity
            ("What inspired me today?", .creativity),
            ("If I could create anything, what would it be?", .creativity),
            ("What new idea excited me today?", .creativity),

            // Challenges
            ("What obstacle did I overcome today?", .challenges),
            ("What's currently weighing on my mind?", .challenges),
            ("How can I reframe a current challenge?", .challenges),
        ]

        for (text, category) in prompts {
            let prompt = JournalPrompt(
                text: text,
                category: category
            )
            context.insert(prompt)
        }

        try? context.save()
    }
}
