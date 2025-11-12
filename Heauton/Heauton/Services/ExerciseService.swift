import Foundation
import SwiftData

/// Service for managing wellness exercises and sessions
actor ExerciseService: ExerciseServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Exercise Management

    func fetchExercises(
        type: ExerciseType? = nil,
        difficulty: Difficulty? = nil
    ) async throws -> [Exercise] {
        var descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.title, order: .forward)]
        )

        // Build predicate if filters are provided
        if let type, let difficulty {
            descriptor.predicate = #Predicate<Exercise> { exercise in
                exercise.type == type && exercise.difficulty == difficulty
            }
        } else if let type {
            descriptor.predicate = #Predicate<Exercise> { exercise in
                exercise.type == type
            }
        } else if let difficulty {
            descriptor.predicate = #Predicate<Exercise> { exercise in
                exercise.difficulty == difficulty
            }
        }

        return try modelContext.fetch(descriptor)
    }

    func getFavoritesExercises() async throws -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.title, order: .forward)]
        )

        return try modelContext.fetch(descriptor)
    }

    // MARK: - Session Management

    func createSession(_ exercise: Exercise) async throws -> ExerciseSession {
        let session = ExerciseSession(
            linkedExerciseId: exercise.id
        )
        modelContext.insert(session)
        try modelContext.save()
        return session
    }

    func completeSession(
        _ session: ExerciseSession,
        actualDuration: Int,
        moodAfter: JournalMood? = nil,
        notes: String? = nil
    ) async throws {
        session.completedAt = Date.now
        session.actualDuration = actualDuration
        session.wasCompleted = true
        session.moodAfter = moodAfter
        session.notes = notes
        try modelContext.save()
    }

    func getSessionHistory(limit: Int? = nil) async throws -> [ExerciseSession] {
        var descriptor = FetchDescriptor<ExerciseSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )

        if let limit {
            descriptor.fetchLimit = limit
        }

        return try modelContext.fetch(descriptor)
    }

    // MARK: - Recommendations

    func getRecommendedExercise(mood: JournalMood? = nil) async throws -> Exercise? {
        // Recommend based on mood
        let category: String? = switch mood {
        case .anxious, .frustrated:
            "Stress Relief"
        case .sad:
            "Mood Boost"
        case .peaceful, .grateful:
            "Gratitude"
        case .motivated, .joyful:
            "Focus"
        default:
            nil
        }

        let descriptor = if let category {
            FetchDescriptor<Exercise>(
                predicate: #Predicate { exercise in
                    exercise.category == category
                },
                sortBy: [SortDescriptor(\.title, order: .forward)]
            )
        } else {
            FetchDescriptor<Exercise>(
                sortBy: [SortDescriptor(\.title, order: .forward)]
            )
        }

        let exercises = try modelContext.fetch(descriptor)
        return exercises.randomElement()
    }
}
