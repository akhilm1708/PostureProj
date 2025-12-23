import Foundation

struct UserProfile: Codable {
    var name: String
    var email: String?
    var sensitivity: String = "medium"
    var createdAt: Date = Date()

    var spineAngleThreshold: Double {
        switch sensitivity {
        case "low":    return 40.0
        case "high":   return 30.0
        default:       return 35.0
        }
    }

    var bufferTime: Double {
        switch sensitivity {
        case "low":    return 20.0
        case "high":   return 10.0
        default:       return 15.0
        }
    }
}

