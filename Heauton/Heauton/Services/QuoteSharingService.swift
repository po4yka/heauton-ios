import Foundation
import SwiftUI
import UIKit

/// Service for sharing quotes with various formatting styles
actor QuoteSharingService: QuoteSharingServiceProtocol {
    func formatQuoteText(_ quote: Quote, style: ShareStyle) -> String {
        switch style {
        case .minimal:
            formatMinimal(quote)
        case .card:
            formatCard(quote)
        case .attributed:
            formatAttributed(quote)
        }
    }

    func createShareItems(_ quote: Quote, includeImage: Bool) async -> [Any] {
        var items: [Any] = []

        // Add text
        let text = formatQuoteText(quote, style: .attributed)
        items.append(text)

        // Add image if requested
        if includeImage {
            if let image = await createQuoteImage(quote, style: .card) {
                items.append(image)
            }
        }

        return items
    }

    // MARK: - Private Helper Methods

    private func formatMinimal(_ quote: Quote) -> String {
        var text = "\"\(quote.text)\"\n\n"
        text += "— \(quote.author)"

        if let source = quote.source {
            text += ", \(source)"
        }

        return text
    }

    private func formatCard(_ quote: Quote) -> String {
        var text = "Daily Quote\n\n"
        text += "\"\(quote.text)\"\n\n"
        text += "— \(quote.author)"

        if let source = quote.source {
            text += ", \(source)"
        }

        text += "\n\nShared from Heauton"

        return text
    }

    private func formatAttributed(_ quote: Quote) -> String {
        var text = "\"\(quote.text)\"\n\n"
        text += "— \(quote.author)"

        if let source = quote.source {
            text += "\nSource: \(source)"
        }

        if let mood = quote.mood {
            text += "\n\nMood: \(mood)"
        }

        if let categories = quote.categories, !categories.isEmpty {
            text += "\nCategories: \(categories.joined(separator: ", "))"
        }

        return text
    }

    @MainActor
    private func createQuoteImage(_ quote: Quote, style: ShareStyle) async -> UIImage? {
        let cardView = QuoteCardView(quote: quote, style: style)
        let renderer = ImageRenderer(content: cardView)

        renderer.scale = UIScreen.main.scale

        return renderer.uiImage
    }
}
