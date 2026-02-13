import Foundation
import OSLog
import SQLite3

/// SQLite transient destructor constant
nonisolated(unsafe) private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Errors that can occur during database operations
enum DatabaseError: Error, LocalizedError {
    case notInitialized
    case migrationFailed
    case queryFailed(String)
    case invalidQuery
    case appGroupNotFound
    case connectionFailed(Int32)
    case preparationFailed(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            "Database not initialized"
        case .migrationFailed:
            "Database migration failed"
        case .queryFailed(let message):
            "Database query failed: \(message)"
        case .invalidQuery:
            "Invalid query parameters"
        case .appGroupNotFound:
            "App Group container not found"
        case .connectionFailed(let code):
            "Failed to open database connection: SQLite error \(code)"
        case .preparationFailed(let message):
            "Failed to prepare statement: \(message)"
        case .executionFailed(let message):
            "Failed to execute statement: \(message)"
        }
    }
}

// This file contains a comprehensive SQLite database manager with many cohesive operations.
// Splitting it would reduce code maintainability and cohesion.
// swiftlint:disable file_length
// swiftlint:disable type_body_length

/// Manages the SQLite database for search indexing
/// Handles initialization, migrations, and query execution with FTS5
///
/// Note: Prefer using AppDependencyContainer for dependency injection rather than the shared instance
actor SearchDatabaseManager: SearchDatabaseManagerProtocol {
    // MARK: - Properties

    private let logger = Logger(
        subsystem: AppConstants.Logging.subsystem,
        category: AppConstants.Logging.Category.searchDatabase
    )

    /// Shared instance
    static let shared = SearchDatabaseManager()

    /// App Group identifier
    private let appGroupIdentifier = AppConstants.appGroupIdentifier

    /// Database filename
    private let databaseFilename = AppConstants.Database.searchDatabaseFilename

    /// SQLite database connection
    private var db: OpaquePointer?

    /// Initialization flag
    private var isInitialized = false

    // MARK: - Initialization

    init() {}

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    /// Initializes the database
    func initialize() async throws {
        guard !isInitialized else { return }

        let databaseURL = try getDatabaseURL()

        logger.debug("Initializing database at: \(databaseURL.path)")

        // Open database connection
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(databaseURL.path, &db, flags, nil)

        guard result == SQLITE_OK, db != nil else {
            logger.error("Failed to open database: \(result)")
            throw DatabaseError.connectionFailed(result)
        }

        // Enable foreign keys
        try execute("PRAGMA foreign_keys = ON")

        // Set WAL mode for better concurrency
        try execute("PRAGMA journal_mode = WAL")

        // Run migrations
        try await migrate()

        isInitialized = true
        logger.debug("Database initialized successfully")
    }

    /// Returns the URL for the database file
    private func getDatabaseURL() throws -> URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw DatabaseError.appGroupNotFound
        }

        let databaseDirectory = containerURL.appendingPathComponent("Database", isDirectory: true)

        // Create directory if needed
        if !FileManager.default.fileExists(atPath: databaseDirectory.path) {
            try FileManager.default.createDirectory(
                at: databaseDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        return databaseDirectory.appendingPathComponent(databaseFilename)
    }

    // MARK: - Migrations

    /// Runs database migrations
    private func migrate() async throws {
        guard db != nil else {
            throw DatabaseError.notInitialized
        }

        let currentVersion = try getDatabaseVersion()
        let targetVersion = SearchDatabaseSchema.currentVersion

        guard currentVersion < targetVersion else {
            logger.info("Database already at version \(currentVersion)")
            return
        }

        logger.info("Migrating database from version \(currentVersion) to \(targetVersion)")

        try execute("BEGIN TRANSACTION")

        do {
            // Create schema if needed
            if currentVersion == 0 {
                for statement in SearchDatabaseSchema.allStatements {
                    try execute(statement)
                }
            }

            // Set new version
            try setDatabaseVersion(targetVersion)

            try execute("COMMIT")
            logger.info("Migration completed successfully")
        } catch {
            try? execute("ROLLBACK")
            logger.error("Migration failed: \(error.localizedDescription)")
            throw DatabaseError.migrationFailed
        }
    }

    private func getDatabaseVersion() throws -> Int {
        var version = 0
        try query("PRAGMA user_version") { statement in
            if sqlite3_step(statement) == SQLITE_ROW {
                version = Int(sqlite3_column_int(statement, 0))
            }
        }
        return version
    }

    private func setDatabaseVersion(_ version: Int) throws {
        try execute("PRAGMA user_version = \(version)")
    }

    // MARK: - Database Operations

    /// Inserts a quote into the database using configuration object
    /// - Parameter data: Quote index data containing all necessary information
    func insertQuote(_ data: QuoteIndexData) async throws {
        try await insertQuoteWithParameters(
            id: data.id,
            author: data.author,
            text: data.text,
            source: data.source,
            isFavorite: data.isFavorite,
            textFilePath: data.textFilePath,
            wordCount: data.wordCount,
            isChunked: data.isChunked
        )
    }

    /// Inserts a quote into the database with individual parameters
    /// - Note: Prefer using `insertQuote(_:QuoteIndexData)` for better maintainability
    private func insertQuoteWithParameters( // swiftlint:disable:this function_parameter_count
        id: UUID,
        author: String,
        text: String,
        source: String?,
        isFavorite: Bool,
        textFilePath: String?,
        wordCount: Int,
        isChunked: Bool
    ) async throws {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }

        let normalizedText = TextNormalizer.prepareForIndexing(text)
        let now = Date.now.timeIntervalSince1970

        // Insert quote metadata
        let quoteSQL = """
        INSERT OR REPLACE INTO quotes
        (id, author, source, created_at, updated_at, is_favorite, text_file_path, word_count, is_chunked)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        try execute(quoteSQL, bindings: [
            .text(id.uuidString),
            .text(author),
            .text(source),
            .real(now),
            .real(now),
            .integer(isFavorite ? 1 : 0),
            .text(textFilePath),
            .integer(Int64(wordCount)),
            .integer(isChunked ? 1 : 0),
        ])

        // Insert quote text content
        let textSQL = """
        INSERT OR REPLACE INTO quote_texts (quote_id, content, normalized_content)
        VALUES (?, ?, ?)
        """

        try execute(textSQL, bindings: [
            .text(id.uuidString),
            .text(text),
            .text(normalizedText),
        ])

        // Insert into FTS5 table
        let ftsSQL = """
        INSERT OR REPLACE INTO quotes_fts (quote_id, author, text, source)
        VALUES (?, ?, ?, ?)
        """

        try execute(ftsSQL, bindings: [
            .text(id.uuidString),
            .text(author),
            .text(normalizedText),
            .text(source ?? ""),
        ])
    }

    /// Updates a quote in the database
    func updateQuote(
        id: UUID,
        author: String,
        text: String,
        source: String?,
        isFavorite: Bool
    ) async throws {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }

        let normalizedText = TextNormalizer.prepareForIndexing(text)
        let now = Date.now.timeIntervalSince1970

        // Update quote metadata
        let quoteSQL = """
        UPDATE quotes
        SET author = ?, source = ?, updated_at = ?, is_favorite = ?
        WHERE id = ?
        """

        try execute(quoteSQL, bindings: [
            .text(author),
            .text(source),
            .real(now),
            .integer(isFavorite ? 1 : 0),
            .text(id.uuidString),
        ])

        // Update quote text
        let textSQL = """
        UPDATE quote_texts
        SET content = ?, normalized_content = ?
        WHERE quote_id = ?
        """

        try execute(textSQL, bindings: [
            .text(text),
            .text(normalizedText),
            .text(id.uuidString),
        ])

        // Update FTS5 table
        let ftsSQL = """
        UPDATE quotes_fts
        SET author = ?, text = ?, source = ?
        WHERE quote_id = ?
        """

        try execute(ftsSQL, bindings: [
            .text(author),
            .text(normalizedText),
            .text(source ?? ""),
            .text(id.uuidString),
        ])
    }

    /// Deletes a quote from the database
    func deleteQuote(id: UUID) async throws {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }

        // Delete from quotes table (cascades to related tables via foreign keys)
        let sql = "DELETE FROM quotes WHERE id = ?"
        try execute(sql, bindings: [.text(id.uuidString)])

        // Delete from FTS5 table
        let ftsSQL = "DELETE FROM quotes_fts WHERE quote_id = ?"
        try execute(ftsSQL, bindings: [.text(id.uuidString)])
    }

    /// Inserts chunks for a quote
    func insertChunks(_ chunks: [TextChunk], for quoteId: UUID) async throws {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }

        let now = Date.now.timeIntervalSince1970

        for chunk in chunks {
            let normalizedContent = TextNormalizer.prepareForIndexing(chunk.content)

            // Insert chunk
            let chunkSQL = """
            INSERT OR REPLACE INTO quote_chunks
            (id, quote_id, chunk_index, total_chunks, content, normalized_content, word_count, file_path, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """

            try execute(chunkSQL, bindings: [
                .text(chunk.id.uuidString),
                .text(quoteId.uuidString),
                .integer(Int64(chunk.index)),
                .integer(Int64(chunk.totalChunks)),
                .text(chunk.content),
                .text(normalizedContent),
                .integer(Int64(chunk.wordCount)),
                .null,
                .real(now),
            ])

            // Insert into chunks FTS5 table
            let ftsSQL = """
            INSERT OR REPLACE INTO chunks_fts (chunk_id, quote_id, chunk_index, content)
            VALUES (?, ?, ?, ?)
            """

            try execute(ftsSQL, bindings: [
                .text(chunk.id.uuidString),
                .text(quoteId.uuidString),
                .integer(Int64(chunk.index)),
                .text(normalizedContent),
            ])
        }
    }

    // MARK: - Full-Text Search

    /// Performs full-text search using FTS5 with BM25 ranking
    func search(query searchQuery: String, limit: Int = 20) async throws -> [SearchResult] {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }

        guard !searchQuery.isEmpty else {
            return []
        }

        let normalizedQuery = TextNormalizer.normalize(searchQuery)
        let ftsQuery = prepareFTSQuery(normalizedQuery)

        // Search in quotes FTS5 table with BM25 ranking
        let sql = """
        SELECT
            q.id,
            q.author,
            snippet(quotes_fts, 2, '<mark>', '</mark>', '...', 32) as snippet,
            bm25(quotes_fts) as rank
        FROM quotes_fts
        JOIN quotes q ON quotes_fts.quote_id = q.id
        WHERE quotes_fts MATCH ?
        ORDER BY rank
        LIMIT ?
        """

        var results: [SearchResult] = []

        try query(sql, bindings: [.text(ftsQuery), .integer(Int64(limit))]) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let idString = sqlite3_column_text(statement, 0).map({ String(cString: $0) }),
                      let id = UUID(uuidString: idString),
                      let author = sqlite3_column_text(statement, 1).map({ String(cString: $0) }),
                      let snippet = sqlite3_column_text(statement, 2).map({ String(cString: $0) }) else {
                    continue
                }

                let rank = sqlite3_column_double(statement, 3)

                // BM25 returns negative scores (more negative = better match)
                // Convert to positive relevance score (0-100)
                let relevanceScore = max(0, min(100, -rank))

                results.append(SearchResult(
                    quoteId: id,
                    author: author,
                    snippet: cleanSnippet(snippet),
                    relevanceScore: relevanceScore,
                    matchType: .contentMatch
                ))
            }
        }

        // Also search in chunks if no results
        if results.isEmpty {
            results = try await searchInChunks(query: ftsQuery, limit: limit)
        }

        // Record search in history
        try await recordSearch(query: searchQuery, resultsCount: results.count)

        return results
    }

    /// Searches in chunks for long quotes
    private func searchInChunks(query: String, limit: Int) async throws -> [SearchResult] {
        let sql = """
        SELECT
            c.quote_id,
            q.author,
            snippet(chunks_fts, 3, '<mark>', '</mark>', '...', 32) as snippet,
            bm25(chunks_fts) as rank
        FROM chunks_fts
        JOIN quote_chunks c ON chunks_fts.chunk_id = c.id
        JOIN quotes q ON c.quote_id = q.id
        WHERE chunks_fts MATCH ?
        ORDER BY rank
        LIMIT ?
        """

        var results: [SearchResult] = []

        try self.query(sql, bindings: [.text(query), .integer(Int64(limit))]) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let idString = sqlite3_column_text(statement, 0).map({ String(cString: $0) }),
                      let id = UUID(uuidString: idString),
                      let author = sqlite3_column_text(statement, 1).map({ String(cString: $0) }),
                      let snippet = sqlite3_column_text(statement, 2).map({ String(cString: $0) }) else {
                    continue
                }

                let rank = sqlite3_column_double(statement, 3)
                let relevanceScore = max(0, min(100, -rank))

                results.append(SearchResult(
                    quoteId: id,
                    author: author,
                    snippet: cleanSnippet(snippet),
                    relevanceScore: relevanceScore,
                    matchType: .contentMatch
                ))
            }
        }

        return results
    }

    /// Searches by author
    func searchByAuthor(author: String, limit: Int = 20) async throws -> [SearchResult] {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }

        let sql = """
        SELECT
            q.id,
            q.author,
            qt.content
        FROM quotes q
        JOIN quote_texts qt ON q.id = qt.quote_id
        WHERE q.author LIKE ?
        ORDER BY q.created_at DESC
        LIMIT ?
        """

        var results: [SearchResult] = []
        let searchPattern = "%\(author)%"

        try query(sql, bindings: [.text(searchPattern), .integer(Int64(limit))]) { statement in
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let idString = sqlite3_column_text(statement, 0).map({ String(cString: $0) }),
                      let id = UUID(uuidString: idString),
                      let authorName = sqlite3_column_text(statement, 1).map({ String(cString: $0) }),
                      let content = sqlite3_column_text(statement, 2).map({ String(cString: $0) }) else {
                    continue
                }

                let snippet = String(content.prefix(200))

                results.append(SearchResult(
                    quoteId: id,
                    author: authorName,
                    snippet: snippet,
                    relevanceScore: 100,
                    matchType: .authorMatch
                ))
            }
        }

        return results
    }

    // MARK: - Configuration Object API

    /// Updates a quote using configuration object
    /// Follows configuration object pattern to reduce parameter count
    func updateQuote(_ data: QuoteIndexData) async throws {
        try await updateQuote(
            id: data.id,
            author: data.author,
            text: data.text,
            source: data.source,
            isFavorite: data.isFavorite
        )
    }

    /// Searches using configuration object for advanced scenarios
    func search(configuration: SearchConfiguration) async throws -> [SearchResult] {
        try await search(query: configuration.query, limit: configuration.limit)
    }

    // MARK: - Helper Methods

    /// Prepares FTS5 query from user input
    private func prepareFTSQuery(_ query: String) -> String {
        // Split into words and add wildcard
        let words = query.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        // Use AND logic for multiple words
        return words.map { "\($0)*" }.joined(separator: " ")
    }

    /// Cleans HTML-like markers from snippet
    private func cleanSnippet(_ snippet: String) -> String {
        snippet.replacingOccurrences(of: "<mark>", with: "")
            .replacingOccurrences(of: "</mark>", with: "")
    }

    /// Records search in history
    private func recordSearch(query: String, resultsCount: Int) async throws {
        let sql = """
        INSERT INTO search_history (query, results_count, searched_at)
        VALUES (?, ?, ?)
        """

        let now = Date.now.timeIntervalSince1970

        try execute(sql, bindings: [
            .text(query),
            .integer(Int64(resultsCount)),
            .real(now),
        ])
    }

    // MARK: - Optimization

    /// Optimizes the database
    func optimize() async throws {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }

        try execute("PRAGMA optimize")
        logger.debug("Database optimized")
    }

    /// Rebuilds FTS5 indices
    func rebuildIndices() async throws {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }

        try execute("INSERT INTO quotes_fts(quotes_fts) VALUES('rebuild')")
        try execute("INSERT INTO chunks_fts(chunks_fts) VALUES('rebuild')")

        logger.debug("FTS5 indices rebuilt")
    }

    // MARK: - Statistics

    /// Returns database statistics
    func getStatistics() async throws -> DatabaseStatistics {
        guard isInitialized else {
            throw DatabaseError.notInitialized
        }

        var totalQuotes = 0
        var totalChunks = 0
        var totalSearches = 0

        try query("SELECT COUNT(*) FROM quotes") { statement in
            if sqlite3_step(statement) == SQLITE_ROW {
                totalQuotes = Int(sqlite3_column_int(statement, 0))
            }
        }

        try query("SELECT COUNT(*) FROM quote_chunks") { statement in
            if sqlite3_step(statement) == SQLITE_ROW {
                totalChunks = Int(sqlite3_column_int(statement, 0))
            }
        }

        try query("SELECT COUNT(*) FROM search_history") { statement in
            if sqlite3_step(statement) == SQLITE_ROW {
                totalSearches = Int(sqlite3_column_int(statement, 0))
            }
        }

        return DatabaseStatistics(
            totalQuotes: totalQuotes,
            totalChunks: totalChunks,
            totalSearches: totalSearches
        )
    }

    // MARK: - Low-level SQLite Operations

    /// Executes a SQL statement without results
    private func execute(_ sql: String, bindings: [SQLiteValue] = []) throws {
        guard let db else {
            throw DatabaseError.notInitialized
        }

        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let error = String(cString: sqlite3_errmsg(db))
            logger.error("Failed to prepare statement: \(error)")
            throw DatabaseError.preparationFailed(error)
        }

        // Bind parameters
        for (index, value) in bindings.enumerated() {
            try bind(value: value, at: index + 1, to: statement)
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let error = String(cString: sqlite3_errmsg(db))
            logger.error("Failed to execute statement: \(error)")
            throw DatabaseError.executionFailed(error)
        }
    }

    /// Executes a query and processes results
    private func query(
        _ sql: String,
        bindings: [SQLiteValue] = [],
        handler: (OpaquePointer) throws -> Void
    ) throws {
        guard let db else {
            throw DatabaseError.notInitialized
        }

        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK,
              let stmt = statement else {
            let error = String(cString: sqlite3_errmsg(db))
            logger.error("Failed to prepare query: \(error)")
            throw DatabaseError.preparationFailed(error)
        }

        // Bind parameters
        for (index, value) in bindings.enumerated() {
            try bind(value: value, at: index + 1, to: stmt)
        }

        try handler(stmt)
    }

    /// Binds a value to a prepared statement
    private func bind(value: SQLiteValue, at index: Int, to statement: OpaquePointer?) throws {
        guard let statement else { return }

        let result: Int32 = switch value {
        case .text(let string):
            sqlite3_bind_text(statement, Int32(index), string, -1, sqliteTransient)
        case .integer(let int):
            sqlite3_bind_int64(statement, Int32(index), int)
        case .real(let double):
            sqlite3_bind_double(statement, Int32(index), double)
        case .null:
            sqlite3_bind_null(statement, Int32(index))
        }

        guard result == SQLITE_OK else {
            throw DatabaseError.executionFailed("Failed to bind parameter at index \(index)")
        }
    }
}

// MARK: - Supporting Types

/// Database statistics
struct DatabaseStatistics: Sendable {
    let totalQuotes: Int
    let totalChunks: Int
    let totalSearches: Int
}

/// SQLite value types for parameter binding
private enum SQLiteValue {
    case text(String?)
    case integer(Int64)
    case real(Double)
    case null
}
