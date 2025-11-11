import Foundation

/// Errors that can occur during file storage operations
enum FileStorageError: Error, LocalizedError {
    case appGroupNotFound
    case fileNotFound(UUID)
    case unableToCreateDirectory
    case unableToWriteFile
    case unableToReadFile
    case invalidData

    var errorDescription: String? {
        switch self {
        case .appGroupNotFound:
            "App Group container not found"
        case .fileNotFound(let id):
            "File not found for ID: \(id)"
        case .unableToCreateDirectory:
            "Unable to create storage directory"
        case .unableToWriteFile:
            "Unable to write file to storage"
        case .unableToReadFile:
            "Unable to read file from storage"
        case .invalidData:
            "Invalid or corrupted file data"
        }
    }
}

/// Manages file storage for long quote texts in the App Group container
actor QuoteFileStorage: QuoteFileStorageProtocol {
    // MARK: - Properties

    /// App Group identifier
    private let appGroupIdentifier = "group.com.heauton.quotes"

    /// Subdirectory for quote text files
    private let quotesSubdirectory = "QuoteTexts"

    /// Subdirectory for chunk files
    private let chunksSubdirectory = "QuoteChunks"

    /// Shared instance
    /// Note: Prefer using AppDependencyContainer for dependency injection
    static let shared = QuoteFileStorage()

    /// File manager
    private let fileManager = FileManager.default

    /// Custom base URL for testing (if nil, uses App Group)
    private let customBaseURL: URL?

    // MARK: - Initialization

    init() {
        customBaseURL = nil
        Task {
            try? await createDirectoriesIfNeeded()
        }
    }

    /// Test-friendly initializer that uses a custom directory
    /// - Parameter baseURL: Custom base directory URL (typically a temporary directory)
    init(baseURL: URL) {
        customBaseURL = baseURL
        Task {
            try? await createDirectoriesIfNeeded()
        }
    }

    // MARK: - Directory Management

    /// Returns the base URL for the App Group container or custom test directory
    private func appGroupURL() throws -> URL {
        // Use custom URL if provided (for testing)
        if let customURL = customBaseURL {
            return customURL
        }

        // Otherwise use App Group container
        guard let url = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw FileStorageError.appGroupNotFound
        }
        return url
    }

    /// Returns the URL for the quotes storage directory
    private func quotesDirectoryURL() throws -> URL {
        let baseURL = try appGroupURL()
        return baseURL.appendingPathComponent(quotesSubdirectory, isDirectory: true)
    }

    /// Returns the URL for the chunks storage directory
    private func chunksDirectoryURL() throws -> URL {
        let baseURL = try appGroupURL()
        return baseURL.appendingPathComponent(chunksSubdirectory, isDirectory: true)
    }

    /// Creates storage directories if they don't exist
    private func createDirectoriesIfNeeded() throws {
        let quotesDir = try quotesDirectoryURL()
        let chunksDir = try chunksDirectoryURL()

        for directory in [quotesDir, chunksDir] where !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    // MARK: - File Path Generation

    /// Returns the file URL for a quote
    /// - Parameter quoteId: UUID of the quote
    /// - Returns: File URL for the quote text
    private func fileURL(for quoteId: UUID) throws -> URL {
        let directory = try quotesDirectoryURL()
        return directory.appendingPathComponent("\(quoteId.uuidString).txt")
    }

    /// Returns the file URL for a chunk
    /// - Parameters:
    ///   - chunkId: UUID of the chunk
    ///   - quoteId: UUID of the parent quote
    /// - Returns: File URL for the chunk text
    private func chunkFileURL(for chunkId: UUID, quoteId: UUID) throws -> URL {
        let directory = try chunksDirectoryURL()
        let quoteDirectory = directory.appendingPathComponent(quoteId.uuidString, isDirectory: true)

        // Create quote-specific directory if needed
        if !fileManager.fileExists(atPath: quoteDirectory.path) {
            try fileManager.createDirectory(
                at: quoteDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        return quoteDirectory.appendingPathComponent("\(chunkId.uuidString).txt")
    }

    // MARK: - Quote Text Storage

    /// Saves quote text to a file
    /// - Parameters:
    ///   - text: The text to save
    ///   - quoteId: UUID of the quote
    /// - Returns: Relative path to the saved file
    func saveQuoteText(_ text: String, for quoteId: UUID) async throws -> String {
        let fileURL = try fileURL(for: quoteId)

        guard let data = text.data(using: .utf8) else {
            throw FileStorageError.invalidData
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw FileStorageError.unableToWriteFile
        }

        // Return relative path
        let quotesDir = try quotesDirectoryURL()
        return fileURL.lastPathComponent
    }

    /// Loads quote text from a file
    /// - Parameter quoteId: UUID of the quote
    /// - Returns: The quote text
    func loadQuoteText(for quoteId: UUID) async throws -> String {
        let fileURL = try fileURL(for: quoteId)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileStorageError.fileNotFound(quoteId)
        }

        do {
            let data = try Data(contentsOf: fileURL)
            guard let text = String(data: data, encoding: .utf8) else {
                throw FileStorageError.invalidData
            }
            return text
        } catch {
            throw FileStorageError.unableToReadFile
        }
    }

    /// Deletes quote text file
    /// - Parameter quoteId: UUID of the quote
    func deleteQuoteText(for quoteId: UUID) async throws {
        let fileURL = try fileURL(for: quoteId)

        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    /// Checks if a quote text file exists
    /// - Parameter quoteId: UUID of the quote
    /// - Returns: True if the file exists
    func quoteTextExists(for quoteId: UUID) async throws -> Bool {
        let fileURL = try fileURL(for: quoteId)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    // MARK: - Chunk Storage

    /// Saves a chunk to a file
    /// - Parameters:
    ///   - chunk: The text chunk to save
    ///   - quoteId: UUID of the parent quote
    /// - Returns: Relative path to the saved chunk file
    func saveChunk(_ chunk: TextChunk, quoteId: UUID) async throws -> String {
        let fileURL = try chunkFileURL(for: chunk.id, quoteId: quoteId)

        guard let data = chunk.content.data(using: .utf8) else {
            throw FileStorageError.invalidData
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw FileStorageError.unableToWriteFile
        }

        // Return relative path
        return "\(quoteId.uuidString)/\(chunk.id.uuidString).txt"
    }

    /// Loads a chunk from a file
    /// - Parameters:
    ///   - chunkId: UUID of the chunk
    ///   - quoteId: UUID of the parent quote
    /// - Returns: The chunk text
    func loadChunk(chunkId: UUID, quoteId: UUID) async throws -> String {
        let fileURL = try chunkFileURL(for: chunkId, quoteId: quoteId)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileStorageError.fileNotFound(chunkId)
        }

        do {
            let data = try Data(contentsOf: fileURL)
            guard let text = String(data: data, encoding: .utf8) else {
                throw FileStorageError.invalidData
            }
            return text
        } catch {
            throw FileStorageError.unableToReadFile
        }
    }

    /// Deletes all chunks for a quote
    /// - Parameter quoteId: UUID of the quote
    func deleteChunks(for quoteId: UUID) async throws {
        let chunksDir = try chunksDirectoryURL()
        let quoteDirectory = chunksDir.appendingPathComponent(quoteId.uuidString)

        if fileManager.fileExists(atPath: quoteDirectory.path) {
            try fileManager.removeItem(at: quoteDirectory)
        }
    }

    /// Saves multiple chunks for a quote
    /// - Parameters:
    ///   - chunks: Array of chunks to save
    ///   - quoteId: UUID of the parent quote
    /// - Returns: Array of relative paths to saved chunk files
    func saveChunks(_ chunks: [TextChunk], for quoteId: UUID) async throws -> [String] {
        var paths: [String] = []

        for chunk in chunks {
            let path = try await saveChunk(chunk, quoteId: quoteId)
            paths.append(path)
        }

        return paths
    }

    // MARK: - Cleanup

    /// Removes orphaned files (files without corresponding database entries)
    /// - Parameter validQuoteIds: Set of valid quote IDs from the database
    func cleanupOrphanedFiles(validQuoteIds: Set<UUID>) async throws {
        // Clean up quote text files
        let quotesDir = try quotesDirectoryURL()
        if let files = try? fileManager.contentsOfDirectory(at: quotesDir, includingPropertiesForKeys: nil) {
            for fileURL in files {
                let filename = fileURL.deletingPathExtension().lastPathComponent
                if let uuid = UUID(uuidString: filename), !validQuoteIds.contains(uuid) {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        }

        // Clean up chunk directories
        let chunksDir = try chunksDirectoryURL()
        if let directories = try? fileManager.contentsOfDirectory(
            at: chunksDir,
            includingPropertiesForKeys: nil
        ) {
            for directoryURL in directories {
                let dirname = directoryURL.lastPathComponent
                if let uuid = UUID(uuidString: dirname), !validQuoteIds.contains(uuid) {
                    try? fileManager.removeItem(at: directoryURL)
                }
            }
        }
    }

    /// Returns the total size of stored files in bytes
    func calculateStorageSize() async throws -> Int64 {
        var totalSize: Int64 = 0

        func addDirectorySize(_ url: URL) throws {
            if let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey]
            ) {
                for case let fileURL as URL in enumerator {
                    if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += Int64(size)
                    }
                }
            }
        }

        try addDirectorySize(quotesDirectoryURL())
        try addDirectorySize(chunksDirectoryURL())

        return totalSize
    }
}
