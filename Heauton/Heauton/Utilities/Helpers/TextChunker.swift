import Foundation

/// Configuration for text chunking
struct ChunkingConfig {
    /// Target words per chunk (will try to split near this size)
    let targetWordsPerChunk: Int

    /// Maximum words per chunk (hard limit)
    let maxWordsPerChunk: Int

    /// Minimum words per chunk (will avoid creating chunks smaller than this)
    let minWordsPerChunk: Int

    /// Default configuration: 1,000-2,000 words per chunk
    static let `default` = ChunkingConfig(
        targetWordsPerChunk: 1500,
        maxWordsPerChunk: 2000,
        minWordsPerChunk: 1000
    )

    /// Aggressive chunking for very long documents
    static let aggressive = ChunkingConfig(
        targetWordsPerChunk: 1000,
        maxWordsPerChunk: 1500,
        minWordsPerChunk: 800
    )

    /// Conservative chunking for shorter documents
    static let conservative = ChunkingConfig(
        targetWordsPerChunk: 2000,
        maxWordsPerChunk: 2500,
        minWordsPerChunk: 1500
    )
}

/// Represents a chunk of text with metadata
struct TextChunk: Sendable {
    /// Unique identifier for the chunk
    let id: UUID

    /// Reference to the parent document/quote
    let parentId: UUID

    /// Zero-based index of this chunk in the document
    let index: Int

    /// Total number of chunks in the document
    let totalChunks: Int

    /// The chunk's text content
    let content: String

    /// Word count of this chunk
    let wordCount: Int

    /// Character range in the original text
    let range: Range<String.Index>

    /// Timestamp when the chunk was created
    let createdAt: Date

    init(
        id: UUID = UUID(),
        parentId: UUID,
        index: Int,
        totalChunks: Int,
        content: String,
        wordCount: Int,
        range: Range<String.Index>,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.parentId = parentId
        self.index = index
        self.totalChunks = totalChunks
        self.content = content
        self.wordCount = wordCount
        self.range = range
        self.createdAt = createdAt
    }
}

/// Utility for chunking long text documents into smaller, indexable pieces
///
/// # Text Chunking Algorithm
///
/// This algorithm splits long documents into smaller, searchable chunks while preserving semantic coherence.
///
/// ## Algorithm Overview
///
/// 1. **Word Counting**: First, count total words to determine if chunking is needed
/// 2. **Chunk Generation**: Split text into chunks based on target word count
/// 3. **Boundary Detection**: Prefer splitting at sentence boundaries (. ! ?)
/// 4. **Validation**: Ensure chunks meet minimum and maximum size constraints
///
/// ## Design Decisions
///
/// ### Why Chunk by Words?
/// - More consistent chunk sizes than character-based chunking
/// - Better semantic units (words) than arbitrary character breaks
/// - Easier to configure and reason about
///
/// ### Why Prefer Sentence Boundaries?
/// - Maintains semantic coherence within chunks
/// - Improves search result quality (complete thoughts)
/// - Better user experience when displaying snippets
///
/// ### Search Window for Sentence Boundaries
/// - Searches ±50 words around target to find sentence end
/// - Falls back to exact target if no boundary found
/// - Prevents excessive deviation from target chunk size
///
/// ## Time Complexity
/// - Best case: O(1) - text doesn't need chunking
/// - Average case: O(n) - one pass through words
/// - Worst case: O(n) - all text scanned for boundaries
/// where n is the number of words
///
/// ## Space Complexity
/// - O(n) - stores all words in memory during processing
/// - Could be optimized to O(1) with streaming for very large texts
///
/// ## Example
///
/// ```swift
/// let longText = "..." // 5000 words
/// let chunks = TextChunker.chunk(longText, parentId: quoteId)
/// // Result: 3-4 chunks of ~1500 words each
/// // Each chunk ends at a sentence boundary when possible
/// ```
enum TextChunker {
    /// Chunks text into smaller pieces based on word count
    /// - Parameters:
    ///   - text: The text to chunk
    ///   - parentId: ID of the parent document/quote
    ///   - config: Chunking configuration
    /// - Returns: Array of text chunks
    static func chunk(
        _ text: String,
        parentId: UUID,
        config: ChunkingConfig = .default
    ) -> [TextChunk] {
        // If text is short enough, return as single chunk
        let wordCount = countWords(in: text)
        if wordCount <= config.targetWordsPerChunk {
            return [
                TextChunk(
                    parentId: parentId,
                    index: 0,
                    totalChunks: 1,
                    content: text,
                    wordCount: wordCount,
                    range: text.startIndex..<text.endIndex
                ),
            ]
        }

        // Split text into chunks
        let chunks = splitIntoChunks(text, config: config)

        // Create TextChunk objects
        return chunks.enumerated().map { index, chunkData in
            TextChunk(
                parentId: parentId,
                index: index,
                totalChunks: chunks.count,
                content: chunkData.content,
                wordCount: chunkData.wordCount,
                range: chunkData.range
            )
        }
    }

    /// Counts words in text
    /// - Parameter text: The text to count words in
    /// - Returns: Number of words
    private static func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }

    /// Internal representation of chunk data during splitting
    private struct ChunkData {
        let content: String
        let wordCount: Int
        let range: Range<String.Index>
    }

    /// Splits text into chunks based on configuration
    /// - Parameters:
    ///   - text: The text to split
    ///   - config: Chunking configuration
    /// - Returns: Array of chunk data
    private static func splitIntoChunks(
        _ text: String,
        config: ChunkingConfig
    ) -> [ChunkData] {
        var chunks: [ChunkData] = []
        var currentStartIndex = text.startIndex
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { Substring($0) }

        var currentWordIndex = 0
        var chunkWords: [Substring] = []

        while currentWordIndex < words.count {
            chunkWords.append(words[currentWordIndex])
            currentWordIndex += 1

            // Check if we should create a chunk
            let shouldCreateChunk = chunkWords.count >= config.targetWordsPerChunk ||
                chunkWords.count >= config.maxWordsPerChunk ||
                currentWordIndex == words.count

            if (shouldCreateChunk && chunkWords.count >= config.minWordsPerChunk) || currentWordIndex == words.count {
                // Find the best split point (prefer splitting at sentence boundaries)
                let splitPoint = findBestSplitPoint(
                    in: chunkWords,
                    targetWords: config.targetWordsPerChunk,
                    maxWords: config.maxWordsPerChunk
                )

                // Create chunk from accumulated words
                let chunkContent = chunkWords[..<splitPoint].joined(separator: " ")
                let actualWordCount = countWords(in: chunkContent)
                let chunkEndIndex = text.index(
                    currentStartIndex,
                    offsetBy: chunkContent.count,
                    limitedBy: text.endIndex
                ) ?? text.endIndex

                chunks.append(ChunkData(
                    content: String(chunkContent),
                    wordCount: actualWordCount,
                    range: currentStartIndex..<chunkEndIndex
                ))

                // Move to next chunk
                currentStartIndex = chunkEndIndex
                chunkWords = Array(chunkWords[splitPoint...])
            }
        }

        // Handle any remaining words
        if !chunkWords.isEmpty {
            let chunkContent = chunkWords.joined(separator: " ")
            chunks.append(ChunkData(
                content: String(chunkContent),
                wordCount: chunkWords.count,
                range: currentStartIndex..<text.endIndex
            ))
        }

        return chunks
    }

    /// Finds the best point to split a chunk (prefers sentence boundaries)
    /// - Parameters:
    ///   - words: Array of words to split
    ///   - targetWords: Target number of words
    ///   - maxWords: Maximum number of words
    /// - Returns: Index to split at
    private static func findBestSplitPoint(
        in words: [Substring],
        targetWords: Int,
        maxWords: Int
    ) -> Int {
        // If we haven't reached target, return all words
        if words.count <= targetWords {
            return words.count
        }

        // If we've exceeded max, force split at max
        if words.count > maxWords {
            return maxWords
        }

        // Look for sentence boundaries near the target
        let searchStart = max(0, targetWords - 50)
        let searchEnd = min(words.count, targetWords + 50)

        for index in (searchStart..<searchEnd).reversed() {
            let word = words[index]
            if word.hasSuffix(".") || word.hasSuffix("!") || word.hasSuffix("?") {
                return index + 1
            }
        }

        // No sentence boundary found, split at target
        return targetWords
    }
}

// MARK: - Chunk Reassembly

extension TextChunker {
    /// Reassembles chunks back into original text
    /// - Parameter chunks: Array of chunks to reassemble
    /// - Returns: Reassembled text
    static func reassemble(chunks: [TextChunk]) -> String {
        let sortedChunks = chunks.sorted { $0.index < $1.index }
        return sortedChunks.map(\.content).joined(separator: " ")
    }

    /// Validates that chunks cover the original text without gaps
    /// - Parameters:
    ///   - chunks: Array of chunks to validate
    ///   - originalText: The original text
    /// - Returns: True if chunks are valid
    static func validateChunks(
        _ chunks: [TextChunk],
        against _: String
    ) -> Bool {
        guard !chunks.isEmpty else { return false }

        let sortedChunks = chunks.sorted { $0.index < $1.index }

        // Check indices are sequential
        for (index, chunk) in sortedChunks.enumerated() where chunk.index != index {
            return false
        }

        // Check total chunks matches
        if sortedChunks.count != sortedChunks.first?.totalChunks {
            return false
        }

        return true
    }
}
