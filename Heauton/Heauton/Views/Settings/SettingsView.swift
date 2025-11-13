import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Bindable var settings = SettingsManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Quotes") {
                    NavigationLink {
                        ScheduleSettingsView()
                    } label: {
                        Label("Daily Quote Schedule", systemImage: "bell.badge")
                    }
                }

                Section("Privacy & Security") {
                    NavigationLink {
                        SecuritySettingsView()
                    } label: {
                        Label("Security Settings", systemImage: "lock.shield")
                    }

                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Data Management", systemImage: "externaldrive.badge.icloud")
                    }
                }

                Section {
                    Picker("Refresh Interval", selection: $settings.widgetRefreshInterval) {
                        ForEach(SettingsManager.availableIntervals, id: \.self) { interval in
                            Text(settings.intervalDescription(interval))
                                .tag(interval)
                        }
                    }
                    .onChange(of: settings.widgetRefreshInterval) { _, _ in
                        // Reload all widgets when the interval changes
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                } header: {
                    Text("Widget Settings")
                } footer: {
                    Text(
                        "Choose how often widgets should refresh with a new quote. " +
                            "Shorter intervals may impact battery life."
                    )
                }

                Section {
                    HStack {
                        Text("Current Interval")
                        Spacer()
                        Text(settings.intervalDescription(settings.widgetRefreshInterval))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Next Update")
                        Spacer()
                        Text("In \(settings.intervalDescription(settings.widgetRefreshInterval))")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Status")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Battery Impact", systemImage: "battery.100")
                            .font(.firaCodeSubheadline(.medium))

                        Text(
                            "Shorter refresh intervals (5-15 minutes) will update " +
                                "widgets more frequently but may consume more battery. " +
                                "Longer intervals (1+ hours) are more battery-efficient."
                        )
                        .font(.firaCodeCaption())
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Information")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
