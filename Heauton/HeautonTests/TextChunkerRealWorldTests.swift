@testable import Heauton
import XCTest

/// Unit tests for TextChunker - Real-world examples and performance
final class TextChunkerRealWorldTests: XCTestCase {
    let testParentId = UUID()

    // MARK: - Real-World Examples

    func testChunkPhilosophicalText() {
        let meditation = """
        When you arise in the morning, think of what a precious privilege it is to be alive,
        to breathe, to think, to enjoy, to love. The happiness of your life depends upon the
        quality of your thoughts: therefore, guard accordingly, and take care that you entertain
        no notions unsuitable to virtue and reasonable nature. You have power over your mind,
        not outside events. Realize this, and you will find strength. Very little is needed
        to make a happy life; it is all within yourself, in your way of thinking.
        """

        let chunks = TextChunker.chunk(meditation, parentId: testParentId)

        XCTAssertEqual(chunks.count, 1, "Short philosophical text should be single chunk")
        XCTAssertEqual(chunks.first?.content, meditation)
    }

    func testChunkVeryLongPhilosophicalText() {
        // Simulate a long meditation (like Marcus Aurelius' Meditations)
        let longMeditation = String(repeating: """
        The art of living is more like wrestling than dancing, in so far as it stands ready
        against the accidental and the unforeseen, and is not apt to fall. Begin each day by
        telling yourself: Today I shall be meeting with interference, ingratitude, insolence,
        disloyalty, ill-will, and selfishness.
        """, count: 50)

        let chunks = TextChunker.chunk(longMeditation, parentId: testParentId)

        XCTAssertGreaterThan(chunks.count, 1, "Very long text should be chunked")

        // Verify all chunks reference same parent
        for chunk in chunks {
            XCTAssertEqual(chunk.parentId, testParentId)
        }

        // Verify indices are sequential
        for (index, chunk) in chunks.enumerated() {
            XCTAssertEqual(chunk.index, index)
        }
    }

    // MARK: - Performance Tests

    func testChunkingPerformance() {
        let text = String(repeating: "This is a test sentence. ", count: 5000)

        measure {
            _ = TextChunker.chunk(text, parentId: testParentId)
        }
    }

    func testReassemblyPerformance() {
        let text = String(repeating: "This is a test sentence. ", count: 5000)
        let chunks = TextChunker.chunk(text, parentId: testParentId)

        measure {
            _ = TextChunker.reassemble(chunks: chunks)
        }
    }
}
