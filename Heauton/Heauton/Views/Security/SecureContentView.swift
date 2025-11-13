import SwiftUI

/// Wrapper view that handles app lock authentication
struct SecureContentView<Content: View>: View {
    @Environment(\.appDependencies)
    private var dependencies
    @Environment(\.scenePhase)
    private var scenePhase

    let content: Content
    let securitySettings = SecuritySettings.shared

    @State private var isLocked = false
    @State private var isInitialCheck = true

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .blur(radius: isLocked && securitySettings.hideInAppSwitcher ? 20 : 0)

            if isLocked {
                AppLockView {
                    isLocked = false
                }
                .transition(.opacity)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .task {
            await checkLockStatus()
        }
    }

    private func checkLockStatus() async {
        guard securitySettings.isAppLockEnabled else {
            isLocked = false
            return
        }

        let unlocked = await dependencies.appLockService.isAppUnlocked()

        await MainActor.run {
            isLocked = !unlocked
            isInitialCheck = false
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // Clear encryption key cache for security
            Task {
                await dependencies.encryptionService.clearKeyCache()
            }

            // Lock app if security setting is enabled
            if securitySettings.isAppLockEnabled, securitySettings.lockOnBackground {
                Task {
                    await dependencies.appLockService.lockApp()
                }
            }
        case .inactive:
            // Do nothing
            break
        case .active:
            // Check lock status when returning to foreground
            if securitySettings.isAppLockEnabled {
                Task {
                    await checkLockStatus()
                }
            }
        @unknown default:
            break
        }
    }
}
