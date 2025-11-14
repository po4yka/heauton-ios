import Foundation

/// Centralized constants for the application
/// Use these constants instead of hardcoded strings throughout the app
enum AppConstants {
    // MARK: - App Group & Identifiers

    /// App Group identifier for sharing data between app and widget
    static let appGroupIdentifier = "group.com.heauton.quotes"

    /// Bundle identifier for the main app
    static let bundleIdentifier = "com.heauton.app"

    /// Background task identifier for quote refresh
    static let backgroundTaskIdentifier = "com.heauton.quotes.refresh"

    // MARK: - Notification Categories

    /// Notification category for daily quotes
    static let quoteNotificationCategory = "QUOTE_CATEGORY"

    /// Notification identifier for daily quotes
    static let dailyQuoteNotificationIdentifier = "daily-quote"

    // MARK: - Keychain Keys

    /// Keychain key for encryption master key
    static let encryptionKeychainKey = "com.heauton.encryption.key"

    // MARK: - UserDefaults Keys

    enum UserDefaultsKeys {
        static let widgetRefreshInterval = "widgetRefreshInterval"
        static let lastQuoteDeliveryDate = "lastQuoteDeliveryDate"
        static let appLockEnabled = "appLockEnabled"
        static let lockTimeout = "lockTimeout"
    }

    // MARK: - Logging

    enum Logging {
        /// App subsystem for OSLog
        static let subsystem = "com.heauton.app"

        /// Log categories
        enum Category {
            static let app = "App"
            static let database = "Database"
            static let encryption = "Encryption"
            static let notifications = "Notifications"
            static let search = "Search"
            static let appLock = "AppLock"
            static let scheduleSettings = "ScheduleSettings"
            static let sampleData = "SampleData"
            static let modelContainer = "ModelContainer"
            static let userDefaults = "UserDefaults"
            static let searchDatabase = "SearchDatabase"
            static let deepLinking = "DeepLinking"
        }
    }

    // MARK: - Validation Limits

    enum Validation {
        // Journal Entry
        static let maxJournalTitleLength = 200
        static let maxJournalContentLength = 100_000 // ~50 pages
        static let maxTagLength = 50
        static let maxTagsPerEntry = 20

        // Search
        static let minSearchQueryLength = 2
        static let maxSearchQueryLength = 500

        // Quote
        static let maxQuoteAuthorLength = 100
        static let maxQuoteSourceLength = 200
        static let longQuoteThreshold = 1000 // words

        // Notification
        static let notificationBodyMaxLength = 200
    }

    // MARK: - Time Intervals

    enum TimeIntervals {
        /// App lock timeout (5 minutes)
        static let appLockTimeout: TimeInterval = 5 * 60

        /// Encryption key cache duration (5 minutes)
        static let encryptionKeyCacheDuration: TimeInterval = 300

        /// Search debounce delay (milliseconds)
        static let searchDebounceDelay: UInt64 = 300

        /// Background refresh interval (24 hours)
        static let backgroundRefreshInterval: TimeInterval = 24 * 60 * 60

        /// Widget refresh interval (30 minutes)
        static let widgetRefreshInterval: TimeInterval = 30 * 60
    }

    // MARK: - Cache Limits

    enum CacheLimits {
        /// Maximum search cache size
        static let maxSearchCacheSize = 50

        /// Search cache expiration (5 minutes)
        static let searchCacheExpiration: TimeInterval = 300
    }

    // MARK: - Retry Configuration

    enum Retry {
        /// Maximum background task retry attempts
        static let maxBackgroundTaskRetries = 3

        /// Delay between retry attempts (seconds)
        static let retryDelay: TimeInterval = 5

        /// Exponential backoff multiplier
        static let backoffMultiplier: Double = 2.0

        /// Maximum failure count before alerting
        static let maxConsecutiveFailures = 5
    }

    // MARK: - Database

    enum Database {
        /// Database filename for search
        static let searchDatabaseFilename = "quotes_search.db"

        /// Database schema version
        static let schemaVersion = 1
    }

    // MARK: - File Paths

    enum FilePaths {
        /// Directory name for quote text files
        static let quoteTextDirectory = "QuoteTexts"

        /// Directory name for chunks
        static let chunksDirectory = "Chunks"

        /// Directory name for database
        static let databaseDirectory = "Database"
    }
}
