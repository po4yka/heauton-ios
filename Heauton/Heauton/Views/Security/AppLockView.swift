import SwiftUI

struct AppLockView: View {
    @Environment(\.appDependencies)
    private var dependencies
    @State private var isAuthenticating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var biometricType: BiometricType = .none

    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.appPrimary.opacity(0.3), .appSecondary.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // App Icon/Logo
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .shadow(radius: 10)

                // Title
                VStack(spacing: 8) {
                    Text("Heauton")
                        .font(.firaCodeTitle(.bold))
                        .foregroundStyle(.white)

                    Text("Your personal journal is protected")
                        .font(.firaCodeBody(.regular))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Biometric Icon
                if biometricType != .none {
                    Image(systemName: biometricType.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .padding(.bottom, 16)
                }

                // Unlock Button
                Button {
                    authenticate()
                } label: {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: biometricType.icon)
                            Text("Unlock with \(biometricType.displayName)")
                        }
                    }
                    .font(.firaCodeHeadline())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(isAuthenticating)

                if showError {
                    Text(errorMessage)
                        .font(.firaCodeCaption())
                        .foregroundStyle(Color.lsShadowGrey)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding()
        }
        .task {
            biometricType = await dependencies.appLockService.biometricType()
            // Auto-trigger authentication on appear with slight delay
            try? await Task.sleep(for: .milliseconds(500))
            authenticate()
        }
    }

    private func authenticate() {
        isAuthenticating = true
        showError = false

        Task {
            do {
                let success = try await dependencies.appLockService.authenticate()

                await MainActor.run {
                    isAuthenticating = false

                    if success {
                        onUnlock()
                    } else {
                        showError = true
                        errorMessage = "Authentication failed. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    AppLockView {
        // Unlocked successfully
    }
    .environment(\.appDependencies, AppDependencyContainer.shared)
}
