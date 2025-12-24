import SwiftUI
import AppKit
import Combine

@main
struct PostureProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
                .onAppear {
                    // Set the sessionManager reference in AppDelegate
                    appDelegate.sessionManager = sessionManager
                    // Update menu bar now that sessionManager is available
                    appDelegate.updateMenuBar()
                    // Set up observer for session state changes
                    appDelegate.observeSessionChanges(sessionManager: sessionManager)
                }
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var sessionManager: SessionManager?
    var loginWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set to regular app (shows in dock and allows windows)
        NSApp.setActivationPolicy(.regular)
        
        // Setup menu bar
        setupMenuBar()
        
        // Show login window if needed, otherwise main window will show automatically
        if !StorageService.shared.userProfileExists() {
            showLoginWindow()
        }
        
        // Activate app to bring windows to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func observeSessionChanges(sessionManager: SessionManager) {
        sessionManager.$isSessionActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBar()
            }
            .store(in: &cancellables)
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "📍"
        }
        
        updateMenuBar()
    }
    
    func updateMenuBar() {
        let menu = NSMenu()

        // Only add session-related items if sessionManager is available
        if let sessionManager = sessionManager {
            let sessionTitle = sessionManager.isSessionActive ? "Stop Session" : "Start Session"
            let sessionItem = NSMenuItem(title: sessionTitle, action: #selector(toggleSession), keyEquivalent: "")
            sessionItem.target = self
            menu.addItem(sessionItem)

            menu.addItem(NSMenuItem.separator())
        }

        let mainItem = NSMenuItem(title: "Main Screen", action: #selector(showMain), keyEquivalent: "m")
        mainItem.target = self
        menu.addItem(mainItem)

        let historyItem = NSMenuItem(title: "View History", action: #selector(showHistory), keyEquivalent: "h")
        historyItem.target = self
        menu.addItem(historyItem)

        menu.addItem(NSMenuItem.separator())
        
        let testAlertItem = NSMenuItem(title: "Test Alert", action: #selector(testAlert), keyEquivalent: "t")
        testAlertItem.target = self
        menu.addItem(testAlertItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit PostureApp", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func showLoginWindow() {
        guard let sessionManager = sessionManager else { return }
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
        guard let sessionManager = sessionManager else { return }
        if sessionManager.isSessionActive {
            sessionManager.stopSession()
        } else {
            sessionManager.startSession()
        }
        updateMenuBar()
    }

    @objc private func showHistory() {
        guard let sessionManager = sessionManager else { return }
        sessionManager.currentView = .history
        // Bring main window to front - try multiple ways to find the window
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }
    
    @objc private func showMain() {
        guard let sessionManager = sessionManager else { return }
        sessionManager.currentView = .main
        // Bring main window to front
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }
    
    @objc private func testAlert() {
        guard let sessionManager = sessionManager else { return }
        let userName = sessionManager.userProfileName
        sessionManager.alertViewModel.showAlert(for: userName, severity: .moderate)
        // Also bring window to front to see the alert
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == loginWindow {
            loginWindow = nil
        }
    }
}
