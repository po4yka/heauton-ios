//  Dependency Injection Container using protocol-based DI pattern
//  This provides compile-time safety and testability without external dependencies

import Foundation
import SwiftData
import SwiftUI

/// Protocol defining all app-level dependencies
/// This allows for easy mocking and testing
protocol AppDependencyProtocol {
    var modelContainer: ModelContainer { get }
    var storageMonitor: StorageMonitor { get }
    var settingsManager: SettingsManagerProtocol { get }
    var quoteFileStorage: QuoteFileStorageProtocol { get }
    var searchDatabaseManager: SearchDatabaseManagerProtocol { get }
    var quoteSearchService: QuoteSearchServiceProtocol { get }
    var spotlightIndexingService: SpotlightIndexingServiceProtocol { get }
    var backgroundIndexingService: BackgroundIndexingServiceProtocol { get }
    var notificationManager: NotificationManagerProtocol { get }
    var quoteSchedulerService: QuoteSchedulerServiceProtocol { get }
    var quoteSharingService: QuoteSharingServiceProtocol { get }
    var journalService: JournalServiceProtocol { get }
    var appLockService: AppLockServiceProtocol { get }
    var encryptionService: EncryptionServiceProtocol { get }
    var exerciseService: ExerciseServiceProtocol { get }
    var progressTrackerService: ProgressTrackerServiceProtocol { get }
    var dataExportService: DataExportServiceProtocol { get }
    var telemetryService: TelemetryService { get }
}

/// Main dependency injection container
/// Manages lifecycle and dependencies for the entire app
final class AppDependencyContainer: AppDependencyProtocol {
    // MARK: - Singleton

    static let shared = AppDependencyContainer()

    // MARK: - Storage Status

    /// Storage initialization result
    private(set) lazy var storageResult: SharedModelContainer.ContainerResult =
        SharedModelContainer.createWithFallback()

    /// Whether storage is persistent (vs in-memory)
    var isStoragePersistent: Bool {
        storageResult.storageType.isPersistent
    }

    /// Storage initialization error if any
    var storageError: SharedModelContainer.ModelContainerError? {
        storageResult.error
    }

    // MARK: - Dependencies

    lazy var modelContainer: ModelContainer = storageResult.container

    lazy var storageMonitor: StorageMonitor = {
        let monitor = StorageMonitor()
        // Initialize the monitor with the current storage state
        monitor.updateStorageMode(
            isInMemory: !storageResult.storageType.isPersistent,
            error: storageResult.error
        )
        return monitor
    }()

    lazy var settingsManager: SettingsManagerProtocol = SettingsManager()

    lazy var quoteFileStorage: QuoteFileStorageProtocol = QuoteFileStorage()

    lazy var searchDatabaseManager: SearchDatabaseManagerProtocol = SearchDatabaseManager()

    lazy var quoteSearchService: QuoteSearchServiceProtocol = QuoteSearchService()

    lazy var spotlightIndexingService: SpotlightIndexingServiceProtocol = SpotlightIndexingService()

    lazy var backgroundIndexingService: BackgroundIndexingServiceProtocol = BackgroundIndexingService()

    lazy var notificationManager: NotificationManagerProtocol = NotificationManager()

    @MainActor lazy var quoteSchedulerService: QuoteSchedulerServiceProtocol = QuoteSchedulerService(
        modelContext: ModelContext(modelContainer),
        notificationManager: notificationManager
    )

    lazy var quoteSharingService: QuoteSharingServiceProtocol = QuoteSharingService()

    @MainActor lazy var journalService: JournalServiceProtocol = JournalService(
        modelContext: ModelContext(modelContainer),
        encryptionService: encryptionService
    )

    lazy var appLockService: AppLockServiceProtocol = AppLockService()

    lazy var encryptionService: EncryptionServiceProtocol = EncryptionService()

    @MainActor lazy var exerciseService: ExerciseServiceProtocol = ExerciseService(
        modelContext: ModelContext(modelContainer)
    )

    @MainActor lazy var progressTrackerService: ProgressTrackerServiceProtocol = ProgressTrackerService(
        modelContext: ModelContext(modelContainer)
    )

    @MainActor lazy var dataExportService: DataExportServiceProtocol = DataExportService(
        journalService: journalService,
        modelContext: ModelContext(modelContainer)
    )

    lazy var telemetryService = TelemetryService.shared

    // MARK: - Initialization

    private init() {}
}

// MARK: - SwiftUI Environment Key

private struct AppDependencyKey: EnvironmentKey {
    static let defaultValue: AppDependencyProtocol = AppDependencyContainer.shared
}

extension EnvironmentValues {
    var appDependencies: AppDependencyProtocol {
        get { self[AppDependencyKey.self] }
        set { self[AppDependencyKey.self] = newValue }
    }
}
