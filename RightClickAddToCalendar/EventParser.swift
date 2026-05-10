import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

protocol EventParser {
    func parseEvent(from text: String) async throws -> CalendarEvent
}

enum ModelProvider: String, CaseIterable {
    case gemini
    case apple

    var displayName: String {
        switch self {
        case .gemini: return "Gemini"
        case .apple: return "Apple Foundation Models"
        }
    }
}

enum ModelProviderStore {
    private static let defaultsKey = "modelProvider"

    static var current: ModelProvider {
        get {
            if let raw = UserDefaults.standard.string(forKey: defaultsKey),
               let provider = ModelProvider(rawValue: raw) {
                return provider
            }
            if let raw = EnvLoader.value(forKey: "MODEL_PROVIDER")?.lowercased(),
               let provider = ModelProvider(rawValue: raw) {
                return provider
            }
            return .gemini
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
            NotificationCenter.default.post(name: .modelProviderDidChange, object: newValue)
        }
    }

    static var isAppleAvailable: Bool {
        if #available(macOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        return false
    }
}

extension Notification.Name {
    static let modelProviderDidChange = Notification.Name("modelProviderDidChange")
}

enum EventParserFactory {
    static func make() -> EventParser {
        switch ModelProviderStore.current {
        case .apple:
            if #available(macOS 26.0, *) {
                return AppleFoundationModelService()
            }
            return GeminiService()
        case .gemini:
            return GeminiService()
        }
    }
}

enum EnvLoader {
    static func value(forKey key: String) -> String? {
        for url in candidatePaths() {
            guard let contents = try? String(contentsOf: url, encoding: .utf8) else { continue }
            for line in contents.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let prefix = "\(key)="
                if trimmed.hasPrefix(prefix) {
                    return String(trimmed.dropFirst(prefix.count))
                }
            }
        }
        return nil
    }

    private static func candidatePaths() -> [URL] {
        var urls: [URL] = []
        if let bundlePath = Bundle.main.path(forResource: ".env", ofType: nil) {
            urls.append(URL(fileURLWithPath: bundlePath))
        }
        urls.append(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/RightClickAddToCalendar/.env"))
        return urls
    }
}
