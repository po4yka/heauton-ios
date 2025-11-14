@testable import Heauton
import XCTest

/// Performance tests for search and indexing layer - Indexing and chunking
/// Tests at 10× expected data volume to ensure scalability
final class SearchPerformanceIndexingTests: XCTestCase {
    // MARK: - Properties

    /// Expected normal data volume (adjust based on app requirements)
    private let normalQuoteCount = 1000

    /// Test data volume (10× normal)
    private var testQuoteCount: Int {
        normalQuoteCount * 10
    }

    /// Test quotes
    private var testQuotes: [Quote] = []

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()

        // Generate test quotes
        testQuotes = generateTestQuotes(count: testQuoteCount)
    }

    override func tearDown() async throws {
        testQuotes.removeAll()
        try await super.tearDown()
    }

    // MARK: - Test Data Generation

    /// Generates test quotes with varying lengths
    /// - Parameter count: Number of quotes to generate
    /// - Returns: Array of test quotes
    private func generateTestQuotes(count: Int) -> [Quote] {
        var quotes: [Quote] = []

        let authors = [
            "Marcus Aurelius", "Seneca", "Epictetus", "Plato", "Aristotle",
            "Socrates", "Confucius", "Lao Tzu", "Buddha", "Nietzsche",
            "Kant", "Hegel", "Descartes", "Spinoza", "Leibniz",
        ]

        let sources = [
            "Meditations", "Letters from a Stoic", "Discourses", "The Republic",
            "Nicomachean Ethics", "The Analects", "Tao Te Ching", nil,
        ]

        let textTemplates = [
            // Short quotes (< 100 words)
            "The happiness of your life depends upon the quality of your thoughts.",
            "He who has a why to live can bear almost any how.",
            "The only true wisdom is in knowing you know nothing.",

            // Medium quotes (100-500 words)
            """
            It is not enough to win a war; it is more important to organize the peace.
            The purpose of our lives is to add value to the people of this generation and those that follow.
            We must learn to live together as brothers or perish together as fools.
            The ultimate measure of a man is not where he stands in moments of comfort and convenience,
            but where he stands at times of challenge and controversy.
            """,

            // Long quotes (> 1000 words) - will test chunking
            """
            The art of living is more like wrestling than dancing, in so far as it stands ready
            against the accidental and the unforeseen, and is not apt to fall.
            When you arise in the morning, think of what a precious privilege it is to be alive,
            to breathe, to think, to enjoy, to love. The happiness of your life depends upon the
            quality of your thoughts: therefore, guard accordingly, and take care that you entertain
            no notions unsuitable to virtue and reasonable nature. You have power over your mind,
            not outside events. Realize this, and you will find strength. Very little is needed
            to make a happy life; it is all within yourself, in your way of thinking. If you are
            distressed by anything external, the pain is not due to the thing itself, but to your
            estimate of it; and this you have the power to revoke at any moment.
            """,
        ]

        for index in 0..<count {
            let author = authors[index % authors.count]
            let source = sources[index % sources.count]
            let textTemplate = textTemplates[index % textTemplates.count]

            // Add variety by appending index to text
            let text = "\(textTemplate) [Quote #\(index)]"

            let quote = Quote(
                author: author,
                text: text,
                source: source,
                isFavorite: index % 10 == 0 // 10% favorites
            )

            quotes.append(quote)
        }

        return quotes
    }

    // MARK: - Indexing Performance Tests

    /// Tests background indexing performance
    func testBackgroundIndexingPerformance() async throws {
        // Allow up to 120 seconds for this test to complete on CI
        executionTimeAllowance = 120

        let backgroundService = BackgroundIndexingService.shared

        let start = Date()

        await backgroundService.queueIndexing(
            quotes: testQuotes,
            type: .initial
        )

        try await backgroundService.waitForCompletion()

        let duration = Date().timeIntervalSince(start)

        // Should complete within reasonable time (10 seconds per 1000 quotes)
        let maxDuration = Double(testQuoteCount) / 1000.0 * 10.0
        XCTAssertLessThan(
            duration,
            maxDuration,
            "Background indexing took \(duration)s, expected < \(maxDuration)s"
        )
    }

    /// Tests chunking performance for long documents
    func testChunkingPerformance() throws {
        // Generate a very long text (10,000 words)
        let longText = String(repeating: "word ", count: 10000)

        measure {
            let chunks = TextChunker.chunk(
                longText,
                parentId: UUID(),
                config: .default
            )

            XCTAssertGreaterThan(chunks.count, 1, "Long text should be chunked")
        }
    }
}
