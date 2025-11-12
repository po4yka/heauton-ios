import Foundation
import SwiftUI

/// ViewModel for ExerciseDetailView following MVVM + @Observable pattern
/// Handles exercise presentation and routing logic
@Observable
@MainActor
final class ExerciseDetailViewModel {
    // MARK: - Dependencies

    private let exercise: Exercise

    // MARK: - Published State

    var showingBreathingExercise = false
    var showingGenericExercise = false

    // MARK: - Computed Properties

    var exerciseTitle: String {
        exercise.title
    }

    var exerciseDescription: String {
        exercise.exerciseDescription
    }

    var exerciseType: ExerciseType {
        exercise.type
    }

    var difficulty: Difficulty {
        exercise.difficulty
    }

    var formattedDuration: String {
        exercise.formattedDuration
    }

    var category: String {
        exercise.category
    }

    var instructions: [String] {
        exercise.instructions
    }

    var difficultyColor: Color {
        Color(exercise.difficulty.color)
    }

    var typeIcon: String {
        exercise.type.icon
    }

    // MARK: - Initialization

    init(exercise: Exercise) {
        self.exercise = exercise
    }

    // MARK: - Public Methods

    /// Start the exercise based on its type
    func startExercise() {
        switch exercise.type {
        case .breathing:
            showingBreathingExercise = true
        case .meditation, .bodyScan, .visualization:
            showingGenericExercise = true
        }
    }

    /// Get the exercise object (for passing to sub-views)
    func getExercise() -> Exercise {
        exercise
    }

    /// Check if this is a breathing exercise
    var isBreathingExercise: Bool {
        exercise.type == .breathing
    }

    /// Check if this is a generic exercise
    var isGenericExercise: Bool {
        switch exercise.type {
        case .breathing:
            false
        case .meditation, .bodyScan, .visualization:
            true
        }
    }
}
