import Foundation
import SwiftData

/// Sample wellness exercises for seeding the database
enum SampleExercises {
    private struct ExerciseData {
        let title: String
        let description: String
        let type: ExerciseType
        let duration: Int
        let difficulty: Difficulty
        let instructions: [String]
        let category: String
    }

    @MainActor
    static func seedIfNeeded(in context: ModelContext) async {
        let fetchDescriptor = FetchDescriptor<Exercise>()
        let existingExercises = (try? context.fetch(fetchDescriptor)) ?? []

        guard existingExercises.isEmpty else {
            return // Already seeded
        }

        seedSampleExercises(modelContext: context)
    }

    private static var exercisesData: [ExerciseData] {
        [
            // Breathing Exercises
            ExerciseData(
                title: "Box Breathing",
                description: """
                A powerful stress-relief technique used by Navy SEALs. \
                Breathe in a balanced 4-4-4-4 pattern.
                """,
                type: .breathing,
                duration: 256,
                difficulty: .beginner,
                instructions: [
                    "Sit comfortably with your back straight",
                    "Breathe in for 4 seconds",
                    "Hold for 4 seconds",
                    "Breathe out for 4 seconds",
                    "Hold for 4 seconds",
                    "Repeat for 8 cycles",
                ],
                category: "Stress Relief"
            ),
            ExerciseData(
                title: "4-7-8 Breathing",
                description: "Dr. Andrew Weil's relaxation breath. Perfect for calming anxiety and promoting sleep.",
                type: .breathing,
                duration: 76,
                difficulty: .beginner,
                instructions: [
                    "Place tongue behind upper front teeth",
                    "Breathe in through nose for 4 seconds",
                    "Hold breath for 7 seconds",
                    "Exhale completely through mouth for 8 seconds",
                    "Complete 4 cycles",
                ],
                category: "Sleep & Relaxation"
            ),
            ExerciseData(
                title: "Deep Breathing",
                description: "Extended breath cycles for deep relaxation and stress reduction.",
                type: .breathing,
                duration: 252,
                difficulty: .intermediate,
                instructions: [
                    "Find a quiet comfortable space",
                    "Breathe in slowly for 5 seconds",
                    "Hold for 2 seconds",
                    "Exhale slowly for 5 seconds",
                    "Pause for 2 seconds",
                    "Repeat for 6 cycles",
                ],
                category: "Stress Relief"
            ),
            // Meditation Exercises
            ExerciseData(
                title: "Mindful Breathing Meditation",
                description: "Focus on the natural rhythm of your breath to cultivate present-moment awareness.",
                type: .meditation,
                duration: 300,
                difficulty: .beginner,
                instructions: [
                    "Sit in a comfortable position",
                    "Close your eyes gently",
                    "Notice the sensation of breathing",
                    "When mind wanders, gently return focus to breath",
                    "Continue for 5 minutes",
                ],
                category: "Mindfulness"
            ),
            ExerciseData(
                title: "Loving-Kindness Meditation",
                description: "Cultivate compassion for yourself and others through focused well-wishing.",
                type: .meditation,
                duration: 600,
                difficulty: .intermediate,
                instructions: [
                    "Sit comfortably and close your eyes",
                    "Begin with yourself: 'May I be happy, may I be healthy'",
                    "Extend to loved ones",
                    "Extend to neutral people",
                    "Extend to difficult people",
                    "Extend to all beings",
                ],
                category: "Gratitude"
            ),
            ExerciseData(
                title: "Morning Gratitude Meditation",
                description: "Start your day by reflecting on things you're grateful for.",
                type: .meditation,
                duration: 300,
                difficulty: .beginner,
                instructions: [
                    "Sit quietly and breathe deeply",
                    "Think of 3 things you're grateful for",
                    "Feel the gratitude in your body",
                    "Set an intention for the day",
                    "Take 3 deep breaths",
                ],
                category: "Gratitude"
            ),
            // Body Scan Exercises
            ExerciseData(
                title: "Progressive Body Scan",
                description: "Systematic relaxation by bringing awareness to each part of your body.",
                type: .bodyScan,
                duration: 900,
                difficulty: .intermediate,
                instructions: [
                    "Lie down comfortably",
                    "Close your eyes and breathe deeply",
                    "Bring attention to your feet",
                    "Gradually move awareness up through your body",
                    "Notice sensations without judgment",
                    "End at the crown of your head",
                ],
                category: "Stress Relief"
            ),
            ExerciseData(
                title: "Quick Body Check-In",
                description: "A brief body scan to release tension and reset during your day.",
                type: .bodyScan,
                duration: 180,
                difficulty: .beginner,
                instructions: [
                    "Sit or stand comfortably",
                    "Take 3 deep breaths",
                    "Scan from head to toe",
                    "Notice areas of tension",
                    "Breathe into tense areas",
                    "Gently release and relax",
                ],
                category: "Focus"
            ),
            // Visualization Exercises
            ExerciseData(
                title: "Safe Place Visualization",
                description: "Create a mental sanctuary for peace and calm.",
                type: .visualization,
                duration: 420,
                difficulty: .beginner,
                instructions: [
                    "Close your eyes and breathe deeply",
                    "Imagine a place where you feel completely safe",
                    "Notice the details - sights, sounds, smells",
                    "Feel the peace this place brings",
                    "Know you can return here anytime",
                ],
                category: "Mood Boost"
            ),
            ExerciseData(
                title: "Energy Centering",
                description: "Visualize gathering and centering your energy for focus and motivation.",
                type: .visualization,
                duration: 300,
                difficulty: .intermediate,
                instructions: [
                    "Sit with spine straight",
                    "Visualize energy at your core",
                    "With each inhale, gather scattered energy",
                    "With each exhale, let go of what doesn't serve you",
                    "Feel centered and focused",
                ],
                category: "Focus"
            ),
        ]
    }

    private static func seedSampleExercises(modelContext: ModelContext) {
        for exercise in exercisesData {
            let newExercise = Exercise(
                title: exercise.title,
                exerciseDescription: exercise.description,
                type: exercise.type,
                duration: exercise.duration,
                difficulty: exercise.difficulty,
                instructions: exercise.instructions,
                category: exercise.category
            )
            modelContext.insert(newExercise)
        }
    }
}
