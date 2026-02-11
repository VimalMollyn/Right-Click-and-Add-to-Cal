import AppKit
import SwiftUI

@MainActor
final class ServiceProvider: NSObject {
    private let geminiService = GeminiService()
    private let calendarService = CalendarService()
    private var previewWindow: NSWindow?

    @objc func handleSelectedText(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let text = pboard.string(forType: .string), !text.isEmpty else {
            error.pointee = "No text was selected." as NSString
            return
        }

        showLoadingWindow()

        Task {
            do {
                let event = try await geminiService.parseEvent(from: text)
                showPreviewWindow(event: event)
            } catch {
                showErrorWindow(message: error.localizedDescription)
            }
        }
    }

    private func showLoadingWindow() {
        let window = createWindow(title: "Add to Calendar")
        let hostingView = NSHostingView(rootView: LoadingView())
        window.contentView = hostingView
        hostingView.frame = window.contentView!.bounds

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        previewWindow = window
    }

    private func showPreviewWindow(event: CalendarEvent) {
        let view = EventPreviewView(
            event: event,
            onAdd: { [weak self] finalEvent in
                self?.addToCalendar(finalEvent)
            },
            onCancel: { [weak self] in
                self?.closeWindow()
            }
        )

        if let window = previewWindow {
            let hostingView = NSHostingView(rootView: view)
            window.contentView = hostingView
            window.title = "Add to Calendar"
            let size = hostingView.fittingSize
            window.setContentSize(size)
            window.center()
        } else {
            let window = createWindow(title: "Add to Calendar")
            let hostingView = NSHostingView(rootView: view)
            window.contentView = hostingView
            let size = hostingView.fittingSize
            window.setContentSize(size)
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            previewWindow = window
        }
    }

    private func showErrorWindow(message: String) {
        let view = ErrorView(message: message, onDismiss: { [weak self] in
            self?.closeWindow()
        })

        if let window = previewWindow {
            let hostingView = NSHostingView(rootView: view)
            window.contentView = hostingView
            let size = hostingView.fittingSize
            window.setContentSize(size)
            window.center()
        } else {
            let window = createWindow(title: "Error")
            let hostingView = NSHostingView(rootView: view)
            window.contentView = hostingView
            let size = hostingView.fittingSize
            window.setContentSize(size)
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            previewWindow = window
        }
    }

    private func addToCalendar(_ event: CalendarEvent) {
        Task {
            do {
                try await calendarService.addEvent(event)
                closeWindow()
            } catch {
                showErrorWindow(message: error.localizedDescription)
            }
        }
    }

    private func showSuccessAndClose() {
        if let window = previewWindow {
            let successView = VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.green)
                Text("Event added to Calendar!")
                    .font(.headline)
            }
            .padding(30)
            .frame(width: 300)

            let hostingView = NSHostingView(rootView: successView)
            window.contentView = hostingView
            let size = hostingView.fittingSize
            window.setContentSize(size)
            window.center()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.closeWindow()
            }
        }
    }

    private func closeWindow() {
        previewWindow?.close()
        previewWindow = nil
    }

    private func createWindow(title: String) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.level = .floating
        window.isReleasedWhenClosed = false
        return window
    }
}
