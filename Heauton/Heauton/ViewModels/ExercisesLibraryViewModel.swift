import Foundation
import SwiftUI

/// ViewModel for ExercisesLibraryView following MVVM + @Observable pattern
/// Handles exercise filtering and search logic
@Observable
@MainActor
final class ExercisesLibraryViewModel {
    // MARK: - Published State

    var selectedType: ExerciseType?
    var selectedDifficulty: Difficulty?
    var searchText = ""

    // MARK: - Computed Properties

    /// Returns exercises filtered by type, difficulty, and search text
    func filteredExercises(from exercises: [Exercise]) -> [Exercise] {
        exercises.filter { exercise in
            let matchesType = selectedType == nil || exercise.type == selectedType
            let matchesDifficulty = selectedDifficulty == nil || exercise.difficulty == selectedDifficulty
            let matchesSearch = searchText.isEmpty ||
                exercise.title.localizedCaseInsensitiveContains(searchText) ||
                exercise.exerciseDescription.localizedCaseInsensitiveContains(searchText) ||
                exercise.category.localizedCaseInsensitiveContains(searchText)

            return matchesType && matchesDifficulty && matchesSearch
        }
    }

    /// Returns favorite exercises
    func favoriteExercises(from exercises: [Exercise]) -> [Exercise] {
        exercises.filter(\.isFavorite)
    }

    // MARK: - Public Methods

    /// Select a type filter
    func selectType(_ type: ExerciseType?) {
        selectedType = type
    }

    /// Toggle difficulty filter
    func toggleDifficulty(_ difficulty: Difficulty) {
        selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
    }

    /// Clear all filters
    func clearFilters() {
        selectedType = nil
        selectedDifficulty = nil
        searchText = ""
    }

    /// Check if any filters are active
    var hasActiveFilters: Bool {
        selectedType != nil || selectedDifficulty != nil || !searchText.isEmpty
    }
}
