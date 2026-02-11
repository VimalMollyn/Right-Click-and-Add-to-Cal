import Foundation

struct CalendarEvent: Codable {
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var notes: String?
    var isAllDay: Bool

    enum CodingKeys: String, CodingKey {
        case title
        case startDate = "start_date"
        case endDate = "end_date"
        case location
        case notes
        case isAllDay = "is_all_day"
    }

    init(title: String, startDate: Date, endDate: Date, location: String? = nil, notes: String? = nil, isAllDay: Bool = false) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.isAllDay = isAllDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isAllDay = try container.decodeIfPresent(Bool.self, forKey: .isAllDay) ?? false

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        let startString = try container.decode(String.self, forKey: .startDate)
        let endString = try container.decode(String.self, forKey: .endDate)

        // Try ISO8601 first, then fall back to common formats
        if let start = dateFormatter.date(from: startString) {
            startDate = start
        } else if let start = CalendarEvent.parseFlexibleDate(startString) {
            startDate = start
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.startDate], debugDescription: "Cannot parse start_date: \(startString)"))
        }

        if let end = dateFormatter.date(from: endString) {
            endDate = end
        } else if let end = CalendarEvent.parseFlexibleDate(endString) {
            endDate = end
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.endDate], debugDescription: "Cannot parse end_date: \(endString)"))
        }
    }

    private static func parseFlexibleDate(_ string: String) -> Date? {
        let formatters: [String] = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        for format in formatters {
            df.dateFormat = format
            if let date = df.date(from: string) {
                return date
            }
        }
        return nil
    }
}
