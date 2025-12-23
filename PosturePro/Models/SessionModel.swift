import Foundation

struct SessionModel: Identifiable, Codable, Hashable {
    let id: String
    let startTime: Date
    let endTime: Date?
    let videoPath: String
    let metadataPath: String
    var postureEvents: [PostureEvent] = []
    var goodPosturePercentage: Double = 0.0

    var totalDuration: TimeInterval {
        guard let end = endTime else { return 0 }
        return end.timeIntervalSince(startTime)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    var formattedDuration: String {
        let duration = Int(totalDuration)
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    init(
        id: String = UUID().uuidString,
        startTime: Date = Date(),
        endTime: Date? = nil,
        videoPath: String = "",
        metadataPath: String = "",
        postureEvents: [PostureEvent] = [],
        goodPosturePercentage: Double = 0.0
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.videoPath = videoPath
        self.metadataPath = metadataPath
        self.postureEvents = postureEvents
        self.goodPosturePercentage = goodPosturePercentage
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SessionModel, rhs: SessionModel) -> Bool {
        lhs.id == rhs.id
    }
}

