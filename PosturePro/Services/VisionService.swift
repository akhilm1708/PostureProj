import Vision
import CoreGraphics
import Combine

class VisionService: ObservableObject {
    @Published var currentPose: PoseAnalysis?
    private let processingQueue = DispatchQueue(label: "com.postureapp.vision")
    var posePublisher = PassthroughSubject<PoseAnalysis, Never>()

    func analyzeFrame(_ pixelBuffer: CVPixelBuffer) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }

            let request = VNDetectHumanBodyPoseRequest()
            // Use default revision (revision 1) for macOS compatibility

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

            do {
                try handler.perform([request])

                guard let observations = request.results as? [VNHumanBodyPoseObservation],
                      let observation = observations.first else {
                    return
                }

                let analysis = self.processPose(observation)
                DispatchQueue.main.async {
                    self.currentPose = analysis
                    self.posePublisher.send(analysis)
                }
            } catch {
                print("Vision error: \(error)")
            }
        }
    }

    private func processPose(_ observation: VNHumanBodyPoseObservation) -> PoseAnalysis {
        let leftShoulder = try? observation.recognizedPoint(.leftShoulder)
        let rightShoulder = try? observation.recognizedPoint(.rightShoulder)
        let neck = try? observation.recognizedPoint(.neck)
        let nose = try? observation.recognizedPoint(.nose)

        var spineAngle: Double = 0
        var headForwardDistance: Double = 0
        var shoulderAsymmetry: Double = 0
        var confidence: Double = 0

        if let neck = neck, let nose = nose,
           let leftShoul = leftShoulder, let rightShoul = rightShoulder {

            let shoulderMidpoint = CGPoint(
                x: (leftShoul.location.x + rightShoul.location.x) / 2,
                y: (leftShoul.location.y + rightShoul.location.y) / 2
            )

            let neckToNose = CGPoint(
                x: nose.location.x - neck.location.x,
                y: nose.location.y - neck.location.y
            )

            let neckToShoulder = CGPoint(
                x: shoulderMidpoint.x - neck.location.x,
                y: shoulderMidpoint.y - neck.location.y
            )

            spineAngle = calculateAngle(from: neckToShoulder, to: neckToNose)
            confidence = (Double(neck.confidence) + Double(nose.confidence) + Double(leftShoul.confidence) + Double(rightShoul.confidence)) / 4.0
        }

        if let nose = nose, let neck = neck {
            headForwardDistance = distance(from: neck.location, to: nose.location)
        }

        if let leftShoul = leftShoulder, let rightShoul = rightShoulder {
            shoulderAsymmetry = abs(leftShoul.location.y - rightShoul.location.y)
        }

        return PoseAnalysis(
            spineAngle: spineAngle,
            headForwardDistance: headForwardDistance,
            shoulderAsymmetry: shoulderAsymmetry,
            confidence: confidence
        )
    }

    private func calculateAngle(from: CGPoint, to: CGPoint) -> Double {
        // Calculate angle between two vectors using dot product
        let dotProduct = from.x * to.x + from.y * to.y
        let magnitudeFrom = sqrt(from.x * from.x + from.y * from.y)
        let magnitudeTo = sqrt(to.x * to.x + to.y * to.y)
        
        guard magnitudeFrom > 0 && magnitudeTo > 0 else { return 0 }
        
        let cosAngle = dotProduct / (magnitudeFrom * magnitudeTo)
        let clampedCos = max(-1.0, min(1.0, cosAngle)) // Clamp to avoid NaN
        let angleRadians = acos(clampedCos)
        let angleDegrees = angleRadians * 180.0 / Double.pi
        return angleDegrees
    }

    private func distance(from: CGPoint, to: CGPoint) -> Double {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return sqrt(dx * dx + dy * dy)
    }
}

