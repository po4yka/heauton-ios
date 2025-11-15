import Foundation
import Observation
import OSLog

/// Monitors the app's storage mode and provides real-time status updates
/// to the UI layer to warn users about in-memory storage fallback
@Observable
final class StorageMonitor {
    // MARK: - Properties

    /// Logger for storage-related events
    private let logger = Logger(
        subsystem: AppConstants.Logging.subsystem,
        category: "StorageMonitor"
    )

    /// Current storage mode - true if in-memory, false if persistent
    private(set) var isInMemoryMode: Bool = false

    /// Error that caused fallback to in-memory mode
    private(set) var storageError: SharedModelContainer.ModelContainerError?

    /// Timestamp when in-memory mode was activated
    private(set) var inMemoryModeStartTime: Date?

    /// Whether the user has been alerted about in-memory mode
    private(set) var userHasBeenAlerted: Bool = false

    // MARK: - Initialization

    init() {
        logger.info("StorageMonitor initialized")
    }

    // MARK: - Public Methods

    /// Updates the storage mode based on container initialization result
    /// - Parameters:
    ///   - isInMemory: Whether storage is in-memory only
    ///   - error: Optional error that caused the fallback
    func updateStorageMode(isInMemory: Bool, error: SharedModelContainer.ModelContainerError?) {
        let previousMode = isInMemoryMode
        isInMemoryMode = isInMemory
        storageError = error

        if isInMemory, !previousMode {
            // Transitioned to in-memory mode
            inMemoryModeStartTime = Date()
            logger.critical("Storage monitor detected transition to IN-MEMORY mode")

            if let error {
                logger.critical("Storage error: \(error.errorDescription ?? "Unknown error")")
                logger.critical("Failure reason: \(error.failureReason ?? "Unknown reason")")
                logger.critical("Recovery suggestion: \(error.recoverySuggestion ?? "No suggestion available")")
            }
        } else if !isInMemory, previousMode {
            // Transitioned back to persistent mode (unlikely but possible)
            logger.info("Storage monitor detected transition back to persistent mode")
            inMemoryModeStartTime = nil
            userHasBeenAlerted = false
        }
    }

    /// Marks that the user has been alerted about in-memory mode
    func markUserAlerted() {
        userHasBeenAlerted = true
        logger.info("User has been alerted about in-memory storage mode")
    }

    /// Resets the alert status (useful for testing or when dismissing warnings)
    func resetAlertStatus() {
        userHasBeenAlerted = false
        logger.debug("Alert status reset")
    }

    /// Returns a user-friendly description of the current storage mode
    var storageStatusDescription: String {
        if isInMemoryMode {
            if let error = storageError {
                """
                Temporary Storage Mode

                Reason: \(error.errorDescription ?? "Unknown error occurred")

                All data will be lost when the app closes.
                """
            } else {
                "Running in temporary storage mode. All data will be lost when the app closes."
            }
        } else {
            "Storage is working normally."
        }
    }

    /// Returns detailed error information for display
    var errorDetails: String? {
        guard let error = storageError else { return nil }

        var details = ""

        if let errorDescription = error.errorDescription {
            details += "Error: \(errorDescription)\n\n"
        }

        if let failureReason = error.failureReason {
            details += "Reason: \(failureReason)\n\n"
        }

        if let recoverySuggestion = error.recoverySuggestion {
            details += "Suggestion: \(recoverySuggestion)"
        }

        return details.isEmpty ? nil : details
    }

    /// Returns how long the app has been in in-memory mode
    var inMemoryModeDuration: TimeInterval? {
        guard let startTime = inMemoryModeStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
}
