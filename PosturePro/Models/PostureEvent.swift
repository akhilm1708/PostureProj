import Foundation

struct PostureEvent: Identifiable, Codable, Hashable {
    let id: String
    let timestamp: Double
    let severity: String
    let spineAngle: Double
    let detectionConfidence: Double

    init(
        id: String = UUID().uuidString,
        timestamp: Double,
        severity: String,
        spineAngle: Double,
        detectionConfidence: Double = 0.8
    ) {
        self.id = id
        self.timestamp = timestamp
        self.severity = severity
        self.spineAngle = spineAngle
        self.detectionConfidence = detectionConfidence
    }

    func formattedTime() -> String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PostureEvent, rhs: PostureEvent) -> Bool {
        lhs.id == rhs.id
    }
}

