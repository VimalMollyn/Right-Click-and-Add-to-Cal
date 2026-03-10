import EventKit
import Foundation

final class CalendarService {
    private let eventStore = EKEventStore()

    func requestAccess() async throws -> Bool {
        if #available(macOS 14.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            return try await eventStore.requestAccess(to: .event)
        }
    }

    func addEvent(_ calendarEvent: CalendarEvent) async throws {
        let granted = try await requestAccess()
        guard granted else {
            throw CalendarError.accessDenied
        }

        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = calendarEvent.title
        ekEvent.startDate = calendarEvent.startDate
        ekEvent.endDate = calendarEvent.endDate
        ekEvent.isAllDay = calendarEvent.isAllDay
        ekEvent.location = calendarEvent.location
        let suffix = "\n\nAdded by RightClickAddToCalendar"
        ekEvent.notes = (calendarEvent.notes ?? "") + suffix
        ekEvent.calendar = eventStore.defaultCalendarForNewEvents

        try eventStore.save(ekEvent, span: .thisEvent)
    }
}

enum CalendarError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied. Please grant access in System Settings > Privacy & Security > Calendars."
        }
    }
}
