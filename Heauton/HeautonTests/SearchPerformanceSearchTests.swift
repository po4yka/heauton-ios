@testable import Heauton
import XCTest

/// Performance tests for search and indexing layer - Search, storage, and processing
/// Tests at 10× expected data volume to ensure scalability
final class SearchPerformanceSearchTests: XCTestCase {
    // MARK: - Properties

    /// Expected normal data volume (adjust based on app requirements)
    private let normalQuoteCount = 1000

    /// Test quotes
    private var testQuotes: [Quote] = []

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()

        // Generate test quotes
        testQuotes = generateTestQuotes(count: normalQuoteCount * 10)
    }

    override func tearDown() async throws {
        testQuotes.removeAll()
        try await super.tearDown()
    }

    // MARK: - Test Data Generation

    /// Generates test quotes with varying lengths
    private func generateTestQuotes(count: Int) -> [Quote] {
        var quotes: [Quote] = []

        let authors = [
            "Marcus Aurelius", "Seneca", "Epictetus", "Plato", "Aristotle",
            "Socrates", "Confucius", "Lao Tzu", "Buddha", "Nietzsche",
        ]

        let textTemplates = [
            "The happiness of your life depends upon the quality of your thoughts.",
            "He who has a why to live can bear almost any how.",
            "The only true wisdom is in knowing you know nothing.",
        ]

        for index in 0..<count {
            let author = authors[index % authors.count]
            let textTemplate = textTemplates[index % textTemplates.count]
            let text = "\(textTemplate) [Quote #\(index)]"

            quotes.append(Quote(author: author, text: text))
        }

        return quotes
    }

    // MARK: - Text Processing Performance Tests

    /// Tests text normalization performance
    func testTextNormalizationPerformance() throws {
        let texts = testQuotes.map(\.text)

        measure {
            for text in texts {
                _ = TextNormalizer.normalize(text)
            }
        }
    }

    /// Tests token extraction performance
    func testTokenExtractionPerformance() throws {
        let texts = testQuotes.map(\.text)

        measure {
            for text in texts {
                _ = TextNormalizer.extractTokens(from: text)
            }
        }
    }
}
