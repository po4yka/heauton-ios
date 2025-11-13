import Foundation
import OSLog
import UserNotifications

/// Handles notification events and deep linking
///
/// # Architecture
///
/// The NotificationDelegate acts as a bridge between iOS notification events
/// and the app's deep link coordinator. It handles:
/// - Notification presentation (foreground)
/// - Notification response (taps)
/// - Deep link navigation
///
/// ## Flow
/// 1. User taps notification
/// 2. NotificationDelegate receives response
/// 3. Extracts deep link from userInfo
/// 4. Passes to DeepLinkCoordinator
/// 5. App navigates to content
///
/// ## Singleton Pattern
/// The delegate must be a singleton because UNUserNotificationCenter
/// only supports a single delegate instance.
@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // MARK: - Singleton

    static let shared = NotificationDelegate()

    // MARK: - Properties

    private let logger = Logger(
        subsystem: AppConstants.Logging.subsystem,
        category: AppConstants.Logging.Category.notifications
    )

    private var deepLinkCoordinator: DeepLinkCoordinator?

    // MARK: - Initialization

    override private init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Sets the deep link coordinator for navigation
    /// - Parameter coordinator: The deep link coordinator to use
    func setDeepLinkCoordinator(_ coordinator: DeepLinkCoordinator) {
        deepLinkCoordinator = coordinator
        logger.debug("Deep link coordinator set")
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification arrives while the app is in the foreground
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in
            logger.debug("Notification received in foreground")

            // Show banner and play sound even when app is open
            completionHandler([.banner, .sound, .badge])
        }
    }

    /// Called when the user taps on a notification
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            await handleNotificationResponse(response)
            completionHandler()
        }
    }

    // MARK: - Private Methods

    private func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        logger.info("Notification tapped: \(response.actionIdentifier)")

        // Log the notification tap
        if let quoteID = userInfo["quoteID"] as? String {
            logger.debug("Quote ID from notification: \(quoteID)")
        }

        // Handle the deep link
        guard let coordinator = deepLinkCoordinator else {
            logger.error("Deep link coordinator not set, cannot handle navigation")
            return
        }

        // Check if notification was dismissed vs tapped
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else {
            logger.debug("Notification dismissed or custom action, not navigating")
            return
        }

        // Parse deep link from userInfo
        guard let deepLink = DeepLink.fromNotification(userInfo: userInfo) else {
            logger.warning("Could not parse deep link from notification userInfo")
            return
        }

        // Record telemetry
        await TelemetryService.shared.recordFeatureUsage(
            "notification_opened",
            properties: ["deepLink": deepLink.description]
        )

        // Small delay to ensure app is ready
        try? await Task.sleep(for: .milliseconds(300))

        // Navigate using coordinator
        await coordinator.handle(deepLink)

        logger.info("Successfully handled notification deep link: \(deepLink.description)")
    }
}
