import Foundation
import OSLog
import SwiftData
import SwiftUI

/// ViewModel for ScheduleSettingsView following MVVM + @Observable pattern
/// Handles quote schedule management and notification testing
@Observable
@MainActor
final class ScheduleSettingsViewModel {
    // MARK: - Dependencies

    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "ScheduleSettings")
    private let modelContext: ModelContext
    private let quoteSchedulerService: QuoteSchedulerServiceProtocol
    private let notificationManager: NotificationManagerProtocol

    // MARK: - Published State

    var showingPermissionSheet = false
    var isSaving = false
    var schedule: QuoteSchedule?

    // MARK: - Computed Properties

    var isEnabled: Bool {
        get { schedule?.isEnabled ?? true }
        set {
            guard let schedule else { return }
            schedule.isEnabled = newValue
            saveSchedule()
        }
    }

    var scheduledTime: Date {
        get { schedule?.scheduledTime ?? Date.now }
        set {
            guard let schedule else { return }
            schedule.scheduledTime = newValue
            saveSchedule()
        }
    }

    var deliveryMethod: DeliveryMethod {
        get { schedule?.deliveryMethod ?? .both }
        set {
            guard let schedule else { return }
            schedule.deliveryMethod = newValue
            saveSchedule()
        }
    }

    var excludeRecentDays: Int {
        get { schedule?.excludeRecentDays ?? 7 }
        set {
            guard let schedule else { return }
            schedule.excludeRecentDays = newValue
            saveSchedule()
        }
    }

    var showNextDelivery: Bool {
        guard let schedule else { return false }
        return !schedule.wasDeliveredToday
    }

    var nextDeliveryTime: String {
        schedule?.formattedTime ?? ""
    }

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        quoteSchedulerService: QuoteSchedulerServiceProtocol,
        notificationManager: NotificationManagerProtocol
    ) {
        self.modelContext = modelContext
        self.quoteSchedulerService = quoteSchedulerService
        self.notificationManager = notificationManager
    }

    // MARK: - Public Methods

    /// Load or create the schedule
    func loadSchedule(from schedules: [QuoteSchedule]) {
        if let existingSchedule = schedules.first {
            schedule = existingSchedule
        }
    }

    /// Create default schedule if none exists
    func createDefaultScheduleIfNeeded() {
        if schedule == nil {
            let newSchedule = QuoteSchedule()
            modelContext.insert(newSchedule)
            schedule = newSchedule
            try? modelContext.save()
        }
    }

    /// Save schedule changes
    func saveSchedule() {
        isSaving = true

        Task {
            do {
                try modelContext.save()

                if let schedule {
                    try await quoteSchedulerService.updateScheduleSettings(schedule)
                }

                await MainActor.run {
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
                logger.error("Failed to save schedule: \(error.localizedDescription)")
            }
        }
    }

    /// Test notification delivery
    func testNotification() async {
        do {
            // Request authorization first
            let granted = try await notificationManager.requestAuthorization()

            if granted {
                // Select a quote and schedule immediately
                if let quote = try await quoteSchedulerService.selectQuoteForToday() {
                    let testTime = Date.now.addingTimeInterval(5) // 5 seconds from now
                    try await notificationManager.scheduleQuoteNotification(
                        quote: quote,
                        time: testTime
                    )
                    logger.info("Test notification scheduled for 5 seconds from now")
                } else {
                    logger.warning("No quote available for test notification")
                }
            } else {
                logger.info("Notification permission not granted, showing settings")
                showingPermissionSheet = true
            }
        } catch {
            logger.error("Failed to test notification: \(error.localizedDescription)")
        }
    }

    /// Show notification permission sheet
    func showPermissionSettings() {
        showingPermissionSheet = true
    }
}
