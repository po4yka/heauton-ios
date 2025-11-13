import Foundation
import SwiftData

/// Service for scheduling and delivering daily quotes
actor QuoteSchedulerService: QuoteSchedulerServiceProtocol {
    private let modelContext: ModelContext
    private let notificationManager: NotificationManagerProtocol

    init(modelContext: ModelContext, notificationManager: NotificationManagerProtocol) {
        self.modelContext = modelContext
        self.notificationManager = notificationManager
    }

    // MARK: - Schedule Management

    func scheduleNextQuote() async throws {
        // Get or create schedule
        guard let schedule = try await getOrCreateSchedule() else {
            return
        }

        // Check if schedule is enabled
        guard schedule.isEnabled else {
            await notificationManager.cancelAllNotifications()
            return
        }

        // Select quote for delivery
        guard let quote = try await selectQuoteForToday() else {
            return
        }

        // Schedule notification if enabled
        if schedule.deliveryMethod == .notification || schedule.deliveryMethod == .both {
            try await notificationManager.scheduleQuoteNotification(
                quote: quote,
                time: schedule.scheduledTime
            )
        }

        // Update schedule with selected quote
        schedule.lastDeliveredQuote = quote
        schedule.lastDeliveryDate = Date.now

        try modelContext.save()
    }

    func selectQuoteForToday() async throws -> Quote? {
        guard let schedule = try await getOrCreateSchedule() else {
            return nil
        }

        // Don't deliver again if already delivered today
        if schedule.wasDeliveredToday {
            return schedule.lastDeliveredQuote
        }

        // Fetch all quotes
        let fetchDescriptor = FetchDescriptor<Quote>()
        let allQuotes = try modelContext.fetch(fetchDescriptor)

        // Filter out recently shown quotes
        let eligibleQuotes = filterEligibleQuotes(
            allQuotes,
            schedule: schedule
        )

        // Select random quote from eligible ones
        return eligibleQuotes.randomElement()
    }

    func updateScheduleSettings(_: QuoteSchedule) async throws {
        try modelContext.save()

        // Reschedule notifications
        try await scheduleNextQuote()
    }

    func cancelScheduledNotifications() async throws {
        await notificationManager.cancelAllNotifications()
    }

    func getUpcomingDeliveryTime() async -> Date? {
        guard let schedule = try? await getOrCreateSchedule(),
              schedule.isEnabled else {
            return nil
        }

        return schedule.scheduledTime
    }

    // MARK: - Private Helper Methods

    private func getOrCreateSchedule() async throws -> QuoteSchedule? {
        let fetchDescriptor = FetchDescriptor<QuoteSchedule>()
        let schedules = try modelContext.fetch(fetchDescriptor)

        if let existingSchedule = schedules.first {
            return existingSchedule
        }

        // Create default schedule
        let newSchedule = QuoteSchedule()
        modelContext.insert(newSchedule)
        try modelContext.save()

        return newSchedule
    }

    private func filterEligibleQuotes(_ quotes: [Quote], schedule: QuoteSchedule) -> [Quote] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(
            byAdding: .day,
            value: -schedule.excludeRecentDays,
            to: Date.now
        ) ?? Date.distantPast

        return quotes.filter { quote in
            if let categories = schedule.categories, !categories.isEmpty {
                // Once Quote model has categories, check if quote.categories overlaps with schedule.categories
            }

            // Exclude recently delivered quote
            if let lastDelivered = schedule.lastDeliveredQuote,
               lastDelivered.id == quote.id,
               let lastDeliveryDate = schedule.lastDeliveryDate,
               lastDeliveryDate > cutoffDate {
                return false
            }

            return true
        }
    }
}
