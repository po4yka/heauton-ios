import SwiftUI
import UIKit

/// SwiftUI wrapper for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let onComplete: (Bool) -> Void

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete(completed)
        }

        return controller
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {
        // No updates needed
    }
}
