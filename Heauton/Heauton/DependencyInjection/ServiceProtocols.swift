//  Protocol definitions for all services to enable dependency injection

import Foundation

// MARK: - Settings Manager Protocol

protocol SettingsManagerProtocol: AnyObject, Observable {
    var widgetRefreshInterval: Int { get set }
    var refreshIntervalInSeconds: TimeInterval { get }
    func intervalDescription(_ minutes: Int) -> String
}

// MARK: - Quote File Storage Protocol

protocol QuoteFileStorageProtocol: Actor {
    func saveQuoteText(_ text: String, for quoteId: UUID) async throws -> String
    func loadQuoteText(for quoteId: UUID) async throws -> String
    func deleteQuoteText(for quoteId: UUID) async throws
    func saveChunk(_ chunk: TextChunk, quoteId: UUID) async throws -> String
    func loadChunk(chunkId: UUID, quoteId: UUID) async throws -> String
    func deleteChunks(for quoteId: UUID) async throws
}

// MARK: - Search Database Manager Protocol

/// Configuration object for quote indexing data
/// Follows configuration object pattern to reduce parameter count
struct QuoteIndexData: Sendable {
    let id: UUID
    let author: String
    let text: String
    let source: String?
    let isFavorite: Bool
    let textFilePath: String?
    let wordCount: Int
    let isChunked: Bool

    /// Creates index data from a Quote model
    init(from quote: Quote) {
        id = quote.id
        author = quote.author
        text = quote.text
        source = quote.source
        isFavorite = quote.isFavorite
        textFilePath = quote.textFilePath
        wordCount = quote.wordCount
        isChunked = quote.isChunked
    }

    /// Custom initializer for testing or manual construction
    init(
        id: UUID,
        author: String,
        text: String,
        source: String? = nil,
        isFavorite: Bool = false,
        textFilePath: String? = nil,
        wordCount: Int = 0,
        isChunked: Bool = false
    ) {
        self.id = id
        self.author = author
        self.text = text
        self.source = source
        self.isFavorite = isFavorite
        self.textFilePath = textFilePath
        self.wordCount = wordCount
        self.isChunked = isChunked
    }
}

/// Configuration object for search operations
/// Follows configuration object pattern to encapsulate search parameters
struct SearchConfiguration: Sendable {
    let query: String
    let limit: Int
    let minRelevance: Double
    let scope: SearchScope

    enum SearchScope: Sendable {
        case all
        case authorsOnly
        case contentOnly
        case sourcesOnly
    }

    static func `default`(query: String) -> SearchConfiguration {
        SearchConfiguration(
            query: query,
            limit: 20,
            minRelevance: 0.0,
            scope: .all
        )
    }

    static func fast(query: String) -> SearchConfiguration {
        SearchConfiguration(
            query: query,
            limit: 10,
            minRelevance: 0.5,
            scope: .all
        )
    }
}

protocol SearchDatabaseManagerProtocol: Actor {
    func initialize() async throws

    /// Inserts a quote into the search index using configuration object
    func insertQuote(_ data: QuoteIndexData) async throws

    /// Updates a quote in the search index using configuration object
    func updateQuote(_ data: QuoteIndexData) async throws

    func deleteQuote(id: UUID) async throws

    /// Searches with basic parameters (maintains backward compatibility)
    func search(query: String, limit: Int) async throws -> [SearchResult]

    /// Searches with configuration object for advanced scenarios
    func search(configuration: SearchConfiguration) async throws -> [SearchResult]
}

// MARK: - Quote Search Service Protocol

protocol QuoteSearchServiceProtocol: Actor {
    func initialize() async throws
    func indexQuote(_ quote: Quote) async throws
    func updateIndex(for quote: Quote) async throws
    func removeFromIndex(quoteId: UUID) async throws
}

// MARK: - Spotlight Indexing Service Protocol

protocol SpotlightIndexingServiceProtocol: Actor {
    func indexQuote(_ quote: Quote) async throws
    func indexQuotes(_ quotes: [Quote]) async throws
    func updateQuote(_ quote: Quote) async throws
    func removeQuote(id quoteId: UUID) async throws
    func removeQuotes(ids quoteIds: [UUID]) async throws
}

// MARK: - Background Indexing Service Protocol

protocol BackgroundIndexingServiceProtocol: Actor {
    func start() async
    func stop() async
    func queueIndexing(quotes: [Quote], type: IndexingJob.JobType) async
}

// MARK: - Quote Scheduler Service Protocol

protocol QuoteSchedulerServiceProtocol: Actor {
    func scheduleNextQuote() async throws
    func selectQuoteForToday() async throws -> Quote?
    func updateScheduleSettings(_ schedule: QuoteSchedule) async throws
    func cancelScheduledNotifications() async throws
    func getUpcomingDeliveryTime() async -> Date?
}

// MARK: - Notification Manager Protocol

protocol NotificationManagerProtocol: Actor {
    func requestAuthorization() async throws -> Bool
    func scheduleQuoteNotification(quote: Quote, time: Date) async throws
    func cancelAllNotifications() async
    func getPendingNotifications() async -> [String]
    func handleNotificationResponse(quoteID: UUID) async
}

// MARK: - Quote Sharing Service Protocol

protocol QuoteSharingServiceProtocol: Actor {
    func formatQuoteText(_ quote: Quote, style: ShareStyle) -> String
    func createShareItems(_ quote: Quote, includeImage: Bool) async -> [Any]
}

enum ShareStyle: String, Codable {
    case minimal
    case card
    case attributed

    var displayName: String {
        switch self {
        case .minimal: "Plain Text"
        case .card: "Beautiful Card"
        case .attributed: "Rich Text"
        }
    }
}

// MARK: - Journal Service Protocol

protocol JournalServiceProtocol: Actor {
    func createEntry(
        title: String,
        content: String,
        mood: JournalMood?,
        tags: [String],
        linkedQuoteId: UUID?
    ) async throws -> DecryptedJournalEntry
    func updateEntry(
        _ entry: JournalEntry,
        title: String,
        content: String,
        mood: JournalMood?,
        tags: [String]
    ) async throws
    func deleteEntry(_ entry: JournalEntry) async throws
    func fetchEntries(
        sortBy: JournalSortOption,
        filterBy: JournalFilter?
    ) async throws -> [DecryptedJournalEntry]
    func fetchEntry(id: UUID) async throws -> DecryptedJournalEntry?
    func selectRandomPrompt(category: PromptCategory?) async throws -> JournalPrompt?
    func markPromptAsUsed(_ prompt: JournalPrompt) async throws
}

enum JournalSortOption: String, Codable, CaseIterable {
    case newest
    case oldest
    case updated
    case pinned

    var displayName: String {
        switch self {
        case .newest: "Newest First"
        case .oldest: "Oldest First"
        case .updated: "Recently Updated"
        case .pinned: "Pinned First"
        }
    }
}

struct JournalFilter: Codable {
    var mood: JournalMood?
    var tags: Set<String>
    var searchText: String?
    var dateRange: DateRange?
    var favoritesOnly: Bool

    static var `default`: JournalFilter {
        JournalFilter(
            mood: nil,
            tags: [],
            searchText: nil,
            dateRange: nil,
            favoritesOnly: false
        )
    }
}

// MARK: - App Lock Service Protocol

protocol AppLockServiceProtocol: Actor {
    func authenticate() async throws -> Bool
    func isAppUnlocked() async -> Bool
    func checkAndLockIfNeeded() async -> Bool
    func lockApp() async
    func updateLastActivity() async
    func biometricType() async -> BiometricType
    func isBiometricAvailable() async -> Bool
}

// MARK: - Encryption Service Protocol

protocol EncryptionServiceProtocol: Actor {
    func encrypt(_ data: Data) async throws -> Data
    func decrypt(_ encryptedData: Data) async throws -> Data
    func encryptString(_ string: String) async throws -> Data
    func decryptString(_ encryptedData: Data) async throws -> String
    func deleteKey() async throws
    func clearKeyCache() async
}

// MARK: - Exercise Service Protocol

protocol ExerciseServiceProtocol: Actor {
    func fetchExercises(
        type: ExerciseType?,
        difficulty: Difficulty?
    ) async throws -> [Exercise]
    func createSession(_ exercise: Exercise) async throws -> ExerciseSession
    func completeSession(
        _ session: ExerciseSession,
        actualDuration: Int,
        moodAfter: JournalMood?,
        notes: String?
    ) async throws
    func getRecommendedExercise(mood: JournalMood?) async throws -> Exercise?
    func getFavoritesExercises() async throws -> [Exercise]
    func getSessionHistory(limit: Int?) async throws -> [ExerciseSession]
}

// MARK: - Progress Tracker Service Protocols

/// Activity type for progress tracking
nonisolated enum ActivityType: String, Codable, Sendable {
    case quotes
    case journaling
    case meditation
    case breathing
    case any

    var displayName: String {
        switch self {
        case .quotes: "Quotes"
        case .journaling: "Journaling"
        case .meditation: "Meditation"
        case .breathing: "Breathing"
        case .any: "All Activities"
        }
    }
}

/// Progress statistics summary
nonisolated struct ProgressStats: Sendable {
    var totalQuotes: Int
    var totalJournalEntries: Int
    var totalMeditationMinutes: Int
    var totalBreathingSessions: Int
    var totalShares: Int
    var currentStreak: Int
    var longestStreak: Int
    var averageMood: JournalMood?
    var favoriteActivity: ActivityType?
}

// MARK: - Focused Protocol: Streak Tracking

/// Protocol for tracking activity streaks
/// Follows Interface Segregation Principle - focused on streak calculations only
protocol StreakTrackingProtocol: Actor {
    /// Gets the current active streak for the given activity type
    func getCurrentStreak(type: ActivityType) async throws -> Int

    /// Gets the longest historical streak for the given activity type
    func getLongestStreak(type: ActivityType) async throws -> Int
}

// MARK: - Focused Protocol: Stats Aggregation

/// Protocol for aggregating progress statistics
/// Follows Interface Segregation Principle - focused on stats calculation only
protocol StatsAggregationProtocol: Actor {
    /// Gets total accumulated statistics across all time
    func getTotalStats() async throws -> ProgressStats

    /// Gets statistics for a specific date range
    func getStatsForPeriod(start: Date, end: Date) async throws -> ProgressStats
}

// MARK: - Focused Protocol: Achievement Management

/// Protocol for managing user achievements
/// Follows Interface Segregation Principle - focused on achievements only
protocol AchievementManagementProtocol: Actor {
    /// Checks for newly unlocked achievements based on current progress
    func checkAndUnlockAchievements() async throws -> [Achievement]

    /// Retrieves all achievements (locked and unlocked)
    func getAchievements() async throws -> [Achievement]

    /// Updates progress for a specific achievement
    func updateAchievementProgress(
        _ achievement: Achievement,
        progress: Int
    ) async throws
}

// MARK: - Focused Protocol: Snapshot Management

/// Protocol for managing daily progress snapshots
/// Follows Interface Segregation Principle - focused on snapshots only
protocol SnapshotManagementProtocol: Actor {
    /// Creates or updates today's progress snapshot
    func createOrUpdateTodaySnapshot() async throws

    /// Retrieves recent snapshots for the specified number of days
    func getRecentSnapshots(days: Int) async throws -> [ProgressSnapshot]
}

// MARK: - Composed Protocol: Complete Progress Tracking

/// Complete progress tracking service composed of focused protocols
/// Clients can depend on individual protocols or the complete service
typealias ProgressTrackerServiceProtocol = AchievementManagementProtocol
    & SnapshotManagementProtocol
    & StatsAggregationProtocol
    & StreakTrackingProtocol

// MARK: - Data Export Service Protocol

/// Protocol for exporting user data to various formats
protocol DataExportServiceProtocol: Actor {
    /// Exports all user data to a complete backup file (JSON)
    func exportCompleteBackup() async throws -> URL

    /// Exports journal entries only (JSON)
    func exportJournals() async throws -> [ExportedJournalEntry]

    /// Exports quotes (JSON)
    func exportQuotes() async throws -> [ExportedQuote]

    /// Exports exercises (JSON)
    func exportExercises() async throws -> [ExportedExercise]

    /// Exports progress snapshots (JSON)
    func exportProgress() async throws -> [ExportedProgressSnapshot]

    /// Exports achievements (JSON)
    func exportAchievements() async throws -> [ExportedAchievement]

    /// Exports journals as CSV
    func exportJournalsAsCSV() async throws -> URL

    /// Exports quotes as CSV
    func exportQuotesAsCSV() async throws -> URL

    /// Gets storage information
    func getStorageInfo() async throws -> StorageInfo
}
