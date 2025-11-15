import Foundation
import OSLog
import SwiftData

/// Provides sample user events for testing and initial app setup
enum SampleEvents {
    private static let logger = Logger(subsystem: "com.heauton.app", category: "SampleData")

    /// Seeds sample events if needed (only on first launch)
    @MainActor
    static func seedIfNeeded(in context: ModelContext) async {
        let descriptor = FetchDescriptor<UserEvent>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        // Only seed if there are no events
        guard existingCount == 0 else { return }

        let sampleEvents = createSampleEvents()

        for event in sampleEvents {
            context.insert(event)
        }

        do {
            try context.save()
            logger.info("Successfully seeded \(sampleEvents.count) sample events")
        } catch {
            logger.error("Failed to save sample events: \(error.localizedDescription)")
        }
    }

    /// Creates an array of sample events for testing
    private static func createSampleEvents() -> [UserEvent] {
        [
            createFirstLoginEvent(),
            createMorningMeditationEvent(),
            createEveningMeditationEvent(),
            createDailyReflectionEvent(),
            createGratitudeJournalEvent(),
            createMilestoneEvent(),
            createReadingEvent(),
            createExerciseEvent(),
            createMoodEvent(),
            createHabitEvent(),
        ]
    }

    private static func createFirstLoginEvent() -> UserEvent {
        UserEvent(
            type: .firstLogin,
            title: "Your first day in stoic",
            eventDescription: "Welcome to your journey of self-improvement and mindfulness.",
            createdAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        )
    }

    private static func createMorningMeditationEvent() -> UserEvent {
        UserEvent(
            type: .meditation,
            title: "Morning meditation",
            eventDescription: "Focused breathing and mindfulness practice",
            createdAt: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date(),
            duration: 15
        )
    }

    private static func createEveningMeditationEvent() -> UserEvent {
        UserEvent(
            type: .meditation,
            title: "Evening meditation",
            eventDescription: "Reflection on the day's experiences",
            createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            duration: 20
        )
    }

    private static func createDailyReflectionEvent() -> UserEvent {
        UserEvent(
            type: .journalEntry,
            title: "Daily reflection",
            eventDescription: "Wrote about today's challenges and lessons learned",
            createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()
        )
    }

    private static func createGratitudeJournalEvent() -> UserEvent {
        UserEvent(
            type: .journalEntry,
            title: "Gratitude journal",
            eventDescription: "Listed three things I'm grateful for today",
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        )
    }

    private static func createMilestoneEvent() -> UserEvent {
        UserEvent(
            type: .milestone,
            title: "7 days streak",
            eventDescription: "Maintained a daily meditation practice for a full week",
            createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        )
    }

    private static func createReadingEvent() -> UserEvent {
        UserEvent(
            type: .reading,
            title: "Meditations by Marcus Aurelius",
            eventDescription: "Read chapters 3-5, focusing on the nature of change",
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            duration: 45
        )
    }

    private static func createExerciseEvent() -> UserEvent {
        UserEvent(
            type: .exercise,
            title: "Morning run",
            eventDescription: "5km run in the park",
            createdAt: Date(),
            duration: 30,
            value: 5.0
        )
    }

    private static func createMoodEvent() -> UserEvent {
        UserEvent(
            type: .mood,
            title: "Feeling productive",
            eventDescription: "Completed all planned tasks for the day",
            createdAt: Date(),
            value: 8.5
        )
    }

    private static func createHabitEvent() -> UserEvent {
        UserEvent(
            type: .habit,
            title: "Cold shower",
            eventDescription: "Started the day with a cold shower",
            createdAt: Date()
        )
    }
}
