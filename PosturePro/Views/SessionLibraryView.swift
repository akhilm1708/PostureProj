import SwiftUI
import AppKit

struct SessionLibraryView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedSession: SessionModel?
    @State private var sessions: [SessionModel] = []

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session History")
                        .font(.headline)
                    Text("\(sessions.count) sessions recorded")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))

                if sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)

                        Text("No Sessions Yet")
                            .font(.headline)

                        Text("Start a new session to begin monitoring your posture.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(sessions, selection: $selectedSession) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.formattedDate)
                                .font(.headline)

                            HStack(spacing: 12) {
                                Label(session.formattedDuration, systemImage: "clock")
                                    .font(.caption)

                                Label("\(Int(session.goodPosturePercentage))%", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)

                                Label("\(session.postureEvents.count)", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .tag(session)
                    }
                }
            }
            .onAppear {
                loadSessions()
            }
        } detail: {
            if let selected = selectedSession {
                SessionDetailView(session: selected, onDelete: deleteSession)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)

                    Text("Select a Session")
                        .font(.headline)

                    Text("Choose a session to view posture details.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func loadSessions() {
        sessions = sessionManager.allSessions
    }

    private func deleteSession(_ sessionId: String) {
        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            let session = sessions[index]
            sessionManager.deleteSession(session)
            sessions.remove(at: index)
        }
    }
}

struct SessionDetailView: View {
    let session: SessionModel
    let onDelete: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Details")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Duration:")
                    Spacer()
                    Text(session.formattedDuration)
                }

                HStack {
                    Text("Good Posture:")
                    Spacer()
                    Text("\(Int(session.goodPosturePercentage))%")
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Slouch Events:")
                    Spacer()
                    Text("\(session.postureEvents.count)")
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            if !session.postureEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Slouch Timeline")
                        .font(.subheadline)

                    List(session.postureEvents) { event in
                        HStack {
                            Text(event.formattedTime())
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Angle: \(Int(event.spineAngle))°")
                                .font(.caption)
                            statusBadge(for: event.severity)
                        }
                    }
                    .frame(height: 150)
                }
            }

            Spacer()

            HStack {
                Button {
                    openInFinder()
                } label: {
                    Label("Open in Finder", systemImage: "folder")
                }
                Spacer()
                Button(role: .destructive) {
                    onDelete(session.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .padding()
        }
        .padding()
    }

    @ViewBuilder
    private func statusBadge(for severity: String) -> some View {
        switch severity {
        case "mild":
            Text("Mild").font(.caption2).padding(4).background(Color.yellow.opacity(0.3)).cornerRadius(4)
        case "moderate":
            Text("Moderate").font(.caption2).padding(4).background(Color.orange.opacity(0.3)).cornerRadius(4)
        case "severe":
            Text("Severe").font(.caption2).padding(4).background(Color.red.opacity(0.3)).cornerRadius(4)
        default:
            Text("Unknown").font(.caption2)
        }
    }

    private func openInFinder() {
        NSWorkspace.shared.selectFile(session.videoPath, inFileViewerRootedAtPath: "")
    }
}

#Preview {
    SessionLibraryView()
        .environmentObject(SessionManager())
}

