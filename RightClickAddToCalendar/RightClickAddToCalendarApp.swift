import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let serviceProvider = ServiceProvider()
    private let modelMenu = NSMenu(title: "Model")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
        installMainMenu()
        focus()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        focus()
        return false
    }

    func applicationDidResignActive(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    private func focus() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func installMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(
            title: "Quit Add to Calendar",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let modelMenuItem = NSMenuItem(title: "Model", action: nil, keyEquivalent: "")
        modelMenu.delegate = self
        modelMenuItem.submenu = modelMenu
        mainMenu.addItem(modelMenuItem)

        NSApp.mainMenu = mainMenu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === modelMenu else { return }
        modelMenu.removeAllItems()
        let current = ModelProviderStore.current
        let appleAvailable = ModelProviderStore.isAppleAvailable

        for provider in ModelProvider.allCases {
            let item = NSMenuItem(
                title: provider.displayName,
                action: #selector(selectProvider(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = provider.rawValue
            item.state = (provider == current) ? .on : .off
            if provider == .apple && !appleAvailable {
                item.isEnabled = false
                item.toolTip = "Requires macOS 26 with Apple Intelligence enabled."
            }
            modelMenu.addItem(item)
        }
    }

    @objc private func selectProvider(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let provider = ModelProvider(rawValue: raw) else { return }
        ModelProviderStore.current = provider
    }
}
