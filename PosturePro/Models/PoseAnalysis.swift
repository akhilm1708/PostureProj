import Foundation
import Vision

struct PoseAnalysis {
    let spineAngle: Double
    let headForwardDistance: Double
    let shoulderAsymmetry: Double
    let confidence: Double
    let timestamp: Date = Date()

    var isSlouching: Bool {
        return spineAngle > Constants.SPINE_ANGLE_THRESHOLD
    }

    var slouchSeverity: String {
        switch spineAngle {
        case ...30:
            return "none"
        case 30..<35:
            return "mild"
        case 35..<50:
            return "moderate"
        default:
            return "severe"
        }
    }

    var isConfident: Bool {
        return confidence > 0.7
    }
}

