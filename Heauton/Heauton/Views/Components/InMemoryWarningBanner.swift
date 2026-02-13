import OSLog
import SwiftUI

/// A prominent, persistent warning banner that appears when the app
/// is running in in-memory storage mode to prevent silent data loss
struct InMemoryWarningBanner: View {
    // MARK: - Environment

    @Environment(\.appDependencies)
    private var dependencies

    // MARK: - State

    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "InMemoryWarning")

    /// Controls the visibility of the detailed error sheet
    @State private var showErrorDetails = false

    /// Controls the visibility of the export sheet
    @State private var showExportSheet = false

    // MARK: - Properties

    let storageMonitor: StorageMonitor
    let onExport: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.white)

                // Warning message
                VStack(alignment: .leading, spacing: 4) {
                    Text("TEMPORARY STORAGE MODE")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("All data will be lost when app closes")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.95))
                }

                Spacer()

                // Action buttons
                HStack(spacing: 8) {
                    // Info button
                    Button {
                        showErrorDetails = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)

                    // Export button
                    Button {
                        showExportSheet = true
                        onExport()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.lsShadowGrey)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.semanticWarning, .semanticError],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Optional thin border at bottom for visual separation
            Divider()
                .background(Color.white.opacity(0.3))
        }
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showErrorDetails) {
            errorDetailsSheet
        }
        .sheet(isPresented: $showExportSheet) {
            exportDataSheet
        }
    }

    // MARK: - Error Details Sheet

    private var errorDetailsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Critical warning
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundColor(.lsShadowGrey)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Critical Storage Issue")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(
                                "The app's persistent storage could not be initialized. " +
                                    "Your data is being stored temporarily in memory."
                            )
                            .font(.body)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.lsAlabasterGrey.opacity(0.3))
                    .cornerRadius(12)

                    // What this means
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What This Means")
                            .font(.headline)
                            .fontWeight(.bold)

                        VStack(alignment: .leading, spacing: 6) {
                            bulletPoint("All data will be permanently lost when you close the app")
                            bulletPoint("Quotes, journal entries, exercises, and progress will not be saved")
                            bulletPoint("The app widget will not function properly")
                            bulletPoint("Data cannot be synced or backed up")
                        }
                    }
                    .padding()
                    .background(Color.lsPaleSlate.opacity(0.3))
                    .cornerRadius(12)

                    // Error details
                    if let errorDetails = storageMonitor.errorDetails {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Technical Details")
                                .font(.headline)
                                .fontWeight(.bold)

                            Text(errorDetails)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // What to do
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended Actions")
                            .font(.headline)
                            .fontWeight(.bold)

                        VStack(alignment: .leading, spacing: 6) {
                            bulletPoint("Export your data immediately using the Export button")
                            bulletPoint("Restart the app to see if the issue resolves")
                            bulletPoint("Ensure you have enough storage space available")
                            bulletPoint("If the problem persists, reinstall the app")
                            bulletPoint("Contact support if reinstalling doesn't help")
                        }
                    }
                    .padding()
                    .background(Color.lsPaleSlate2.opacity(0.3))
                    .cornerRadius(12)

                    // Duration info
                    if let duration = storageMonitor.inMemoryModeDuration {
                        Text("Time in temporary mode: \(formatDuration(duration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Storage Error Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showErrorDetails = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Export Data Sheet

    private var exportDataSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.appPrimary)

                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Save your quotes, journal entries, exercises, and progress to a file that you can import later.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Data will be saved as a JSON file")
                    bulletPoint("You can share this file via AirDrop, email, or save to Files")
                    bulletPoint("Import the file after reinstalling the app")
                }
                .padding()
                .background(Color.lsPaleSlate.opacity(0.3))
                .cornerRadius(12)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        showExportSheet = false
                        // Trigger actual export - this will be handled by the parent view
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Now")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPrimary)
                        .cornerRadius(12)
                    }

                    Button("Cancel") {
                        showExportSheet = false
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Helper Views

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
                .fontWeight(.bold)
            Text(text)
                .font(.body)
            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        InMemoryWarningBanner(
            storageMonitor: {
                let monitor = StorageMonitor()
                monitor.updateStorageMode(
                    isInMemory: true,
                    error: .appGroupNotConfigured
                )
                return monitor
            }()
        ) {
            Logger(subsystem: AppConstants.Logging.subsystem, category: "InMemoryWarning")
                .info("Export triggered")
        }

        Spacer()

        Text("Main Content Below")
            .font(.title)
            .padding()

        Spacer()
    }
    .edgesIgnoringSafeArea(.top)
}
