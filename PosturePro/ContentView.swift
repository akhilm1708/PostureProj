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
                Group {
                    switch sessionManager.currentView {
                    case .main:
                        MainView()
                            .environmentObject(sessionManager)
                    case .recording:
                        RecordingView()
                            .environmentObject(sessionManager)
                    case .history:
                        SessionLibraryView()
                            .environmentObject(sessionManager)
                    }
                }
                .onChange(of: sessionManager.isSessionActive) { isActive in
                    if isActive {
                        sessionManager.currentView = .recording
                    } else if sessionManager.currentView == .recording {
                        sessionManager.currentView = .main
                    }
                }
                
                // Alert overlay (backup display in case window doesn't work)
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
        }
    }
}

struct MainView: View {
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("PosturePro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Monitor and improve your posture")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 40)
            
            Spacer()
            
            VStack(spacing: 16) {
                if sessionManager.isSessionActive {
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
                } else {
                    Button(action: {
                        sessionManager.startSession()
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Start Session")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                Button(action: {
                    sessionManager.currentView = .history
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("View History")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager())
}
