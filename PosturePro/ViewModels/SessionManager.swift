import Foundation
import Combine

final class SessionManager: ObservableObject {
    @Published var isSessionActive = false
    @Published var allSessions: [SessionModel] = []
    @Published var sessionDuration: TimeInterval = 0
    @Published var sessionMinutes = 0
    @Published var sessionSeconds = 0
    @Published var currentView: AppView = .main

    let cameraService = CameraService()
    let visionService = VisionService()
    let storageService = StorageService.shared
    let alertViewModel = AlertViewModel()

    private var currentSessionId: String?
    private var sessionStartTime: Date?
    private var postureEvents: [PostureEvent] = []
    private var slouchBuffer: SlouchBuffer?
    private var userProfile: UserProfile?
    
    // Public accessor for user profile
    var userProfileName: String {
        return userProfile?.name ?? "User"
    }

    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    private var frameFrameCounter = 0

    init() {
        setupBindings()
        loadUserProfile()
        loadSessions()
    }

    private func setupBindings() {
        visionService.posePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] analysis in
                self?.processPoseAnalysis(analysis)
            }
            .store(in: &cancellables)
    }

    private func loadUserProfile() {
        do {
            userProfile = try storageService.loadUserProfile()
        } catch {
            userProfile = UserProfile(name: "User", sensitivity: "medium")
        }
    }

    func startSession() {
        currentSessionId = UUID().uuidString
        sessionStartTime = Date()
        sessionDuration = 0
        postureEvents = []

        let bufferTime = userProfile?.bufferTime ?? Constants.SLOUCH_BUFFER_TIME
        slouchBuffer = SlouchBuffer(bufferDuration: bufferTime)

        cameraService.startCapture()

        if let videoPath = storageService.getSessionVideoPath(for: currentSessionId ?? "") {
            cameraService.startRecording(to: videoPath)
        }

        isSessionActive = true
        startDurationTimer()

        // Subscribe to frames for vision processing
        cameraService.framePublisher
            .sink { [weak self] pixelBuffer in
                guard let self = self else { return }
                self.frameFrameCounter += 1
                if self.frameFrameCounter % Constants.FRAME_SKIP == 0 {
                    self.visionService.analyzeFrame(pixelBuffer)
                }
            }
            .store(in: &cancellables)
    }

    func stopSession() {
        isSessionActive = false
        timerCancellable?.cancel()
        cameraService.stopCapture()

        cameraService.stopRecording { [weak self] url in
            self?.finalizeSession(videoUrl: url)
        }
    }

    private func startDurationTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.sessionDuration += 1
                self.sessionMinutes = Int(self.sessionDuration) / 60
                self.sessionSeconds = Int(self.sessionDuration) % 60
            }
    }

    private func processPoseAnalysis(_ analysis: PoseAnalysis) {
        if analysis.isSlouching {
            slouchBuffer?.addSlouching()

            if slouchBuffer?.shouldAlert ?? false {
                triggerAlert(for: analysis)
            }
        } else {
            slouchBuffer?.reset()
        }
    }

    private func triggerAlert(for analysis: PoseAnalysis) {
        let timestamp = Date().timeIntervalSince(sessionStartTime ?? Date())
        let severity = analysis.slouchSeverity

        let event = PostureEvent(
            timestamp: timestamp,
            severity: severity,
            spineAngle: analysis.spineAngle,
            detectionConfidence: analysis.confidence
        )

        postureEvents.append(event)

        let alertSeverity: PostureAlert.AlertSeverity
        switch severity {
        case "mild":
            alertSeverity = .mild
        case "moderate":
            alertSeverity = .moderate
        default:
            alertSeverity = .severe
        }

        let userName = userProfile?.name ?? "User"
        alertViewModel.showAlert(for: userName, severity: alertSeverity)
    }

    private func finalizeSession(videoUrl: URL?) {
        guard let sessionId = currentSessionId,
              let startTime = sessionStartTime else { return }

        let endTime = Date()
        let videoPath = videoUrl?.path ?? storageService.getSessionVideoPath(for: sessionId)?.path ?? ""
        let metadataPath = storageService.getSessionMetadataPath(for: sessionId)?.path ?? ""

        let totalDuration = endTime.timeIntervalSince(startTime)
        // Estimate slouch duration: each event represents approximately the buffer time of slouching
        let estimatedSlouchDurationPerEvent = userProfile?.bufferTime ?? Constants.SLOUCH_BUFFER_TIME
        let estimatedSlouchDuration = Double(postureEvents.count) * estimatedSlouchDurationPerEvent
        let goodPosturePercentage = totalDuration > 0 ? max(0, min(100, ((totalDuration - estimatedSlouchDuration) / totalDuration) * 100)) : 100.0

        let session = SessionModel(
            id: sessionId,
            startTime: startTime,
            endTime: endTime,
            videoPath: videoPath,
            metadataPath: metadataPath,
            postureEvents: postureEvents,
            goodPosturePercentage: max(0, min(100, goodPosturePercentage))
        )

        do {
            try storageService.saveSession(session)
            print("Session saved: \(sessionId)")
        } catch {
            print("Error saving session: \(error)")
        }

        loadSessions()
    }

    func loadSessions() {
        allSessions = storageService.loadAllSessions()
    }

    func deleteSession(_ session: SessionModel) {
        do {
            try storageService.deleteSession(withId: session.id)
            loadSessions()
        } catch {
            print("Error deleting session: \(error)")
        }
    }
}

private class SlouchBuffer {
    let bufferDuration: TimeInterval
    private var slouchStartTime: Date?

    var shouldAlert: Bool {
        guard let startTime = slouchStartTime else { return false }
        return Date().timeIntervalSince(startTime) >= bufferDuration
    }

    init(bufferDuration: TimeInterval = Constants.SLOUCH_BUFFER_TIME) {
        self.bufferDuration = bufferDuration
    }

    func addSlouching() {
        if slouchStartTime == nil {
            slouchStartTime = Date()
        }
    }

    func reset() {
        slouchStartTime = nil
    }
}

