import Foundation
import Observation

/// Observable service for managing exercise timers with real-time updates
@Observable
@MainActor
final class ExerciseTimerService {
    // MARK: - Published State

    var currentPhase: BreathingPhase = .inhale
    var timeRemaining: Int = 0
    var isRunning: Bool = false
    var currentCycle: Int = 1
    var totalCycles: Int = 1

    // MARK: - Private State

    private var pattern: BreathingPattern?
    private var timer: Timer?
    private var phaseStartTime: Date?
    private var elapsedTime: Int = 0

    // MARK: - Timer Control

    func start(pattern: BreathingPattern) {
        self.pattern = pattern
        totalCycles = pattern.cycles
        currentCycle = 1
        elapsedTime = 0

        startPhase(.inhale, duration: pattern.inhale)
        isRunning = true
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func resume() {
        guard let pattern else { return }

        // Resume from current phase
        let phaseDuration = duration(for: currentPhase, in: pattern)
        startPhase(currentPhase, duration: timeRemaining)
        isRunning = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        currentPhase = .inhale
        timeRemaining = 0
        currentCycle = 1
        pattern = nil
    }

    // MARK: - Private Methods

    private func startPhase(_ phase: BreathingPhase, duration: Int) {
        currentPhase = phase
        timeRemaining = duration
        phaseStartTime = Date()

        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let pattern else { return }

        timeRemaining -= 1
        elapsedTime += 1

        if timeRemaining <= 0 {
            advanceToNextPhase(pattern)
        }
    }

    private func advanceToNextPhase(_ pattern: BreathingPattern) {
        let nextPhase: BreathingPhase?
        var nextDuration = 0

        switch currentPhase {
        case .inhale:
            if pattern.hold1 > 0 {
                nextPhase = .hold1
                nextDuration = pattern.hold1
            } else {
                nextPhase = .exhale
                nextDuration = pattern.exhale
            }
        case .hold1:
            nextPhase = .exhale
            nextDuration = pattern.exhale
        case .exhale:
            if pattern.hold2 > 0 {
                nextPhase = .hold2
                nextDuration = pattern.hold2
            } else {
                // Completed one cycle
                if currentCycle < totalCycles {
                    currentCycle += 1
                    nextPhase = .inhale
                    nextDuration = pattern.inhale
                } else {
                    // Completed all cycles
                    stop()
                    return
                }
            }
        case .hold2:
            // Completed one cycle
            if currentCycle < totalCycles {
                currentCycle += 1
                nextPhase = .inhale
                nextDuration = pattern.inhale
            } else {
                // Completed all cycles
                stop()
                return
            }
        }

        if let nextPhase {
            startPhase(nextPhase, duration: nextDuration)
        }
    }

    private func duration(for phase: BreathingPhase, in pattern: BreathingPattern) -> Int {
        switch phase {
        case .inhale: pattern.inhale
        case .hold1: pattern.hold1
        case .exhale: pattern.exhale
        case .hold2: pattern.hold2
        }
    }

    /// Get total elapsed time in seconds
    var totalElapsedTime: Int {
        elapsedTime
    }

    /// Get progress percentage (0.0 to 1.0)
    var progress: Double {
        guard let pattern else { return 0.0 }
        let total = Double(pattern.totalDuration)
        return total > 0 ? Double(elapsedTime) / total : 0.0
    }
}
