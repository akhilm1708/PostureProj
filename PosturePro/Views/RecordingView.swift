import SwiftUI
import AppKit

struct RecordingView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showCameraError = false

    var body: some View {
        ZStack {
            // Camera preview background
            CameraPreviewView(captureSession: sessionManager.cameraService.captureSession)
                .ignoresSafeArea()
            
            // UI overlay
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .opacity(sessionManager.isSessionActive ? 1.0 : 0.5)

                        Text("Session Recording")
                            .font(.headline)

                        Spacer()

                        Text(String(format: "%02d:%02d", sessionManager.sessionMinutes, sessionManager.sessionSeconds))
                            .font(.system(.title3, design: .monospaced))
                            .foregroundColor(.blue)
                    }

                    if let analysis = sessionManager.visionService.currentPose {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Spine Angle")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(String(format: "%.1f°", analysis.spineAngle))
                                    .font(.caption2)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Status")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(analysis.isSlouching ? "Slouching" : "Good Posture")
                                    .font(.caption2)
                                    .foregroundColor(analysis.isSlouching ? .orange : .green)
                            }

                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.85))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(formatDuration(sessionManager.sessionDuration))
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.85))
                .cornerRadius(8)

                Spacer()

                Button(action: {
                    sessionManager.stopSession()
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Session")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()

            // Alert overlay
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    if sessionManager.alertViewModel.isShowingAlert,
                       let alert = sessionManager.alertViewModel.currentAlert {
                        AlertPopupView(
                            alert: alert,
                            onDismiss: sessionManager.alertViewModel.dismissAlert
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(20)
            }
        }
        .alert("Camera Error", isPresented: $showCameraError) {
            Button("OK") { }
        } message: {
            if let error = sessionManager.cameraService.cameraError {
                Text(error.localizedDescription)
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    RecordingView()
        .environmentObject(SessionManager())
}

