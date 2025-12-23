import Foundation

struct PostureAlert: Identifiable {
    let id = UUID()
    let message: String
    let userName: String
    let severity: AlertSeverity
    let timestamp: Date

    enum AlertSeverity {
        case mild
        case moderate
        case severe
    }
}

