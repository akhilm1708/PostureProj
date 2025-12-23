import Foundation

struct Constants {
    // MARK: - Posture Detection Thresholds
    static let SPINE_ANGLE_THRESHOLD = 35.0
    static let SHOULDER_HEIGHT_THRESHOLD = 0.05
    static let HEAD_FORWARD_THRESHOLD = 0.15

    // MARK: - Alert System Timing (seconds)
    static let SLOUCH_BUFFER_TIME = 15.0
    static let ALERT_DISPLAY_DURATION = 4.0
    static let ALERT_ANIMATION_DURATION = 0.3

    // MARK: - Video Capture Settings
    static let VIDEO_FRAME_RATE = 30
    static let FRAME_SKIP = 3
}

