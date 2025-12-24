import SwiftUI
import Combine

class AlertViewModel: ObservableObject {
    @Published var currentAlert: PostureAlert?
    @Published var isShowingAlert = false

    private var dismissTimer: Timer?
    private let alertDuration: TimeInterval = Constants.ALERT_DISPLAY_DURATION

    func showAlert(for userName: String, severity: PostureAlert.AlertSeverity) {
        let messages: [PostureAlert.AlertSeverity: String] = [
            .mild: "\(userName), it looks like you're slouching a little. 🪑 Time for a quick stretch?",
            .moderate: "\(userName), your posture is drifting. Stand tall! 💪",
            .severe: "⚠️ \(userName), major slouch alert! Let's reset that posture! 📍"
        ]

        let alert = PostureAlert(
            message: messages[severity] ?? "Check your posture!",
            userName: userName,
            severity: severity,
            timestamp: Date()
        )

        // Update published properties for in-app display
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            self.currentAlert = alert
            self.isShowingAlert = true
        }
        
        // Show floating window at screen bottom-right
        AlertWindowManager.shared.showAlert(alert) { [weak self] in
            self?.dismissAlert()
        }

        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: alertDuration, repeats: false) { [weak self] _ in
            self?.dismissAlert()
        }
    }

    func dismissAlert() {
        withAnimation(.easeOut(duration: 0.2)) {
            self.isShowingAlert = false
            self.currentAlert = nil
        }
        dismissTimer?.invalidate()
        AlertWindowManager.shared.dismissAlert()
    }
}

