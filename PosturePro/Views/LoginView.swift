import SwiftUI
import Combine
import AppKit

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    let onComplete: (() -> Void)?
    
    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Welcome to PostureApp")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Let's set up your profile")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Name", systemImage: "person.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    TextField("Enter your name", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Detection Sensitivity", systemImage: "slider.horizontal.3")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Picker("Sensitivity", selection: $viewModel.sensitivity) {
                        Text("Low (relaxed)").tag("low")
                        Text("Medium (balanced)").tag("medium")
                        Text("High (strict)").tag("high")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            Button(action: completeSetup) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Start Monitoring")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.name.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(viewModel.name.isEmpty)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }

    private func completeSetup() {
        let profile = UserProfile(
            name: viewModel.name,
            email: nil,
            sensitivity: viewModel.sensitivity
        )

        do {
            try StorageService.shared.saveUserProfile(profile)
            UserDefaults.standard.set(true, forKey: "hasLoggedIn")
            onComplete?()
        } catch {
            print("Error saving profile: \(error)")
        }
    }
}

class LoginViewModel: ObservableObject {
    @Published var name = ""
    @Published var sensitivity = "medium"
}

#Preview {
    LoginView()
        .environmentObject(SessionManager())
}

