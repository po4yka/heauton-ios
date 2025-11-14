import SwiftUI

extension Font {
    // MARK: - Fira Code Custom Fonts

    /// Fira Code with specified size and weight
    static func firaCode(size: CGFloat, weight: FiraCodeWeight = .regular) -> Font {
        .custom(weight.fontName, size: size)
    }

    // MARK: - Predefined Sizes

    static func firaCodeLargeTitle(_ weight: FiraCodeWeight = .regular) -> Font {
        firaCode(size: 34, weight: weight)
    }

    static func firaCodeTitle(_ weight: FiraCodeWeight = .regular) -> Font {
        firaCode(size: 28, weight: weight)
    }

    static func firaCodeTitle2(_ weight: FiraCodeWeight = .regular) -> Font {
        firaCode(size: 22, weight: weight)
    }

    static func firaCodeTitle3(_ weight: FiraCodeWeight = .regular) -> Font {
        firaCode(size: 20, weight: weight)
    }

    static func firaCodeHeadline() -> Font {
        firaCode(size: 17, weight: .semiBold)
    }

    static func firaCodeBody(_ weight: FiraCodeWeight = .regular) -> Font {
        firaCode(size: 17, weight: weight)
    }

    static func firaCodeCallout(_ weight: FiraCodeWeight = .regular) -> Font {
        firaCode(size: 16, weight: weight)
    }

    static func firaCodeSubheadline(_ weight: FiraCodeWeight = .regular) -> Font {
        firaCode(size: 15, weight: weight)
    }

    static func firaCodeFootnote(_ weight: FiraCodeWeight = .regular) -> Font {
        firaCode(size: 13, weight: weight)
    }

    static func firaCodeCaption(_ weight: FiraCodeWeight = .regular) -> Font {
        firaCode(size: 12, weight: weight)
    }

    static func firaCodeCaption2(_ weight: FiraCodeWeight = .regular) -> Font {
        firaCode(size: 11, weight: weight)
    }
}

// MARK: - Fira Code Weight Enum

enum FiraCodeWeight {
    case light
    case regular
    case retina
    case medium
    case semiBold
    case bold

    var fontName: String {
        switch self {
        case .light:
            "FiraCode-Light"
        case .regular:
            "FiraCode-Regular"
        case .retina:
            "FiraCode-Retina"
        case .medium:
            "FiraCode-Medium"
        case .semiBold:
            "FiraCode-SemiBold"
        case .bold:
            "FiraCode-Bold"
        }
    }
}
