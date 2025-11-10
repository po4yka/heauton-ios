import BackgroundTasks
import OSLog
import SwiftData
import SwiftUI
import UserNotifications

@main
struct HeautonApp: App {
    // Dependency injection container
    private let dependencies = AppDependencyContainer.shared

    // Deep link coordinator
    @State private var deepLinkCoordinator = DeepLinkCoordinator()

    // Background task identifier
    private let quoteRefreshTaskIdentifier = "com.heauton.quotes.refresh"

    // Logger
    private let logger = Logger(subsystem: "com.heauton.app", category: "App")

    // Track background refresh failure count
    @State private var backgroundRefreshFailureCount = 0
    private let maxBackgroundRefreshFailures = 5

    // Storage error state
    @State private var showStorageErrorAlert = false
    @State private var showDataExport = false
    @State private var exportShareURL: URL?
    @State private var showExportShare = false

    init() {
        // Register background task handler
        registerBackgroundTasks()

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            SecureContentView {
                VStack(spacing: 0) {
                    // Show persistent warning banner when in in-memory mode
                    if dependencies.storageMonitor.isInMemoryMode {
                        InMemoryWarningBanner(
                            storageMonitor: dependencies.storageMonitor,
                            onExport: handleExportData
                        )
                    }

                    TabBarView()
                        .environment(\.appDependencies, dependencies)
                        .environment(\.deepLinkCoordinator, deepLinkCoordinator)
                }
                .task {
                    // Check for storage errors and show critical alert
                    if !dependencies.isStoragePersistent {
                        logger.critical("App is using in-memory storage - data will be lost!")

                        // Mark that user needs to be alerted if not already
                        if !dependencies.storageMonitor.userHasBeenAlerted {
                            showStorageErrorAlert = true
                        }
                    }

                    await SampleQuotes.seedIfNeeded(in: dependencies.modelContainer.mainContext)
                    await SampleEvents.seedIfNeeded(in: dependencies.modelContainer.mainContext)
                    await SampleJournalPrompts.seedIfNeeded(in: dependencies.modelContainer.mainContext)
                    await SampleExercises.seedIfNeeded(in: dependencies.modelContainer.mainContext)
                    await SampleAchievements.seedIfNeeded(in: dependencies.modelContainer.mainContext)

                    // Schedule initial quote delivery
                    await scheduleQuoteDelivery()

                    // Schedule background refresh
                    scheduleBackgroundRefresh()

                    // Set up deep link coordinator in notification delegate
                    NotificationDelegate.shared.setDeepLinkCoordinator(deepLinkCoordinator)
                }
                .alert(
                    "Critical Storage Error",
                    isPresented: $showStorageErrorAlert
                ) {
                    Button("Export Data Now") {
                        dependencies.storageMonitor.markUserAlerted()
                        handleExportData()
                    }
                    Button("Continue Anyway", role: .cancel) {
                        dependencies.storageMonitor.markUserAlerted()
                    }
                } message: {
                    if let error = dependencies.storageError {
                        Text("""
                        \(error.errorDescription ?? "Unknown error")

                        WARNING: Your data is using temporary storage and will be LOST when the app closes.

                        \(error.recoverySuggestion ?? "Please reinstall the app.")

                        It is strongly recommended to export your data immediately.
                        """)
                    } else {
                        Text(
                            "The app's storage system could not be initialized properly. " +
                                "All data will be lost when the app closes. " +
                                "Please export your data immediately."
                        )
                    }
                }
                .sheet(isPresented: $showExportShare) {
                    if let url = exportShareURL {
                        ShareSheet(items: [url]) { _ in
                            showExportShare = false
                        }
                    }
                }
            }
            .environment(\.appDependencies, dependencies)
            .onOpenURL { url in
                Task {
                    await deepLinkCoordinator.handleURL(url)
                }
            }
        }
        .modelContainer(dependencies.modelContainer)
    }

    // MARK: - Data Export

    /// Handles exporting data when in in-memory mode
    private func handleExportData() {
        Task {
            do {
                logger.info("Exporting complete backup due to in-memory storage mode")
                let url = try await dependencies.dataExportService.exportCompleteBackup()

                await MainActor.run {
                    exportShareURL = url
                    showExportShare = true
                }

                logger.info("Successfully exported backup to: \(url.path)")
            } catch {
                logger.error("Failed to export backup: \(error.localizedDescription)")

                // Show error alert
                await MainActor.run {
                    // Create and show error alert
                    let alert = UIAlertController(
                        title: "Export Failed",
                        message: "Unable to export your data: \(error.localizedDescription). Please try again from Settings > Data Management.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))

                    // Present on the topmost view controller
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(alert, animated: true)
                    }
                }
            }
        }
    }

    // MARK: - Background Tasks

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: quoteRefreshTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                return
            }
            handleQuoteRefresh(task: refreshTask)
        }
    }

    private func handleQuoteRefresh(task: BGAppRefreshTask) {
        // Schedule next background task
        scheduleBackgroundRefresh()

        // Set expiration handler
        task.expirationHandler = {
            logger.warning("Background quote refresh task expired before completion")
            task.setTaskCompleted(success: false)
        }

        Task {
            logger.info("Starting background quote refresh with retry")

            // Execute with retry policy
            let result = await RetryUtility.executeWithResult(policy: .default) {
                try await dependencies.quoteSchedulerService.scheduleNextQuote()
            }

            switch result {
            case .success:
                // Reset failure count on success
                await MainActor.run {
                    backgroundRefreshFailureCount = 0
                }

                logger.info("Background quote refresh completed successfully")
                task.setTaskCompleted(success: true)

            case .failure(let error):
                logger.error("Background quote refresh failed after retries: \(error.localizedDescription)")

                // Track failure count
                await MainActor.run {
                    backgroundRefreshFailureCount += 1

                    if backgroundRefreshFailureCount >= maxBackgroundRefreshFailures {
                        logger.critical("Background refresh failed \(self.backgroundRefreshFailureCount) times consecutively")
                    }

                    // Notify user of failures
                    Task {
                        await notifyBackgroundTaskFailure(
                            failureCount: backgroundRefreshFailureCount,
                            error: error
                        )
                    }
                }

                task.setTaskCompleted(success: false)
            }
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: quoteRefreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.error("Could not schedule app refresh: \(error.localizedDescription)")
        }
    }

    private func scheduleQuoteDelivery() async {
        do {
            try await dependencies.quoteSchedulerService.scheduleNextQuote()
        } catch {
            logger.error("Could not schedule quote delivery: \(error.localizedDescription)")
        }
    }

    // MARK: - User Notifications

    /// Notifies user about background task failures
    /// - Parameters:
    ///   - failureCount: Number of consecutive failures
    ///   - error: The error that caused the failure
    private func notifyBackgroundTaskFailure(failureCount: Int, error: Error) async {
        // Only notify after 2 or more failures to avoid being too noisy
        guard failureCount >= 2 else { return }

        let content = UNMutableNotificationContent()

        if failureCount >= maxBackgroundRefreshFailures {
            // Critical notification for max failures
            content.title = "Daily Quotes Not Working"
            content.body = "Your daily quotes haven't been delivered for \(failureCount) days. Please open the app to resolve this issue."
            content.sound = .defaultCritical
            content.interruptionLevel = .critical
        } else if failureCount >= 3 {
            // Urgent notification
            content.title = "Daily Quotes Issue"
            content.body = "There's a problem delivering your daily quotes. Please check your app settings."
            content.sound = .default
            content.interruptionLevel = .timeSensitive
        } else {
            // First warning notification
            content.title = "Daily Quotes Delayed"
            content.body = "We're having trouble delivering your daily quotes. We'll keep trying."
            content.sound = .default
        }

        content.categoryIdentifier = "BACKGROUND_TASK_FAILURE"
        content.userInfo = ["failureCount": failureCount]

        // Schedule notification to appear immediately
        let request = UNNotificationRequest(
            identifier: "background-task-failure-\(failureCount)",
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("Sent background task failure notification (failure count: \(failureCount))")
        } catch {
            logger.error("Failed to send background task failure notification: \(error.localizedDescription)")
        }
    }
}
