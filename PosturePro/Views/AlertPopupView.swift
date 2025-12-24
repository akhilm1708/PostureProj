import SwiftUI

struct AlertPopupView: View {
    let alert: PostureAlert
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(iconColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.message)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))  // Dark text for readability
                        .lineLimit(2)

                    Text(alert.timestamp.formatted(date: .omitted, time: .standard))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))  // Dark gray for timestamp
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))  // Dark gray for close button
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: 380)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }

    private var iconName: String {
        switch alert.severity {
        case .mild:
            return "exclamationmark.circle.fill"
        case .moderate:
            return "exclamationmark.triangle.fill"
        case .severe:
            return "exclamationmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch alert.severity {
        case .mild:
            return .yellow
        case .moderate:
            return .orange
        case .severe:
            return .red
        }
    }

    private var backgroundColor: Color {
        switch alert.severity {
        case .mild:
            return Color(red: 0.98, green: 0.95, blue: 0.85)  // Darker yellow background
        case .moderate:
            return Color(red: 0.98, green: 0.90, blue: 0.80)  // Darker orange background
        case .severe:
            return Color(red: 0.95, green: 0.85, blue: 0.85)  // Darker red background
        }
    }
}

#Preview {
    AlertPopupView(
        alert: PostureAlert(
            message: "Hey! Looks like you're slouching.",
            userName: "Arjun",
            severity: .mild,
            timestamp: Date()
        ),
        onDismiss: {}
    )
    .padding()
}

