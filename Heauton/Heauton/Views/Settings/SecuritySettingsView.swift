import SwiftUI

struct SecuritySettingsView: View {
    @Environment(\.appDependencies)
    private var dependencies
    @Bindable var settings = SecuritySettings.shared

    @State private var biometricType: BiometricType = .none
    @State private var isBiometricAvailable = false

    var body: some View {
        Form {
            Section {
                Toggle("Enable App Lock", isOn: $settings.isAppLockEnabled)
                    .disabled(!isBiometricAvailable)

                if !isBiometricAvailable {
                    Label {
                        Text("Biometric authentication not available")
                            .font(.firaCodeCaption())
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Color.lsIronGrey)
                    }
                }
            } header: {
                Text("Authentication")
            } footer: {
                if isBiometricAvailable {
                    Text("Protect your journal with \(biometricType.displayName)")
                } else {
                    Text("Set up \(biometricType.displayName) in Settings to enable app lock")
                }
            }

            if settings.isAppLockEnabled {
                Section("App Lock Options") {
                    Toggle("Lock When Backgrounded", isOn: $settings.lockOnBackground)
                    Toggle("Require Auth for Journal", isOn: $settings.requireAuthForJournal)
                }
            }

            Section {
                Toggle("Hide in App Switcher", isOn: $settings.hideInAppSwitcher)
                Toggle("Disable Screenshots", isOn: $settings.disableScreenshots)
            } header: {
                Text("Privacy")
            } footer: {
                Text("Additional privacy protection for your journal entries")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("Your Data Stays Private")
                            .font(.firaCodeSubheadline(.semiBold))
                    } icon: {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(Color.lsGunmetal)
                    }

                    Text(
                        """
                        All journal entries are stored locally on your device. \
                        Your data is never sent to any servers.
                        """
                    )
                    .font(.firaCodeCaption())
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Data Security")
            }
        }
        .navigationTitle("Security & Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            biometricType = await dependencies.appLockService.biometricType()
            isBiometricAvailable = await dependencies.appLockService.isBiometricAvailable()
        }
    }
}

#Preview {
    NavigationStack {
        SecuritySettingsView()
            .environment(\.appDependencies, AppDependencyContainer.shared)
    }
}
