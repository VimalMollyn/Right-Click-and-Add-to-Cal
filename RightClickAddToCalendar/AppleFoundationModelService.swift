import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(macOS 26.0, *)
final class AppleFoundationModelService: EventParser {
    @Generable
    struct ParsedEvent {
        @Guide(description: "Short, descriptive event title")
        let title: String

        @Guide(description: "Start date and time in ISO 8601 format with NO timezone offset, e.g. '2025-03-15T14:00:00'. Must already be converted to the user's local timezone.")
        let startDate: String

        @Guide(description: "End date and time in ISO 8601 format with NO timezone offset. If no end is specified, set to one hour after start.")
        let endDate: String

        @Guide(description: "Location of the event, or empty string if none is mentioned.")
        let location: String

        @Guide(description: "Extra details, including any URLs or links found in the source text. Empty string if none.")
        let notes: String

        @Guide(description: "True if the event is all-day with no specific time.")
        let isAllDay: Bool
    }

    func parseEvent(from text: String) async throws -> CalendarEvent {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw AppleFoundationModelError.unavailable(model.availability)
        }

        let now = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss EEEE"
        df.locale = Locale(identifier: "en_US_POSIX")
        let currentDateStr = df.string(from: now)
        let tzName = TimeZone.current.identifier
        let tzAbbrev = TimeZone.current.abbreviation() ?? "UTC"

        let instructions = """
        You extract calendar event details from arbitrary text.

        The current date and time is \(currentDateStr).
        The user's local timezone is \(tzName) (\(tzAbbrev)).

        Rules:
        - Convert all times into the user's local timezone (\(tzAbbrev)). For example, "16:00 GMT" for a user in EST becomes "11:00".
        - Return all dates in ISO 8601 form with NO timezone offset suffix.
        - If only a date is given with no time, set isAllDay to true and use T00:00:00 for both start and end.
        - If the year is not specified, assume the current or next occurrence.
        - If no end time is specified, set the end one hour after the start.
        - Preserve any URLs from the source text in the notes field.
        """

        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(
            to: "Extract the event from the following text:\n\n\(text)",
            generating: ParsedEvent.self
        )
        let parsed = response.content

        guard let start = Self.parseDate(parsed.startDate) else {
            throw AppleFoundationModelError.invalidDate(parsed.startDate)
        }
        let end = Self.parseDate(parsed.endDate) ?? start.addingTimeInterval(3600)

        return CalendarEvent(
            title: parsed.title,
            startDate: start,
            endDate: end,
            location: parsed.location.isEmpty ? nil : parsed.location,
            notes: parsed.notes.isEmpty ? nil : parsed.notes,
            isAllDay: parsed.isAllDay
        )
    }

    private static func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: trimmed) { return d }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        for format in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy-MM-dd"] {
            df.dateFormat = format
            if let d = df.date(from: trimmed) { return d }
        }
        return nil
    }
}

@available(macOS 26.0, *)
enum AppleFoundationModelError: LocalizedError {
    case unavailable(SystemLanguageModel.Availability)
    case invalidDate(String)

    var errorDescription: String? {
        switch self {
        case .unavailable(let availability):
            switch availability {
            case .available:
                return "Apple on-device model reports available but failed to initialize."
            case .unavailable(let reason):
                switch reason {
                case .deviceNotEligible:
                    return "This Mac is not eligible for Apple Intelligence on-device models."
                case .appleIntelligenceNotEnabled:
                    return "Apple Intelligence is not enabled. Turn it on in System Settings."
                case .modelNotReady:
                    return "Apple on-device model is downloading or not ready yet. Try again shortly."
                @unknown default:
                    return "Apple on-device model is unavailable."
                }
            @unknown default:
                return "Apple on-device model is unavailable."
            }
        case .invalidDate(let s):
            return "Could not parse date from on-device model output: \(s)"
        }
    }
}
