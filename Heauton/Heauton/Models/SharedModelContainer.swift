import Foundation
import OSLog
import SwiftData

/// Shared ModelContainer configuration for the app and widget extension
///
/// Migration Strategy:
/// - Uses HeautonMigrationPlan (defined in SchemaMigration.swift)
/// - Provides safe, versioned schema migrations to prevent data loss
/// - Current version: V1 (1.0.0)
/// - See SchemaMigration.swift for detailed migration documentation
///
/// Data Protection:
/// - All data stored by this container is protected using iOS Data Protection
/// - Files use NSFileProtectionComplete (defined in Heauton.entitlements)
/// - Data is encrypted and inaccessible when device is locked
/// - Keychain items use kSecAttrAccessibleAfterFirstUnlock for encryption keys
enum SharedModelContainer {
    /// App Group identifier for sharing data between app and widget
    /// Note: This must match the App Group configured in your project's capabilities
    static let appGroupIdentifier = AppConstants.appGroupIdentifier

    private static let logger = Logger(
        subsystem: AppConstants.Logging.subsystem,
        category: AppConstants.Logging.Category.modelContainer
    )

    /// Storage type for the model container
    enum StorageType {
        case persistent
        case inMemory

        var isPersistent: Bool {
            self == .persistent
        }
    }

    /// Result of container creation including storage type
    struct ContainerResult {
        let container: ModelContainer
        let storageType: StorageType
        let error: ModelContainerError?
    }

    /// Errors that can occur during ModelContainer creation
    enum ModelContainerError: Error, LocalizedError {
        case initializationFailed(Error)
        case appGroupNotConfigured
        case schemaInvalid

        var errorDescription: String? {
            switch self {
            case .initializationFailed(let error):
                "Failed to initialize data storage: \(error.localizedDescription)"
            case .appGroupNotConfigured:
                "App Group not configured. Please check project capabilities."
            case .schemaInvalid:
                "Database schema is invalid. App may need to be reinstalled."
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .initializationFailed:
                "Try restarting the app. If the problem persists, please reinstall the app."
            case .appGroupNotConfigured:
                "Please contact support or reinstall the app."
            case .schemaInvalid:
                "Please reinstall the app to fix the database."
            }
        }

        var failureReason: String? {
            switch self {
            case .initializationFailed:
                "The app's database could not be initialized."
            case .appGroupNotConfigured:
                "The app is not properly configured for data sharing."
            case .schemaInvalid:
                "The database structure is corrupted or incompatible."
            }
        }
    }

    /// Creates a shared ModelContainer that can be used by both the app and widget
    ///
    /// Uses HeautonMigrationPlan to ensure safe schema migrations and prevent data loss.
    ///
    /// - Returns: ModelContainer configured with App Group and migration strategy
    /// - Throws: ModelContainerError if creation fails
    ///
    /// Migration Behavior:
    /// - Automatically migrates from previous schema versions to current version
    /// - Preserves all existing data during migration
    /// - Fails safely if migration cannot be completed
    /// - Logs migration progress for debugging
    static func create() throws -> ModelContainer {
        // Verify App Group is accessible
        guard FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) != nil else {
            logger.error("App Group container not found: \(appGroupIdentifier)")
            throw ModelContainerError.appGroupNotConfigured
        }

        // Configure the model to use the App Group container with migration plan
        let modelConfiguration = ModelConfiguration(
            appGroupIdentifier,
            schema: Schema(versionedSchema: HeautonSchemaV1.self)
        )

        do {
            let container = try ModelContainer(
                for: Schema(versionedSchema: HeautonSchemaV1.self),
                migrationPlan: HeautonMigrationPlan.self,
                configurations: [modelConfiguration]
            )
            logger.info("ModelContainer created successfully with migration strategy")
            return container
        } catch {
            logger.error("Failed to create ModelContainer: \(error.localizedDescription)")
            throw ModelContainerError.initializationFailed(error)
        }
    }

    /// Creates a ModelContainer with fallback to in-memory storage if App Group fails
    /// This is useful for testing or when App Group is misconfigured
    /// - Returns: ContainerResult indicating storage type and any errors
    /// - Warning: In-memory storage means ALL DATA WILL BE LOST when app terminates
    static func createWithFallback() -> ContainerResult {
        do {
            let container = try create()
            logger.info("Successfully created persistent ModelContainer")
            return ContainerResult(
                container: container,
                storageType: .persistent,
                error: nil
            )
        } catch let error as ModelContainerError {
            logModelContainerError(error)
            return ContainerResult(
                container: createInMemory(),
                storageType: .inMemory,
                error: error
            )
        } catch {
            logUnexpectedError(error)
            return ContainerResult(
                container: createInMemory(),
                storageType: .inMemory,
                error: .initializationFailed(error)
            )
        }
    }

    /// Logs detailed information about a ModelContainerError
    private static func logModelContainerError(_ error: ModelContainerError) {
        logger.critical("═══════════════════════════════════════════════════════════")
        logger.critical("CRITICAL: Failed to create persistent storage container")
        logger.critical("═══════════════════════════════════════════════════════════")
        logger.critical("Error Type: \(String(describing: error))")
        logger.critical("Error Description: \(error.errorDescription ?? "None")")
        logger.critical("Failure Reason: \(error.failureReason ?? "Unknown")")
        logger.critical("Recovery Suggestion: \(error.recoverySuggestion ?? "None")")
        logger.critical("───────────────────────────────────────────────────────────")
        logInMemoryFallbackWarning()
        logAppGroupDebugInfo()
    }

    /// Logs warnings about switching to in-memory storage
    private static func logInMemoryFallbackWarning() {
        logger.critical("FALLBACK: Switching to IN-MEMORY storage")
        logger.critical("WARNING: ALL USER DATA WILL BE PERMANENTLY LOST WHEN APP CLOSES")
        logger.critical("WARNING: Widget functionality will be unavailable")
        logger.critical("WARNING: Data cannot be backed up or synced")
        logger.critical("ACTION REQUIRED: User should export data immediately")
        logger.critical("═══════════════════════════════════════════════════════════")
    }

    /// Logs app group debugging information
    private static func logAppGroupDebugInfo() {
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            logger.info("App Group container URL exists: \(containerURL.path)")
            let isAccessible = FileManager.default.isReadableFile(atPath: containerURL.path)
            logger.info("App Group directory accessible: \(isAccessible)")
        } else {
            logger.critical("App Group container URL is nil - App Group may not be properly configured")
            logger.critical("App Group Identifier: \(appGroupIdentifier)")
        }
    }

    /// Logs information about unexpected errors during container creation
    private static func logUnexpectedError(_ error: Error) {
        logger.critical("═══════════════════════════════════════════════════════════")
        logger.critical("CRITICAL: Unexpected error creating storage container")
        logger.critical("═══════════════════════════════════════════════════════════")
        logger.critical("Error: \(error.localizedDescription)")
        logger.critical("Error Type: \(type(of: error))")
        logger.critical("Underlying Error: \(String(describing: error))")
        logger.critical("───────────────────────────────────────────────────────────")
        logger.critical("FALLBACK: Switching to IN-MEMORY storage")
        logger.critical("WARNING: ALL USER DATA WILL BE PERMANENTLY LOST WHEN APP CLOSES")
        logger.critical("ACTION REQUIRED: User should export data immediately")
        logger.critical("═══════════════════════════════════════════════════════════")
    }

    /// Creates an in-memory ModelContainer for testing or fallback
    ///
    /// Uses the same migration plan as persistent storage for consistency.
    ///
    /// - Returns: In-memory ModelContainer
    /// - Warning: All data is lost when the app terminates
    static func createInMemory() -> ModelContainer {
        let modelConfiguration = ModelConfiguration(
            schema: Schema(versionedSchema: HeautonSchemaV1.self),
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(
                for: Schema(versionedSchema: HeautonSchemaV1.self),
                migrationPlan: HeautonMigrationPlan.self,
                configurations: [modelConfiguration]
            )
            logger.info("In-memory ModelContainer created with migration strategy")
            return container
        } catch {
            // This should never happen with in-memory storage
            logger.critical("Failed to create in-memory ModelContainer: \(error)")
            // Create the simplest possible container as absolute fallback
            do {
                let emergencyConfiguration = ModelConfiguration(
                    schema: Schema(versionedSchema: HeautonSchemaV1.self),
                    isStoredInMemoryOnly: true
                )
                return try ModelContainer(
                    for: Schema(versionedSchema: HeautonSchemaV1.self),
                    configurations: [emergencyConfiguration]
                )
            } catch {
                // If even this fails, the app cannot continue
                // This is an unrecoverable error that should never occur.
                logger.fault("Unable to create any ModelContainer: \(String(describing: error))")
                fatalError("Critical storage initialization failure")
            }
        }
    }
}
