import Foundation

/// Breathing exercise pattern with timing for each phase
struct BreathingPattern: Codable, Sendable {
    var name: String
    var inhale: Int // Seconds to inhale
    var hold1: Int // Seconds to hold after inhale
    var exhale: Int // Seconds to exhale
    var hold2: Int // Seconds to hold after exhale
    var cycles: Int // Number of cycles to perform

    /// Total duration of one cycle in seconds
    var cycleDuration: Int {
        inhale + hold1 + exhale + hold2
    }

    /// Total duration of all cycles in seconds
    var totalDuration: Int {
        cycleDuration * cycles
    }

    // MARK: - Preset Patterns

    /// Box Breathing (4-4-4-4) - balanced breathing for stress relief
    static let box = BreathingPattern(
        name: "Box Breathing",
        inhale: 4,
        hold1: 4,
        exhale: 4,
        hold2: 4,
        cycles: 8
    )

    /// 4-7-8 Breathing - calming breath for relaxation and sleep
    static let calm = BreathingPattern(
        name: "4-7-8 Breathing",
        inhale: 4,
        hold1: 7,
        exhale: 8,
        hold2: 0,
        cycles: 4
    )

    /// Deep Breathing (5-2-5-2) - extended breath for deep relaxation
    static let deep = BreathingPattern(
        name: "Deep Breathing",
        inhale: 5,
        hold1: 2,
        exhale: 5,
        hold2: 2,
        cycles: 6
    )

    /// Energizing Breath (3-0-3-0) - quick breathing for energy
    static let energizing = BreathingPattern(
        name: "Energizing Breath",
        inhale: 3,
        hold1: 0,
        exhale: 3,
        hold2: 0,
        cycles: 10
    )

    /// All preset patterns
    static let allPatterns: [BreathingPattern] = [.box, .calm, .deep, .energizing]
}

/// Current phase of breathing exercise
enum BreathingPhase: Codable, Sendable {
    case inhale
    case hold1
    case exhale
    case hold2

    var displayName: String {
        switch self {
        case .inhale: "Inhale"
        case .hold1, .hold2: "Hold"
        case .exhale: "Exhale"
        }
    }

    var instruction: String {
        switch self {
        case .inhale: "Breathe in..."
        case .hold1, .hold2: "Hold your breath..."
        case .exhale: "Breathe out..."
        }
    }
}
