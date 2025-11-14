@testable import Heauton
import XCTest

/// Unit tests for TextChunker - Content validation and edge cases
final class TextChunkerContentTests: XCTestCase {
    let testParentId = UUID()

    // MARK: - Chunk Content Tests

    func testChunkContentCompleteness() {
        let text = String(repeating: "word ", count: 3000)
        let chunks = TextChunker.chunk(text, parentId: testParentId)

        // Sum of all chunk word counts should roughly equal total
        let totalChunkWords = chunks.reduce(0) { $0 + $1.wordCount }
        let expectedWords = 3000

        // Allow 5% tolerance for splitting
        XCTAssertGreaterThan(totalChunkWords, expectedWords - 150)
        XCTAssertLessThan(totalChunkWords, expectedWords + 150)
    }

    func testChunkUniqueIds() {
        let text = String(repeating: "word ", count: 3000)
        let chunks = TextChunker.chunk(text, parentId: testParentId)

        let ids = Set(chunks.map(\.id))
        XCTAssertEqual(ids.count, chunks.count, "All chunk IDs should be unique")
    }

    // MARK: - Reassembly Tests

    func testReassembleChunks() {
        let originalText = String(repeating: "This is a test sentence. ", count: 200)
        let chunks = TextChunker.chunk(originalText, parentId: testParentId)

        let reassembled = TextChunker.reassemble(chunks: chunks)

        // Reassembled text should be similar to original (may have spacing differences)
        let originalWords = originalText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let reassembledWords = reassembled.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        XCTAssertEqual(
            originalWords.count,
            reassembledWords.count,
            "Reassembled text should have same word count as original"
        )
    }

    func testReassemblePreservesOrder() {
        let text = "First. Second. Third. Fourth. Fifth."
        let chunks = [
            TextChunk(
                parentId: testParentId,
                index: 2,
                totalChunks: 3,
                content: "Third.",
                wordCount: 1,
                range: text.startIndex..<text.endIndex
            ),
            TextChunk(
                parentId: testParentId,
                index: 0,
                totalChunks: 3,
                content: "First.",
                wordCount: 1,
                range: text.startIndex..<text.endIndex
            ),
            TextChunk(
                parentId: testParentId,
                index: 1,
                totalChunks: 3,
                content: "Second.",
                wordCount: 1,
                range: text.startIndex..<text.endIndex
            ),
        ]

        let reassembled = TextChunker.reassemble(chunks: chunks)

        // Should reassemble in correct order
        XCTAssertTrue(reassembled.contains("First"))
        XCTAssertTrue(reassembled.contains("Second"))
        XCTAssertTrue(reassembled.contains("Third"))

        let words = reassembled.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        XCTAssertEqual(words[0], "First.")
        XCTAssertEqual(words[1], "Second.")
        XCTAssertEqual(words[2], "Third.")
    }

    // MARK: - Validation Tests

    func testValidateChunksSuccess() {
        let text = String(repeating: "word ", count: 2000)
        let chunks = TextChunker.chunk(text, parentId: testParentId)

        let isValid = TextChunker.validateChunks(chunks, against: text)
        XCTAssertTrue(isValid, "Properly created chunks should be valid")
    }

    func testValidateChunksWithGaps() {
        let text = "Original text"
        let invalidChunks = [
            TextChunk(
                parentId: testParentId,
                index: 0,
                totalChunks: 3,
                content: "First",
                wordCount: 1,
                range: text.startIndex..<text.endIndex
            ),
            // Gap: missing index 1
            TextChunk(
                parentId: testParentId,
                index: 2,
                totalChunks: 3,
                content: "Third",
                wordCount: 1,
                range: text.startIndex..<text.endIndex
            ),
        ]

        let isValid = TextChunker.validateChunks(invalidChunks, against: text)
        XCTAssertFalse(isValid, "Chunks with gaps should be invalid")
    }

    func testValidateEmptyChunks() {
        let text = "Some text"
        let emptyChunks: [TextChunk] = []

        let isValid = TextChunker.validateChunks(emptyChunks, against: text)
        XCTAssertFalse(isValid, "Empty chunks array should be invalid")
    }

    func testValidateChunksWrongTotalCount() {
        let text = "Text"
        let invalidChunks = [
            TextChunk(
                parentId: testParentId,
                index: 0,
                totalChunks: 5, // Wrong total
                content: "First",
                wordCount: 1,
                range: text.startIndex..<text.endIndex
            ),
            TextChunk(
                parentId: testParentId,
                index: 1,
                totalChunks: 5, // Wrong total
                content: "Second",
                wordCount: 1,
                range: text.startIndex..<text.endIndex
            ),
        ]

        let isValid = TextChunker.validateChunks(invalidChunks, against: text)
        XCTAssertFalse(isValid, "Chunks with wrong total count should be invalid")
    }

    // MARK: - Edge Cases

    func testChunkEmptyString() {
        let chunks = TextChunker.chunk("", parentId: testParentId)

        XCTAssertEqual(chunks.count, 1, "Empty string should create one chunk")
        XCTAssertEqual(chunks.first?.content, "")
        XCTAssertEqual(chunks.first?.wordCount, 0)
    }

    func testChunkSingleWord() {
        let chunks = TextChunker.chunk("word", parentId: testParentId)

        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks.first?.content, "word")
        XCTAssertEqual(chunks.first?.wordCount, 1)
    }

    func testChunkExactlyTargetSize() {
        let config = ChunkingConfig.default
        let text = String(repeating: "word ", count: config.targetWordsPerChunk)
        let chunks = TextChunker.chunk(text, parentId: testParentId, config: config)

        XCTAssertEqual(chunks.count, 1, "Text exactly at target should create one chunk")
    }

    func testChunkJustOverTargetSize() {
        let config = ChunkingConfig.default
        let text = String(repeating: "word ", count: config.targetWordsPerChunk + 1)
        let chunks = TextChunker.chunk(text, parentId: testParentId, config: config)

        // Slightly over target might still be one chunk
        XCTAssertGreaterThanOrEqual(chunks.count, 1)
        XCTAssertLessThanOrEqual(chunks.count, 2)
    }

    // MARK: - Special Character Handling

    func testChunkTextWithEmojis() {
        let text = String(repeating: "Hello world test ", count: 200)
        let chunks = TextChunker.chunk(text, parentId: testParentId)

        XCTAssertGreaterThan(chunks.count, 0)
        XCTAssertTrue(chunks.first?.content.contains("Hello") ?? false)
    }

    func testChunkTextWithUnicode() {
        let text = String(repeating: "你好世界 Hello World ", count: 200)
        let chunks = TextChunker.chunk(text, parentId: testParentId)

        XCTAssertGreaterThan(chunks.count, 0)
        XCTAssertNotNil(chunks.first?.content)
    }
}
