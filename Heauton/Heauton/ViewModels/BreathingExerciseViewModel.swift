import Foundation
import SwiftUI

/// ViewModel for BreathingExerciseView following MVVM + @Observable pattern
/// Handles exercise timer, session management, and breathing animation logic
@Observable
@MainActor
final class BreathingExerciseViewModel {
    // MARK: - Dependencies

    private let exerciseService: ExerciseServiceProtocol
    private let exercise: Exercise

    // MARK: - Published State

    var timerService = ExerciseTimerService()
    var session: ExerciseSession?
    var showingCompletion = false
    var circleScale: CGFloat = 1.0

    // MARK: - Computed Properties

    var gradientColors: [Color] {
        switch timerService.currentPhase {
        case .inhale:
            [.lsPaleSlate.opacity(0.6), .lsSlateGrey.opacity(0.6)]
        case .hold1, .hold2:
            [.lsSlateGrey.opacity(0.6), .lsIronGrey.opacity(0.6)]
        case .exhale:
            [.lsIronGrey.opacity(0.6), .lsGunmetal.opacity(0.6)]
        }
    }

    var showResumeButton: Bool {
        !timerService.isRunning && session != nil
    }

    var showPauseButton: Bool {
        timerService.isRunning
    }

    // MARK: - Initialization

    init(
        exercise: Exercise,
        exerciseService: ExerciseServiceProtocol
    ) {
        self.exercise = exercise
        self.exerciseService = exerciseService
    }

    // MARK: - Public Methods

    /// Start the exercise
    func startExercise() async {
        // Create session
        session = try? await exerciseService.createSession(exercise)

        // Determine breathing pattern based on exercise title
        let pattern = determinePattern(from: exercise.title)

        // Start timer
        timerService.start(pattern: pattern)
    }

    /// Resume the exercise
    func resumeExercise() {
        timerService.resume()
    }

    /// Pause the exercise
    func pauseExercise() {
        timerService.pause()
    }

    /// Stop and complete the exercise
    func stopExercise() async {
        timerService.stop()

        guard let session else { return }

        try? await exerciseService.completeSession(
            session,
            actualDuration: timerService.totalElapsedTime,
            moodAfter: nil,
            notes: nil
        )

        showingCompletion = true
    }

    /// Get animation parameters for current phase
    func animationParameters(for phase: BreathingPhase) -> (duration: Double, scale: CGFloat) {
        switch phase {
        case .inhale:
            (duration: 4.0, scale: 1.5)
        case .hold1, .hold2:
            (duration: 0.5, scale: circleScale)
        case .exhale:
            (duration: 4.0, scale: 1.0)
        }
    }

    /// Update circle scale for animation
    func updateCircleScale(_ scale: CGFloat) {
        circleScale = scale
    }

    /// Check if exercise is complete
    func checkCompletion() async {
        if !timerService.isRunning, timerService.totalElapsedTime > 0 {
            await stopExercise()
        }
    }

    // MARK: - Private Methods

    private func determinePattern(from title: String) -> BreathingPattern {
        if title.contains("Box") {
            .box
        } else if title.contains("4-7-8") {
            .calm
        } else if title.contains("Deep") {
            .deep
        } else {
            .box // Default
        }
    }
}
