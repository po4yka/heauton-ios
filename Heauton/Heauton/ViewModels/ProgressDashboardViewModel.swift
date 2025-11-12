import Foundation
import SwiftUI

/// ViewModel for ProgressDashboardView following MVVM + @Observable pattern
/// Handles progress statistics and achievement management
@Observable
@MainActor
final class ProgressDashboardViewModel {
    // MARK: - Dependencies

    private let progressTrackerService: ProgressTrackerServiceProtocol

    // MARK: - Published State

    var stats: ProgressStats?
    var isLoading = true
    var error: Error?

    // MARK: - Initialization

    init(progressTrackerService: ProgressTrackerServiceProtocol) {
        self.progressTrackerService = progressTrackerService
    }

    // MARK: - Public Methods

    /// Load statistics from the service
    func loadStats() async {
        isLoading = true
        error = nil

        do {
            stats = try await progressTrackerService.getTotalStats()

            // Check for new achievements
            _ = try await progressTrackerService.checkAndUnlockAchievements()
        } catch let loadError {
            error = loadError
            // Handle error silently as per original implementation
        }

        isLoading = false
    }

    /// Refresh stats (for pull to refresh)
    func refreshStats() async {
        await loadStats()
    }

    /// Filter unlocked achievements sorted by unlock date
    func unlockedAchievements(from achievements: [Achievement]) -> [Achievement] {
        achievements
            .filter(\.isUnlocked)
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
    }

    /// Get recent achievements (up to 5)
    func recentAchievements(from achievements: [Achievement]) -> [Achievement] {
        Array(unlockedAchievements(from: achievements).prefix(5))
    }
}
