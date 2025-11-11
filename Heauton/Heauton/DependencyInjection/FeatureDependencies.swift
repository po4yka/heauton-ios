//  Feature-specific dependency protocols
//  Follows Interface Segregation Principle - clients only depend on what they need

import SwiftData

// MARK: - Feature Dependency Protocols

/// Dependencies required for the Quotes feature
/// Follows ISP by grouping only quote-related dependencies
protocol QuotesFeatureDependencies {
    var modelContainer: ModelContainer { get }
    var quoteFileStorage: QuoteFileStorageProtocol { get }
    var searchDatabaseManager: SearchDatabaseManagerProtocol { get }
    var quoteSearchService: QuoteSearchServiceProtocol { get }
    var spotlightIndexingService: SpotlightIndexingServiceProtocol { get }
    var quoteSharingService: QuoteSharingServiceProtocol { get }
}

/// Dependencies required for the Journal feature
/// Follows ISP by grouping only journal-related dependencies
protocol JournalFeatureDependencies {
    var modelContainer: ModelContainer { get }
    var encryptionService: EncryptionServiceProtocol { get }
    var journalService: JournalServiceProtocol { get }
}

/// Dependencies required for the Exercises feature
/// Follows ISP by grouping only exercise-related dependencies
protocol ExercisesFeatureDependencies {
    var modelContainer: ModelContainer { get }
    var exerciseService: ExerciseServiceProtocol { get }
}

/// Dependencies required for the Progress feature
/// Follows ISP by grouping only progress-related dependencies
protocol ProgressFeatureDependencies {
    var modelContainer: ModelContainer { get }
    var progressTrackerService: ProgressTrackerServiceProtocol { get }
}

/// Dependencies required for the Settings feature
/// Follows ISP by grouping only settings-related dependencies
protocol SettingsFeatureDependencies {
    var settingsManager: SettingsManagerProtocol { get }
    var appLockService: AppLockServiceProtocol { get }
    var encryptionService: EncryptionServiceProtocol { get }
    var notificationManager: NotificationManagerProtocol { get }
    var dataExportService: DataExportServiceProtocol { get }
}

/// Dependencies required for Quote Scheduling
/// Follows ISP by grouping only scheduling-related dependencies
protocol SchedulingFeatureDependencies {
    var quoteSchedulerService: QuoteSchedulerServiceProtocol { get }
    var notificationManager: NotificationManagerProtocol { get }
}

// MARK: - Feature-Specific Dependency Containers

/// Adapts AppDependencyContainer to QuotesFeatureDependencies
/// This allows views to request only quote-related dependencies
extension AppDependencyContainer: QuotesFeatureDependencies {}

/// Adapts AppDependencyContainer to JournalFeatureDependencies
extension AppDependencyContainer: JournalFeatureDependencies {}

/// Adapts AppDependencyContainer to ExercisesFeatureDependencies
extension AppDependencyContainer: ExercisesFeatureDependencies {}

/// Adapts AppDependencyContainer to ProgressFeatureDependencies
extension AppDependencyContainer: ProgressFeatureDependencies {}

/// Adapts AppDependencyContainer to SettingsFeatureDependencies
extension AppDependencyContainer: SettingsFeatureDependencies {}

/// Adapts AppDependencyContainer to SchedulingFeatureDependencies
extension AppDependencyContainer: SchedulingFeatureDependencies {}

// MARK: - Usage Examples

/*
 # How to Use Feature-Specific Dependencies

 Instead of depending on the entire AppDependencyProtocol, views and ViewModels
 should depend only on the specific feature dependencies they need.

 ## Before (Violates ISP):

 ```swift
 struct QuotesListView: View {
     @Environment(\.appDependencies) private var dependencies: AppDependencyProtocol
     // Has access to ALL services, even though it only needs quote-related ones
 }
 ```

 ## After (Follows ISP):

 ```swift
 struct QuotesListView: View {
     @Environment(\.quotesFeature) private var dependencies: QuotesFeatureDependencies
     // Only has access to quote-related services
 }

 // Or even more focused - inject only what's needed:
 init(
     searchService: QuoteSearchServiceProtocol,
     sharingService: QuoteSharingServiceProtocol
 ) {
     self.searchService = searchService
     self.sharingService = sharingService
 }
 ```

 ## Benefits:

 1. **Clearer Dependencies** - Easy to see what a view actually needs
 2. **Better Testing** - Mock only what's needed, not entire dependency graph
 3. **Faster Compilation** - Changes to unrelated services don't trigger recompilation
 4. **Principle Compliance** - Follows Interface Segregation Principle perfectly
 */
