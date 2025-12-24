import SwiftUI
import AppKit

class AlertWindowManager: NSObject {
    static let shared = AlertWindowManager()
    
    private var alertWindow: NSWindow?
    private var isDismissing = false
    
    private override init() {
        super.init()
    }
    
    func showAlert(_ alert: PostureAlert, onDismiss: @escaping () -> Void) {
        // Dismiss any existing alert window first
        dismissAlert()
        
        // Reset dismissing flag
        isDismissing = false
        
        // Create the alert view - onDismiss will handle both view model and window cleanup
        // Don't call dismissAlert here to avoid double-dismissal
        let alertView = AlertPopupView(alert: alert, onDismiss: {
            // Only call the view model's dismiss - it will call AlertWindowManager.dismissAlert
            onDismiss()
        })
        
        // Get the main screen
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        
        // Calculate position at bottom-right of screen
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 120
        let padding: CGFloat = 20
        
        let x = screenRect.maxX - windowWidth - padding
        let y = screenRect.minY + padding
        
        let window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Create the hosting view
        let hosting = NSHostingView(rootView: alertView)
        hosting.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        hosting.autoresizingMask = [.width, .height]
        
        window.contentView = hosting
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        
        // Retain only the window - the window will retain the hosting view
        alertWindow = window
    }
    
    func dismissAlert() {
        // Prevent double-dismissal
        guard !isDismissing, let window = alertWindow else { return }
        
        isDismissing = true
        
        // Clear our reference first, then let window close naturally
        // This prevents windowWillClose from trying to clean up an already-cleaned window
        let windowToClose = window
        alertWindow = nil
        
        // Clear delegate to prevent windowWillClose callback
        windowToClose.delegate = nil
        
        // Close the window - it will handle releasing its contentView
        windowToClose.close()
        
        // Reset flag after a short delay to allow window cleanup to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isDismissing = false
        }
    }
}

extension AlertWindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Only clean up if this is our alert window and we haven't already dismissed it
        guard let window = notification.object as? NSWindow,
              window == alertWindow,
              !isDismissing else {
            return
        }
        
        // Window is closing naturally (e.g., user clicked X or system closed it)
        // Just clear our reference - don't try to manipulate the window
        isDismissing = true
        alertWindow = nil
        window.delegate = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isDismissing = false
        }
    }
}

