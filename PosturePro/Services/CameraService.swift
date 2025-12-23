import AVFoundation
import Combine
import CoreVideo

class CameraService: NSObject, ObservableObject {
    @Published var isRunning = false
    @Published var cameraError: Error?

    let captureSession = AVCaptureSession()
    private var videoOutput: AVCaptureVideoDataOutput?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var currentURL: URL?
    private let sessionQueue = DispatchQueue(label: "com.postureapp.camera.session")
    private var isConfigured = false
    private var configurationGroup = DispatchGroup()
    var framePublisher = PassthroughSubject<CVPixelBuffer, Never>()

    override init() {
        super.init()
        configurationGroup.enter()
        setupCamera()
    }

    private func setupCamera() {
        let group = configurationGroup
        sessionQueue.async { [weak self] in
            guard let self = self else {
                group.leave()
                return
            }

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            ) else {
                DispatchQueue.main.async {
                    self.cameraError = CameraError.noCameraFound
                }
                self.captureSession.commitConfiguration()
                self.isConfigured = true
                group.leave()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }
            } catch {
                DispatchQueue.main.async {
                    self.cameraError = error
                }
                self.captureSession.commitConfiguration()
                self.isConfigured = true
                group.leave()
                return
            }

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.postureapp.video"))
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)]

            if self.captureSession.canAddOutput(videoOutput) {
                self.captureSession.addOutput(videoOutput)
                self.videoOutput = videoOutput
            }

            let movieOutput = AVCaptureMovieFileOutput()
            if self.captureSession.canAddOutput(movieOutput) {
                self.captureSession.addOutput(movieOutput)
                self.movieFileOutput = movieOutput
            }

            self.captureSession.commitConfiguration()
            self.isConfigured = true
            group.leave()
        }
    }

    func startCapture() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Wait for configuration to complete
            self.configurationGroup.wait()
            
            guard !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }

    func stopCapture() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }

    func startRecording(to url: URL) {
        currentURL = url
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.movieFileOutput?.startRecording(to: url, recordingDelegate: self)
        }
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            self.movieFileOutput?.stopRecording()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion(self.currentURL)
            }
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        framePublisher.send(pixelBuffer)
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error = error {
            Task { @MainActor in
                self.cameraError = error
            }
        }
    }
}

enum CameraError: LocalizedError {
    case noCameraFound
    case permissionDenied
    case setupFailed

    var errorDescription: String? {
        switch self {
        case .noCameraFound:
            return "No camera found on this device"
        case .permissionDenied:
            return "Camera permission denied"
        case .setupFailed:
            return "Failed to setup camera"
        }
    }
}

