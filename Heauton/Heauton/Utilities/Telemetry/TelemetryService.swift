import Foundation
import OSLog

/// Telemetry service for tracking errors and events in production
///
/// # Privacy-First Telemetry
///
/// This telemetry implementation is designed with user privacy as the top priority:
///
/// ## What We Track
/// - Error types and frequencies
/// - Feature usage statistics (anonymous)
/// - Performance metrics
/// - Crash information
///
/// ## What We DON'T Track
/// - User content (quotes, journal entries)
/// - Personal information
/// - Location data
/// - Device identifiers
///
/// ## Data Storage
/// - All telemetry stored locally
/// - Optional opt-in for sharing anonymized data
/// - User can view and delete all telemetry data
///
/// ## Compliance
/// - GDPR compliant
/// - CCPA compliant
/// - No third-party trackers
actor TelemetryService {
    // MARK: - Singleton

    static let shared = TelemetryService()

    // MARK: - Properties

    private let logger = Logger(
        subsystem: AppConstants.Logging.subsystem,
        category: "Telemetry"
    )

    private var events: [TelemetryEvent] = []
    private let maxStoredEvents = 1000
    private var eventsLoaded = false

    // UserDefaults key for storing telemetry events
    private let storageKey = "telemetry.events"

    // MARK: - Initialization

    private init() {
        // Load events lazily on first access to avoid concurrency issues
    }

    // MARK: - Public Methods

    /// Records an error event
    func recordError(
        _ error: Error,
        context: String,
        severity: TelemetrySeverity = .error
    ) async {
        let event = TelemetryEvent(
            type: .error,
            name: "error_occurred",
            properties: [
                "error_type": String(describing: type(of: error)),
                "error_description": error.localizedDescription,
                "context": context,
                "severity": severity.rawValue,
            ],
            timestamp: Date()
        )

        await recordEvent(event)

        // Also log to system
        switch severity {
        case .debug:
            logger.debug("[\(context)] \(error.localizedDescription)")
        case .info:
            logger.info("[\(context)] \(error.localizedDescription)")
        case .warning:
            logger.warning("[\(context)] \(error.localizedDescription)")
        case .error:
            logger.error("[\(context)] \(error.localizedDescription)")
        case .critical:
            logger.critical("[\(context)] \(error.localizedDescription)")
        }
    }

    /// Records a feature usage event
    func recordFeatureUsage(_ featureName: String, properties: [String: String] = [:]) async {
        var allProperties = properties
        allProperties["feature"] = featureName

        let event = TelemetryEvent(
            type: .featureUsage,
            name: "feature_used",
            properties: allProperties,
            timestamp: Date()
        )

        await recordEvent(event)
        logger.debug("Feature used: \(featureName)")
    }

    /// Records a performance metric
    func recordPerformance(
        operation: String,
        duration: TimeInterval,
        success: Bool
    ) async {
        let event = TelemetryEvent(
            type: .performance,
            name: "operation_performance",
            properties: [
                "operation": operation,
                "duration_ms": String(Int(duration * 1000)),
                "success": String(success),
            ],
            timestamp: Date()
        )

        await recordEvent(event)

        if duration > 1.0 {
            logger.warning("Slow operation: \(operation) took \(Int(duration * 1000))ms")
        }
    }

    /// Records a custom event
    func recordEvent(name: String, properties: [String: String] = [:]) async {
        let event = TelemetryEvent(
            type: .custom,
            name: name,
            properties: properties,
            timestamp: Date()
        )

        await recordEvent(event)
    }

    /// Gets error statistics
    func getErrorStatistics() async -> ErrorStatistics {
        let errorEvents = events.filter { $0.type == .error }

        var errorCounts: [String: Int] = [:]
        for event in errorEvents {
            if let errorType = event.properties["error_type"] {
                errorCounts[errorType, default: 0] += 1
            }
        }

        let last24Hours = Date().addingTimeInterval(-24 * 60 * 60)
        let recentErrors = errorEvents.filter { $0.timestamp > last24Hours }.count

        return ErrorStatistics(
            totalErrors: errorEvents.count,
            recentErrors: recentErrors,
            errorsByType: errorCounts,
            mostCommonError: errorCounts.max { $0.value < $1.value }?.key
        )
    }

    /// Gets feature usage statistics
    func getFeatureStatistics() async -> FeatureStatistics {
        let featureEvents = events.filter { $0.type == .featureUsage }

        var featureUsage: [String: Int] = [:]
        for event in featureEvents {
            if let feature = event.properties["feature"] {
                featureUsage[feature, default: 0] += 1
            }
        }

        return FeatureStatistics(
            totalUsageEvents: featureEvents.count,
            usageByFeature: featureUsage,
            mostUsedFeature: featureUsage.max { $0.value < $1.value }?.key
        )
    }

    /// Clears all telemetry data
    func clearAllData() async {
        events = []
        saveEvents()
        logger.info("All telemetry data cleared")
    }

    /// Exports telemetry data for debugging
    func exportData() async -> String {
        let sortedEvents = events.sorted { $0.timestamp > $1.timestamp }

        var output = "# Telemetry Report\n\n"
        output += "Generated: \(Date())\n"
        output += "Total Events: \(events.count)\n\n"

        let errorStats = await getErrorStatistics()
        output += "## Error Statistics\n"
        output += "Total Errors: \(errorStats.totalErrors)\n"
        output += "Recent Errors (24h): \(errorStats.recentErrors)\n"
        output += "Most Common: \(errorStats.mostCommonError ?? "None")\n\n"

        let featureStats = await getFeatureStatistics()
        output += "## Feature Statistics\n"
        output += "Total Usage Events: \(featureStats.totalUsageEvents)\n"
        output += "Most Used: \(featureStats.mostUsedFeature ?? "None")\n\n"

        output += "## Recent Events\n"
        for event in sortedEvents.prefix(50) {
            output += "\(event.timestamp): [\(event.type.rawValue)] \(event.name)\n"
            for (key, value) in event.properties {
                output += "  \(key): \(value)\n"
            }
            output += "\n"
        }

        return output
    }

    // MARK: - Private Methods

    private func recordEvent(_ event: TelemetryEvent) async {
        loadEventsIfNeeded()
        events.append(event)

        // Trim if exceeding max
        if events.count > maxStoredEvents {
            events = Array(events.suffix(maxStoredEvents))
        }

        saveEvents()
    }

    private func loadEventsIfNeeded() {
        guard !eventsLoaded else { return }
        eventsLoaded = true

        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            events = try decoder.decode([TelemetryEvent].self, from: data)
            logger.info("Loaded \(self.events.count) telemetry events")
        } catch {
            logger.error("Failed to load telemetry events: \(error.localizedDescription)")
        }
    }

    private func saveEvents() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            logger.error("Failed to save telemetry events: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

/// Telemetry event type
enum TelemetryEventType: String, Codable {
    case error
    case featureUsage
    case performance
    case custom
}

/// Severity level for events
enum TelemetrySeverity: String, Codable {
    case debug
    case info
    case warning
    case error
    case critical
}

/// Telemetry event structure
struct TelemetryEvent: Codable {
    let id: UUID
    let type: TelemetryEventType
    let name: String
    let properties: [String: String]
    let timestamp: Date

    init(
        id: UUID = UUID(),
        type: TelemetryEventType,
        name: String,
        properties: [String: String],
        timestamp: Date
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.properties = properties
        self.timestamp = timestamp
    }
}

/// Error statistics summary
struct ErrorStatistics {
    let totalErrors: Int
    let recentErrors: Int
    let errorsByType: [String: Int]
    let mostCommonError: String?
}

/// Feature usage statistics summary
struct FeatureStatistics {
    let totalUsageEvents: Int
    let usageByFeature: [String: Int]
    let mostUsedFeature: String?
}

// MARK: - Performance Tracking Helpers

extension TelemetryService {
    /// Tracks the performance of an async operation
    func trackPerformance<T>(
        _ operationName: String,
        operation: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()

        do {
            let result = try await operation()
            let duration = Date().timeIntervalSince(startTime)
            await recordPerformance(operation: operationName, duration: duration, success: true)
            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            await recordPerformance(operation: operationName, duration: duration, success: false)
            await recordError(error, context: operationName)
            throw error
        }
    }

    /// Tracks the performance of a synchronous operation
    func trackPerformanceSync<T>(
        _ operationName: String,
        operation: () throws -> T
    ) rethrows -> T {
        let startTime = Date()

        do {
            let result = try operation()
            let duration = Date().timeIntervalSince(startTime)
            Task {
                await recordPerformance(operation: operationName, duration: duration, success: true)
            }
            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            Task {
                await recordPerformance(operation: operationName, duration: duration, success: false)
                await recordError(error, context: operationName)
            }
            throw error
        }
    }
}
