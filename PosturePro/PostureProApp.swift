import SwiftUI
import AppKit

@main
struct PostureProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var sessionManager = SessionManager()

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var sessionManager = SessionManager()
    var historyWindow: NSWindow?
    var loginWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if !StorageService.shared.userProfileExists() {
            showLoginWindow()
        } else {
            setupMenuBar()
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "📍"
        }

        let menu = NSMenu()

        let sessionTitle = sessionManager.isSessionActive ? "Stop Session" : "Start Session"
        let sessionItem = NSMenuItem(title: sessionTitle, action: #selector(toggleSession), keyEquivalent: "")
        menu.addItem(sessionItem)

        menu.addItem(NSMenuItem.separator())

        let historyItem = NSMenuItem(title: "View History", action: #selector(showHistory), keyEquivalent: "h")
        menu.addItem(historyItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit PostureApp", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)

        menu.items.forEach { $0.target = self }
        statusItem?.menu = menu
    }

    private func showLoginWindow() {
        let loginView = LoginView(onComplete: { [weak self] in
            self?.loginWindow?.close()
            self?.loginWindow = nil
            self?.setupMenuBar()
        }).environmentObject(sessionManager)
        
        let hosting = NSHostingView(rootView: loginView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "PostureApp – Setup"
        window.contentView = hosting
        window.makeKeyAndOrderFront(nil)
        window.delegate = self
        loginWindow = window
    }

    @objc private func toggleSession() {
        if sessionManager.isSessionActive {
            sessionManager.stopSession()
        } else {
            sessionManager.startSession()
        }
        setupMenuBar()
    }

    @objc private func showHistory() {
        if historyWindow == nil {
            let hosting = NSHostingView(rootView: SessionLibraryView().environmentObject(sessionManager))
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "PostureApp – Session History"
            window.contentView = hosting
            window.makeKeyAndOrderFront(nil)
            window.delegate = self
            historyWindow = window
        } else {
            historyWindow?.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == historyWindow {
            historyWindow = nil
        }
        if notification.object as? NSWindow == loginWindow {
            loginWindow = nil
        }
    }
}
