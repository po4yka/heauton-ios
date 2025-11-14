@testable import Heauton
import XCTest

/// Unit tests for TextChunker - Basic functionality and configuration
final class TextChunkerBasicTests: XCTestCase {
    let testParentId = UUID()

    // MARK: - Basic Chunking Tests

    func testChunkShortText() {
        let text = "This is a short text with less than 1000 words."
        let chunks = TextChunker.chunk(text, parentId: testParentId)

        XCTAssertEqual(chunks.count, 1, "Short text should result in single chunk")
        XCTAssertEqual(chunks.first?.content, text)
        XCTAssertEqual(chunks.first?.index, 0)
        XCTAssertEqual(chunks.first?.totalChunks, 1)
        XCTAssertEqual(chunks.first?.parentId, testParentId)
    }

    func testChunkLongText() {
        // Create text with ~2500 words
        let text = String(repeating: "word ", count: 2500)
        let chunks = TextChunker.chunk(text, parentId: testParentId, config: .default)

        XCTAssertGreaterThan(chunks.count, 1, "Long text should be split into multiple chunks")
        XCTAssertLessThanOrEqual(chunks.count, 3, "2500 words should create 2-3 chunks with default config")
    }

    func testChunkMetadata() {
        let text = String(repeating: "word ", count: 2000)
        let chunks = TextChunker.chunk(text, parentId: testParentId)

        for (index, chunk) in chunks.enumerated() {
            XCTAssertEqual(chunk.index, index, "Chunk index should be sequential")
            XCTAssertEqual(chunk.totalChunks, chunks.count, "Total chunks should match array count")
            XCTAssertEqual(chunk.parentId, testParentId, "Parent ID should match")
            XCTAssertNotNil(chunk.id, "Each chunk should have unique ID")
        }
    }

    // MARK: - Chunking Configuration Tests

    func testDefaultConfiguration() {
        let config = ChunkingConfig.default

        XCTAssertEqual(config.targetWordsPerChunk, 1500)
        XCTAssertEqual(config.maxWordsPerChunk, 2000)
        XCTAssertEqual(config.minWordsPerChunk, 1000)
    }

    func testAggressiveConfiguration() {
        let config = ChunkingConfig.aggressive

        XCTAssertEqual(config.targetWordsPerChunk, 1000)
        XCTAssertEqual(config.maxWordsPerChunk, 1500)
        XCTAssertEqual(config.minWordsPerChunk, 800)
    }

    func testConservativeConfiguration() {
        let config = ChunkingConfig.conservative

        XCTAssertEqual(config.targetWordsPerChunk, 2000)
        XCTAssertEqual(config.maxWordsPerChunk, 2500)
        XCTAssertEqual(config.minWordsPerChunk, 1500)
    }

    func testCustomConfiguration() {
        let text = String(repeating: "word ", count: 3000)
        let config = ChunkingConfig(
            targetWordsPerChunk: 500,
            maxWordsPerChunk: 600,
            minWordsPerChunk: 400
        )

        let chunks = TextChunker.chunk(text, parentId: testParentId, config: config)

        // 3000 words with 500 word target should create ~6 chunks
        XCTAssertGreaterThanOrEqual(chunks.count, 4)
        XCTAssertLessThanOrEqual(chunks.count, 8)

        // Check chunk sizes
        for chunk in chunks {
            XCTAssertGreaterThanOrEqual(chunk.wordCount, config.minWordsPerChunk - 100) // Allow some tolerance
            XCTAssertLessThanOrEqual(chunk.wordCount, config.maxWordsPerChunk + 100)
        }
    }

    // MARK: - Word Count Tests

    func testWordCounting() {
        let text = "one two three four five"
        let chunks = TextChunker.chunk(text, parentId: testParentId)

        XCTAssertEqual(chunks.first?.wordCount, 5)
    }

    func testWordCountingWithPunctuation() {
        let text = "one, two. three! four? five;"
        let chunks = TextChunker.chunk(text, parentId: testParentId)

        // Should count words correctly even with punctuation
        XCTAssertEqual(chunks.first?.wordCount, 5)
    }

    func testWordCountingMultiline() {
        let text = """
        Line one has words.
        Line two has more words.
        Line three also has words.
        """
        let chunks = TextChunker.chunk(text, parentId: testParentId)

        XCTAssertEqual(chunks.first?.wordCount, 14)
    }

    // MARK: - Sentence Boundary Detection Tests

    func testSentenceBoundarySplitting() {
        // Create text with clear sentence boundaries
        let sentences = Array(repeating: "This is a sentence. ", count: 1500)
        let text = sentences.joined()

        let chunks = TextChunker.chunk(text, parentId: testParentId)

        // Should split at sentence boundaries
        for chunk in chunks {
            // Each chunk should ideally end with a period
            let trimmed = chunk.content.trimmingCharacters(in: .whitespaces)
            if chunk.index < chunks.count - 1 { // Not the last chunk
                // Should prefer ending with sentence-ending punctuation
                XCTAssertTrue(
                    trimmed.hasSuffix(".") ||
                        trimmed.hasSuffix("!") ||
                        trimmed.hasSuffix("?") ||
                        chunk.wordCount >= 1000,
                    "Chunk should end at sentence boundary when possible"
                )
            }
        }
    }

    // MARK: - Sendable Conformance Tests

    func testTextChunkIsSendable() {
        let chunk = TextChunk(
            parentId: testParentId,
            index: 0,
            totalChunks: 1,
            content: "Test",
            wordCount: 1,
            range: "Test".startIndex..<"Test".endIndex
        )

        // Should be able to use in async context
        Task {
            _ = chunk.content
            _ = chunk.wordCount
        }
    }

    func testChunkingConfigIsSendable() {
        let config = ChunkingConfig.default

        // Should be able to pass across actor boundaries
        Task {
            _ = config.targetWordsPerChunk
            _ = config.maxWordsPerChunk
        }
    }

    // MARK: - Timestamp Tests

    func testChunkCreationTimestamp() {
        let before = Date()
        let chunks = TextChunker.chunk("test", parentId: testParentId)
        let after = Date()

        if let chunk = chunks.first {
            XCTAssertGreaterThanOrEqual(chunk.createdAt, before)
            XCTAssertLessThanOrEqual(chunk.createdAt, after)
        }
    }
}
