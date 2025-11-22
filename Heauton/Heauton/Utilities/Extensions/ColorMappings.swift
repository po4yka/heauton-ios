import SwiftUI

// MARK: - Achievement Category Colors

extension AchievementCategory {
    /// Returns the color associated with this achievement category
    var color: Color {
        switch self {
        case .quotes:
            return .categoryQuotes
        case .journaling:
            return .categoryJournaling
        case .meditation:
            return .categoryMeditation
        case .breathing:
            return .categoryBreathing
        case .consistency:
            return .categoryConsistency
        case .social:
            return .categorySocial
        }
    }
}

// MARK: - Exercise Difficulty Colors

extension Difficulty {
    /// Returns the SwiftUI Color for this difficulty level
    var swiftUIColor: Color {
        switch self {
        case .beginner:
            return .difficultyBeginner
        case .intermediate:
            return .difficultyIntermediate
        case .advanced:
            return .difficultyAdvanced
        }
    }
}

// MARK: - Exercise Type Colors

extension ExerciseType {
    /// Returns the color associated with this exercise type
    var color: Color {
        switch self {
        case .meditation:
            return .typeMeditation
        case .breathing:
            return .typeBreathing
        case .visualization:
            return .typeVisualization
        case .bodyScan:
            return .typeBodyScan
        }
    }
}
