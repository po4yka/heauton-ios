import Foundation
@testable import Heauton
import SwiftData
import Testing

@Suite("ExerciseService Tests")
struct ExerciseServiceTests {
    @Test("Create exercise session")
    func createExerciseSession() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Exercise.self,
            ExerciseSession.self,
            configurations: config
        )
        let context = ModelContext(container)

        let service = ExerciseService(modelContext: context)

        // Create a sample exercise
        let exercise = Exercise(
            title: "Box Breathing",
            exerciseDescription: "A calming breathing technique",
            type: .breathing,
            duration: 5,
            difficulty: .beginner,
            instructions: ["Inhale for 4 seconds", "Hold for 4 seconds"],
            category: "Stress Relief"
        )
        context.insert(exercise)
        try context.save()

        // Create a session
        let session = try await service.createSession(exercise)

        #expect(session.linkedExerciseId == exercise.id)
        #expect(session.wasCompleted == false)
        #expect(session.actualDuration == 0)
    }

    @Test("Complete exercise session with mood tracking")
    func completeExerciseSession() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Exercise.self,
            ExerciseSession.self,
            configurations: config
        )
        let context = ModelContext(container)

        let service = ExerciseService(modelContext: context)

        let exercise = Exercise(
            title: "Meditation",
            exerciseDescription: "Mindful breathing meditation",
            type: .meditation,
            duration: 10,
            difficulty: .intermediate,
            instructions: ["Sit comfortably", "Focus on breath"],
            category: "Mindfulness"
        )
        context.insert(exercise)
        try context.save()

        // Create and complete session
        let session = try await service.createSession(exercise)
        try await service.completeSession(
            session,
            actualDuration: 600,
            moodAfter: .peaceful,
            notes: "Felt very peaceful"
        )

        #expect(session.wasCompleted == true)
        #expect(session.actualDuration == 600)
        #expect(session.moodAfter == .peaceful)
        #expect(session.notes == "Felt very peaceful")
        #expect(session.completedAt != nil)
    }

    @Test("Fetch exercises by type", .disabled("SwiftData query issue in test environment"))
    func fetchExercisesByType() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Exercise.self,
            ExerciseSession.self,
            configurations: config
        )
        let context = ModelContext(container)

        let service = ExerciseService(modelContext: context)

        // Create exercises of different types
        let breathing = Exercise(
            title: "Deep Breathing",
            exerciseDescription: "Breathing exercise",
            type: .breathing,
            duration: 5,
            difficulty: .beginner,
            instructions: ["Breathe deeply"],
            category: "Relaxation"
        )

        let meditation = Exercise(
            title: "Meditation",
            exerciseDescription: "Meditation exercise",
            type: .meditation,
            duration: 10,
            difficulty: .beginner,
            instructions: ["Meditate"],
            category: "Mindfulness"
        )

        context.insert(breathing)
        context.insert(meditation)
        try context.save()

        // Fetch only breathing exercises
        let breathingExercises = try await service.fetchExercises(
            type: .breathing,
            difficulty: nil
        )

        #expect(breathingExercises.count == 1)
        #expect(breathingExercises.first?.type == .breathing)
    }

    @Test("Fetch exercises by difficulty", .disabled("SwiftData query issue in test environment"))
    func fetchExercisesByDifficulty() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Exercise.self,
            ExerciseSession.self,
            configurations: config
        )
        let context = ModelContext(container)

        let service = ExerciseService(modelContext: context)

        let beginner = Exercise(
            title: "Easy Exercise",
            exerciseDescription: "Beginner level",
            type: .breathing,
            duration: 3,
            difficulty: .beginner,
            instructions: ["Easy steps"],
            category: "Basics"
        )

        let advanced = Exercise(
            title: "Advanced Exercise",
            exerciseDescription: "Advanced level",
            type: .breathing,
            duration: 15,
            difficulty: .advanced,
            instructions: ["Complex steps"],
            category: "Expert"
        )

        context.insert(beginner)
        context.insert(advanced)
        try context.save()

        let beginnerExercises = try await service.fetchExercises(
            type: nil,
            difficulty: .beginner
        )

        #expect(beginnerExercises.count == 1)
        #expect(beginnerExercises.first?.difficulty == .beginner)
    }

    @Test("Get recommended exercise based on mood")
    func getRecommendedExercise() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Exercise.self,
            ExerciseSession.self,
            configurations: config
        )
        let context = ModelContext(container)

        let service = ExerciseService(modelContext: context)

        // Create sample exercises
        let exercise = Exercise(
            title: "Calming Exercise",
            exerciseDescription: "For stress relief",
            type: .breathing,
            duration: 5,
            difficulty: .beginner,
            instructions: ["Breathe slowly"],
            category: "Stress Relief"
        )

        context.insert(exercise)
        try context.save()

        let recommended = try await service.getRecommendedExercise(mood: .anxious)

        #expect(recommended != nil)
    }
}
