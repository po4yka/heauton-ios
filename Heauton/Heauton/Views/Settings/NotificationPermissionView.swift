import SwiftUI

struct NotificationPermissionView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.appDependencies)
    private var dependencies

    @State private var isRequesting = false
    @State private var authorizationStatus: AuthStatus = .notDetermined

    enum AuthStatus {
        case notDetermined
        case granted
        case denied
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.appPrimary.gradient)

                // Title
                Text("Enable Notifications")
                    .font(.title.bold())

                // Description
                Text("Get daily inspirational quotes delivered at your preferred time.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                // Status message
                if authorizationStatus == .granted {
                    Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.semanticSuccess)
                        .padding()
                        .background(Color.semanticSuccess.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if authorizationStatus == .denied {
                    VStack(spacing: 12) {
                        Label("Notifications Denied", systemImage: "xmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.semanticError)

                        Text("Please enable notifications in Settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.semanticError.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Action buttons
                VStack(spacing: 12) {
                    if authorizationStatus == .notDetermined {
                        Button {
                            requestAuthorization()
                        } label: {
                            if isRequesting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Enable Notifications")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(isRequesting)
                    } else if authorizationStatus == .denied {
                        Button {
                            openSettings()
                        } label: {
                            Text("Open Settings")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    Button("Maybe Later") {
                        dismiss()
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.bottom, 32)
            }
            .padding()
            .navigationTitle("Daily Quotes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func requestAuthorization() {
        isRequesting = true

        Task {
            do {
                let granted = try await dependencies.notificationManager.requestAuthorization()
                await MainActor.run {
                    authorizationStatus = granted ? .granted : .denied
                    isRequesting = false
                }

                if granted {
                    // Dismiss after showing success for 1.5 seconds
                    try? await Task.sleep(for: .milliseconds(1500))
                    await MainActor.run {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    authorizationStatus = .denied
                    isRequesting = false
                }
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NotificationPermissionView()
        .environment(\.appDependencies, AppDependencyContainer.shared)
}
