import OSLog
import SwiftData
import SwiftUI

struct ScheduleSettingsView: View {
    @Environment(\.appDependencies)
    private var dependencies
    @Environment(\.modelContext)
    private var modelContext
    @Query private var schedules: [QuoteSchedule]

    @State private var showingPermissionSheet = false
    @State private var isSaving = false

    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "ScheduleSettings")

    private var schedule: QuoteSchedule? {
        schedules.first
    }

    var body: some View {
        Form {
            Section {
                Toggle("Enable Daily Quotes", isOn: Binding(
                    get: { schedule?.isEnabled ?? true },
                    set: { newValue in
                        if let schedule {
                            schedule.isEnabled = newValue
                            saveSchedule()
                        }
                    }
                ))
            } header: {
                Text("Schedule")
            } footer: {
                Text("Receive a daily inspirational quote at your preferred time")
            }

            if schedule?.isEnabled ?? true {
                Section("Delivery Time") {
                    DatePicker(
                        "Time",
                        selection: Binding(
                            get: { schedule?.scheduledTime ?? Date.now },
                            set: { newValue in
                                if let schedule {
                                    schedule.scheduledTime = newValue
                                    saveSchedule()
                                }
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }

                Section("Delivery Method") {
                    Picker("Method", selection: Binding(
                        get: { schedule?.deliveryMethod ?? .both },
                        set: { newValue in
                            if let schedule {
                                schedule.deliveryMethod = newValue
                                saveSchedule()
                            }
                        }
                    )) {
                        Text("Notification").tag(DeliveryMethod.notification)
                        Text("Widget").tag(DeliveryMethod.widget)
                        Text("Both").tag(DeliveryMethod.both)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Stepper(
                        "Don't repeat for \(schedule?.excludeRecentDays ?? 7) days",
                        value: Binding(
                            get: { schedule?.excludeRecentDays ?? 7 },
                            set: { newValue in
                                if let schedule {
                                    schedule.excludeRecentDays = newValue
                                    saveSchedule()
                                }
                            }
                        ),
                        in: 1...30
                    )
                } header: {
                    Text("Quote Rotation")
                } footer: {
                    Text("Avoid showing the same quote within this many days")
                }

                Section {
                    Button {
                        testNotification()
                    } label: {
                        Label("Test Notification", systemImage: "bell.badge")
                    }
                    .disabled(isSaving)
                } footer: {
                    Text("Send a test notification to verify your settings")
                }

                Section {
                    Button {
                        showingPermissionSheet = true
                    } label: {
                        Label("Notification Permissions", systemImage: "gear")
                    }
                }
            }

            if let schedule, !schedule.wasDeliveredToday {
                Section {
                    HStack {
                        Text("Next Delivery")
                        Spacer()
                        Text(schedule.formattedTime)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Daily Quote Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPermissionSheet) {
            NotificationPermissionView()
        }
        .task {
            // Create default schedule if none exists
            if schedules.isEmpty {
                let newSchedule = QuoteSchedule()
                modelContext.insert(newSchedule)
                try? modelContext.save()
            }
        }
    }

    private func saveSchedule() {
        isSaving = true

        Task {
            do {
                try modelContext.save()

                if let schedule {
                    try await dependencies.quoteSchedulerService.updateScheduleSettings(schedule)
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

    func testNotification() {
        Task {
            do {
                // Request authorization first
                let granted = try await dependencies.notificationManager.requestAuthorization()

                if granted {
                    // Select a quote and schedule immediately
                    if let quote = try await dependencies.quoteSchedulerService.selectQuoteForToday() {
                        let testTime = Date.now.addingTimeInterval(5) // 5 seconds from now
                        try await dependencies.notificationManager.scheduleQuoteNotification(
                            quote: quote,
                            time: testTime
                        )
                        logger.info("Test notification scheduled for 5 seconds from now")
                    } else {
                        logger.warning("No quote available for test notification")
                    }
                } else {
                    logger.info("Notification permission not granted")
                    showingPermissionSheet = true
                }
            } catch {
                logger.error("Failed to test notification: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScheduleSettingsView()
            // swiftlint:disable:next force_try
            .modelContainer(try! SharedModelContainer.create())
            .environment(\.appDependencies, AppDependencyContainer.shared)
    }
}
