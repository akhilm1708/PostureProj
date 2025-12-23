import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showingLoginView = !UserDefaults.standard.bool(forKey: "hasLoggedIn")

    var body: some View {
        if showingLoginView {
            LoginView()
                .onDisappear {
                    showingLoginView = false
                }
        } else {
            ZStack {
                if sessionManager.isSessionActive {
                    RecordingView()
                        .environmentObject(sessionManager)
                } else {
                    VStack(spacing: 20) {
                        Text("PostureApp")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Click the menu bar icon (top-right) to start monitoring your posture.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.windowBackgroundColor))
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager())
}
