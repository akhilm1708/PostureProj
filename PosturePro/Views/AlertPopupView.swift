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
                        .lineLimit(2)

                    Text(alert.timestamp.formatted(date: .omitted, time: .standard))
                        .font(.system(size: 12, weight: .regular))
                        .opacity(0.7)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
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
            return Color(red: 0.99, green: 0.97, blue: 0.92)
        case .moderate:
            return Color(red: 1.0, green: 0.95, blue: 0.90)
        case .severe:
            return Color(red: 1.0, green: 0.92, blue: 0.92)
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

