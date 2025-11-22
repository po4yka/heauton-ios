import SwiftUI

extension Color {
    // MARK: - Hex Initializer

    /// Initialize a Color from a hex string
    /// Supports both 6-digit (RGB) and 8-digit (ARGB) hex strings
    // swiftlint:disable:next identifier_name
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 6: // RGB
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }

    // MARK: - Light Steel Palette - Light Colors

    /// Bright Snow - Lightest shade (F8F9FA)
    static let lsBrightSnow = Color(hex: "F8F9FA")

    /// Platinum - Very light gray (E9ECEF)
    static let lsPlatinum = Color(hex: "E9ECEF")

    /// Alabaster Grey - Light gray (DEE2E6)
    static let lsAlabasterGrey = Color(hex: "DEE2E6")

    /// Pale Slate - Medium-light gray (CED4DA)
    static let lsPaleSlate = Color(hex: "CED4DA")

    /// Pale Slate 2 - Medium gray (ADB5BD)
    static let lsPaleSlate2 = Color(hex: "ADB5BD")

    // MARK: - Light Steel Palette - Dark Colors

    /// Slate Grey - Medium-dark gray (6C757D)
    static let lsSlateGrey = Color(hex: "6C757D")

    /// Iron Grey - Dark gray (495057)
    static let lsIronGrey = Color(hex: "495057")

    /// Gunmetal - Very dark gray (343A40)
    static let lsGunmetal = Color(hex: "343A40")

    /// Shadow Grey - Darkest shade (212529)
    static let lsShadowGrey = Color(hex: "212529")

    // MARK: - Semantic Accent Colors (Light Mode)

    /// Alizarin Red - Errors, favorites, destructive actions (E74C3C)
    static let semanticError = Color(hex: "E74C3C")

    /// Orange - Warnings, alerts (F39C12)
    static let semanticWarning = Color(hex: "F39C12")

    /// Nephritis Green - Success, completions (27AE60)
    static let semanticSuccess = Color(hex: "27AE60")

    /// Peter River Blue - Info messages (3498DB)
    static let semanticInfo = Color(hex: "3498DB")

    // MARK: - Semantic Color Mappings
    // Note: appBackground, appSurface, appPrimary, and appText are defined in Assets catalog

    /// Secondary accent color
    static let appSecondary = lsSlateGrey

    /// Secondary text color
    static let appTextSecondary = lsGunmetal

    /// Border color for UI elements
    static let appBorder = lsAlabasterGrey

    /// Divider color for separators
    static let appDivider = lsPaleSlate

    // MARK: - Semantic Accent Mappings

    /// Red for hearts/favorites
    static let accentFavorite = semanticError

    /// Red for destructive actions
    static let accentDanger = semanticError

    /// Orange for alerts
    static let accentAlert = semanticWarning

    /// Green for completions
    static let accentComplete = semanticSuccess

    // MARK: - Mood Colors (for emotional expression)

    /// Warm Amber - Joyful, Motivated (FFB74D)
    static let moodEnergeticJoy = Color(hex: "FFB74D")

    /// Soft Green - Grateful, Peaceful (81C784)
    static let moodCalmGratitude = Color(hex: "81C784")

    /// Blue Grey - Neutral, Reflective (90A4AE)
    static let moodNeutralReflect = Color(hex: "90A4AE")

    /// Bright Orange - Anxious (FFA726)
    static let moodAlertAnxious = Color(hex: "FFA726")

    /// Soft Indigo - Sad, Frustrated (7986CB)
    static let moodSubduedSad = Color(hex: "7986CB")

    // MARK: - Mood Color Mapping

    /// Returns the appropriate mood color for a given mood
    /// - Parameter mood: The JournalMood enum value
    /// - Returns: The corresponding Color for the mood category
    static func moodColor(for mood: JournalMood) -> Color {
        switch mood {
        case .joyful, .motivated:
            return moodEnergeticJoy
        case .grateful, .peaceful:
            return moodCalmGratitude
        case .neutral, .reflective:
            return moodNeutralReflect
        case .anxious:
            return moodAlertAnxious
        case .sad, .frustrated:
            return moodSubduedSad
        }
    }

    // MARK: - Phase 3: Exercise Difficulty Colors

    /// Beginner difficulty - Green (4CAF50)
    static let difficultyBeginner = Color(hex: "4CAF50")

    /// Intermediate difficulty - Orange (FF9800)
    static let difficultyIntermediate = Color(hex: "FF9800")

    /// Advanced difficulty - Red (F44336)
    static let difficultyAdvanced = Color(hex: "F44336")

    // MARK: - Phase 3: Exercise Type Colors

    /// Meditation exercises - Purple (9C27B0)
    static let typeMeditation = Color(hex: "9C27B0")

    /// Breathing exercises - Blue (2196F3)
    static let typeBreathing = Color(hex: "2196F3")

    /// Visualization exercises - Cyan (00BCD4)
    static let typeVisualization = Color(hex: "00BCD4")

    /// Body scan exercises - Light Green (8BC34A)
    static let typeBodyScan = Color(hex: "8BC34A")

    // MARK: - Phase 3: Achievement Category Colors

    /// Quotes category - Indigo (3F51B5)
    static let categoryQuotes = Color(hex: "3F51B5")

    /// Journaling category - Deep Orange (FF5722)
    static let categoryJournaling = Color(hex: "FF5722")

    /// Meditation category - Purple (reuses typeMeditation)
    static let categoryMeditation = typeMeditation

    /// Breathing category - Blue (reuses typeBreathing)
    static let categoryBreathing = typeBreathing

    /// Consistency category - Green (4CAF50)
    static let categoryConsistency = Color(hex: "4CAF50")

    /// Social category - Pink (E91E63)
    static let categorySocial = Color(hex: "E91E63")

    // MARK: - Phase 3: Calendar Heatmap Colors

    /// Heatmap level 0 - No activity - Very light gray (E0E0E0)
    static let heatmapLevel0 = Color(hex: "E0E0E0")

    /// Heatmap level 1 - Minimal activity - Very light green (C8E6C9)
    static let heatmapLevel1 = Color(hex: "C8E6C9")

    /// Heatmap level 2 - Low activity - Light green (81C784)
    static let heatmapLevel2 = Color(hex: "81C784")

    /// Heatmap level 3 - Medium activity - Medium green (4CAF50)
    static let heatmapLevel3 = Color(hex: "4CAF50")

    /// Heatmap level 4 - High activity - Dark green (2E7D32)
    static let heatmapLevel4 = Color(hex: "2E7D32")

    /// Helper function to get heatmap color for a specific intensity level
    /// - Parameter level: Activity level from 0 (no activity) to 4+ (high activity)
    /// - Returns: The corresponding heatmap color
    static func heatmapColor(for level: Int) -> Color {
        switch level {
        case 0: return heatmapLevel0
        case 1: return heatmapLevel1
        case 2: return heatmapLevel2
        case 3: return heatmapLevel3
        default: return heatmapLevel4
        }
    }
}

// MARK: - JournalMood Extension

extension JournalMood {
    /// Convenience property to get the mood color
    var color: Color {
        Color.moodColor(for: self)
    }
}
