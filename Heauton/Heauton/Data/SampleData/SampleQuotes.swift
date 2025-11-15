import Foundation
import SwiftData

enum SampleQuotes {
    static let quotes: [Quote] = [
        Quote(
            author: "Socrates",
            text: "The unexamined life is not worth living.",
            source: "Apology"
        ),
        Quote(
            author: "René Descartes",
            text: "Cogito, ergo sum. (I think, therefore I am.)",
            source: "Discourse on the Method"
        ),
        Quote(
            author: "Friedrich Nietzsche",
            text: "He who has a why to live can bear almost any how.",
            source: "Twilight of the Idols"
        ),
        Quote(
            author: "Aristotle",
            text: "We are what we repeatedly do. Excellence, then, is not an act, but a habit."
        ),
        Quote(
            author: "Marcus Aurelius",
            text: "You have power over your mind - not outside events. Realize this, and you will find strength.",
            source: "Meditations"
        ),
        Quote(
            author: "Plato",
            text: "The measure of a man is what he does with power.",
            source: "Republic"
        ),
        Quote(
            author: "Confucius",
            text: "It does not matter how slowly you go as long as you do not stop."
        ),
        Quote(
            author: "Lao Tzu",
            text: "A journey of a thousand miles begins with a single step.",
            source: "Tao Te Ching"
        ),
        Quote(
            author: "Epictetus",
            text: "It's not what happens to you, but how you react to it that matters.",
            source: "Enchiridion"
        ),
        Quote(
            author: "Immanuel Kant",
            text:
            "Act only according to that maxim whereby you can, at the same time, " +
                "will that it should become a universal law.",
            source: "Groundwork of the Metaphysics of Morals"
        ),
        Quote(
            author: "Jean-Paul Sartre",
            text:
            "Man is condemned to be free; because once thrown into the world, " +
                "he is responsible for everything he does.",
            source: "Existentialism is a Humanism"
        ),
        Quote(
            author: "Simone de Beauvoir",
            text: "One is not born, but rather becomes, a woman.",
            source: "The Second Sex"
        ),
    ]

    static func seedIfNeeded(in modelContext: ModelContext) async {
        // Check if there are any quotes already
        let descriptor = FetchDescriptor<Quote>()
        if let count = try? modelContext.fetchCount(descriptor), count > 0 {
            // Already have quotes, don't seed
            return
        }

        // Seed with sample quotes
        for quote in quotes {
            modelContext.insert(quote)
        }

        try? modelContext.save()
    }
}
