import Foundation

/// Database schema for search indexing
/// Uses GRDB with FTS5 for full-text search with BM25 ranking
enum SearchDatabaseSchema {
    // MARK: - Schema Version

    /// Current schema version for migrations
    static let currentVersion = 1

    // MARK: - Table Definitions

    /// Quote metadata table
    static let quotesTable = """
    CREATE TABLE IF NOT EXISTS quotes (
        id TEXT PRIMARY KEY NOT NULL,
        author TEXT NOT NULL,
        source TEXT,
        created_at REAL NOT NULL,
        updated_at REAL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        text_file_path TEXT,
        word_count INTEGER NOT NULL DEFAULT 0,
        is_chunked INTEGER NOT NULL DEFAULT 0
    )
    """

    /// Index for author searches
    static let authorIndex = """
    CREATE INDEX IF NOT EXISTS idx_quotes_author
    ON quotes(author)
    """

    /// Index for favorite quotes
    static let favoriteIndex = """
    CREATE INDEX IF NOT EXISTS idx_quotes_favorite
    ON quotes(is_favorite)
    WHERE is_favorite = 1
    """

    /// Index for date-based queries
    static let dateIndex = """
    CREATE INDEX IF NOT EXISTS idx_quotes_created_at
    ON quotes(created_at DESC)
    """

    // MARK: - FTS5 Tables

    /// FTS5 virtual table for full-text search on quote content
    /// Uses BM25 ranking algorithm
    static let quotesSearchTable = """
    CREATE VIRTUAL TABLE IF NOT EXISTS quotes_fts USING fts5(
        quote_id UNINDEXED,
        author,
        text,
        source,
        tokenize = 'unicode61 remove_diacritics 2'
    )
    """

    /// Trigger to keep FTS5 table in sync with quotes table (insert)
    static let quotesInsertTrigger = """
    CREATE TRIGGER IF NOT EXISTS quotes_fts_insert
    AFTER INSERT ON quotes
    BEGIN
        INSERT INTO quotes_fts(quote_id, author, text, source)
        VALUES (
            NEW.id,
            NEW.author,
            (SELECT content FROM quote_texts WHERE quote_id = NEW.id),
            IFNULL(NEW.source, '')
        );
    END
    """

    /// Trigger to keep FTS5 table in sync with quotes table (update)
    static let quotesUpdateTrigger = """
    CREATE TRIGGER IF NOT EXISTS quotes_fts_update
    AFTER UPDATE ON quotes
    BEGIN
        UPDATE quotes_fts
        SET author = NEW.author,
            text = (SELECT content FROM quote_texts WHERE quote_id = NEW.id),
            source = IFNULL(NEW.source, '')
        WHERE quote_id = NEW.id;
    END
    """

    /// Trigger to keep FTS5 table in sync with quotes table (delete)
    static let quotesDeleteTrigger = """
    CREATE TRIGGER IF NOT EXISTS quotes_fts_delete
    AFTER DELETE ON quotes
    BEGIN
        DELETE FROM quotes_fts WHERE quote_id = OLD.id;
    END
    """

    // MARK: - Text Content Tables

    /// Quote text content table (for non-chunked quotes)
    static let quoteTextsTable = """
    CREATE TABLE IF NOT EXISTS quote_texts (
        quote_id TEXT PRIMARY KEY NOT NULL,
        content TEXT NOT NULL,
        normalized_content TEXT NOT NULL,
        FOREIGN KEY (quote_id) REFERENCES quotes(id) ON DELETE CASCADE
    )
    """

    /// Chunks table for long quotes
    static let chunksTable = """
    CREATE TABLE IF NOT EXISTS quote_chunks (
        id TEXT PRIMARY KEY NOT NULL,
        quote_id TEXT NOT NULL,
        chunk_index INTEGER NOT NULL,
        total_chunks INTEGER NOT NULL,
        content TEXT NOT NULL,
        normalized_content TEXT NOT NULL,
        word_count INTEGER NOT NULL,
        file_path TEXT,
        created_at REAL NOT NULL,
        FOREIGN KEY (quote_id) REFERENCES quotes(id) ON DELETE CASCADE
    )
    """

    /// Index for chunk lookups
    static let chunksQuoteIndex = """
    CREATE INDEX IF NOT EXISTS idx_chunks_quote
    ON quote_chunks(quote_id, chunk_index)
    """

    /// FTS5 virtual table for chunk search
    static let chunksSearchTable = """
    CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(
        chunk_id UNINDEXED,
        quote_id UNINDEXED,
        chunk_index UNINDEXED,
        content,
        tokenize = 'unicode61 remove_diacritics 2'
    )
    """

    /// Trigger to keep chunks FTS5 table in sync (insert)
    static let chunksInsertTrigger = """
    CREATE TRIGGER IF NOT EXISTS chunks_fts_insert
    AFTER INSERT ON quote_chunks
    BEGIN
        INSERT INTO chunks_fts(chunk_id, quote_id, chunk_index, content)
        VALUES (NEW.id, NEW.quote_id, NEW.chunk_index, NEW.normalized_content);
    END
    """

    /// Trigger to keep chunks FTS5 table in sync (update)
    static let chunksUpdateTrigger = """
    CREATE TRIGGER IF NOT EXISTS chunks_fts_update
    AFTER UPDATE ON quote_chunks
    BEGIN
        UPDATE chunks_fts
        SET content = NEW.normalized_content
        WHERE chunk_id = NEW.id;
    END
    """

    /// Trigger to keep chunks FTS5 table in sync (delete)
    static let chunksDeleteTrigger = """
    CREATE TRIGGER IF NOT EXISTS chunks_fts_delete
    AFTER DELETE ON quote_chunks
    BEGIN
        DELETE FROM chunks_fts WHERE chunk_id = OLD.id;
    END
    """

    // MARK: - Search History & Analytics

    /// Search history table
    static let searchHistoryTable = """
    CREATE TABLE IF NOT EXISTS search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        results_count INTEGER NOT NULL,
        searched_at REAL NOT NULL
    )
    """

    /// Index for recent searches
    static let searchHistoryIndex = """
    CREATE INDEX IF NOT EXISTS idx_search_history_date
    ON search_history(searched_at DESC)
    """

    // MARK: - Schema Creation

    /// All SQL statements needed to create the schema
    static var allStatements: [String] {
        [
            // Core tables
            quotesTable,
            quoteTextsTable,
            chunksTable,

            // Indices
            authorIndex,
            favoriteIndex,
            dateIndex,
            chunksQuoteIndex,

            // FTS5 tables
            quotesSearchTable,
            chunksSearchTable,

            // Triggers for quotes
            quotesInsertTrigger,
            quotesUpdateTrigger,
            quotesDeleteTrigger,

            // Triggers for chunks
            chunksInsertTrigger,
            chunksUpdateTrigger,
            chunksDeleteTrigger,

            // Search history
            searchHistoryTable,
            searchHistoryIndex,
        ]
    }

    // MARK: - Migration Helpers

    /// Checks if a table exists
    static func tableExistsQuery(tableName: String) -> String {
        """
        SELECT name FROM sqlite_master
        WHERE type='table' AND name='\(tableName)'
        """
    }

    /// Drops all tables (for testing/reset)
    static var dropAllTables: [String] {
        [
            "DROP TABLE IF EXISTS search_history",
            "DROP TRIGGER IF EXISTS chunks_fts_delete",
            "DROP TRIGGER IF EXISTS chunks_fts_update",
            "DROP TRIGGER IF EXISTS chunks_fts_insert",
            "DROP TRIGGER IF EXISTS quotes_fts_delete",
            "DROP TRIGGER IF EXISTS quotes_fts_update",
            "DROP TRIGGER IF EXISTS quotes_fts_insert",
            "DROP TABLE IF EXISTS chunks_fts",
            "DROP TABLE IF EXISTS quotes_fts",
            "DROP TABLE IF EXISTS quote_chunks",
            "DROP TABLE IF EXISTS quote_texts",
            "DROP TABLE IF EXISTS quotes",
        ]
    }
}

// MARK: - Record Types

/// Database record for quote metadata
struct QuoteRecord: Codable, Sendable {
    let id: String
    let author: String
    let source: String?
    let createdAt: Double
    let updatedAt: Double?
    let isFavorite: Bool
    let textFilePath: String?
    let wordCount: Int
    let isChunked: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case author
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isFavorite = "is_favorite"
        case textFilePath = "text_file_path"
        case wordCount = "word_count"
        case isChunked = "is_chunked"
    }
}

/// Database record for quote text content
struct QuoteTextRecord: Codable, Sendable {
    let quoteId: String
    let content: String
    let normalizedContent: String

    enum CodingKeys: String, CodingKey {
        case quoteId = "quote_id"
        case content
        case normalizedContent = "normalized_content"
    }
}

/// Database record for quote chunk
struct ChunkRecord: Codable, Sendable {
    let id: String
    let quoteId: String
    let chunkIndex: Int
    let totalChunks: Int
    let content: String
    let normalizedContent: String
    let wordCount: Int
    let filePath: String?
    let createdAt: Double

    enum CodingKeys: String, CodingKey {
        case id
        case quoteId = "quote_id"
        case chunkIndex = "chunk_index"
        case totalChunks = "total_chunks"
        case content
        case normalizedContent = "normalized_content"
        case wordCount = "word_count"
        case filePath = "file_path"
        case createdAt = "created_at"
    }
}

/// Search result with relevance score
struct SearchResult: Sendable {
    let quoteId: UUID
    let author: String
    let snippet: String
    let relevanceScore: Double
    let matchType: MatchType

    enum MatchType: String, Codable, Sendable {
        case exactMatch
        case authorMatch
        case contentMatch
        case sourceMatch
    }
}
