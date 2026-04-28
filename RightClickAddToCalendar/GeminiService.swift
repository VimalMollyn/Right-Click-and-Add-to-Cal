import Foundation

final class GeminiService {
    private let apiKey: String

    init() {
        self.apiKey = GeminiService.loadAPIKey()
    }

    private static func loadAPIKey() -> String {
        // Try loading from bundle .env file
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil),
           let contents = try? String(contentsOfFile: envPath, encoding: .utf8) {
            for line in contents.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("GEMINI_API_KEY=") {
                    return String(trimmed.dropFirst("GEMINI_API_KEY=".count))
                }
            }
        }

        // Fallback: try loading from project directory .env
        let projectEnvPaths = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/RightClickAddToCalendar/.env"),
        ]
        for url in projectEnvPaths {
            if let contents = try? String(contentsOf: url, encoding: .utf8) {
                for line in contents.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("GEMINI_API_KEY=") {
                        return String(trimmed.dropFirst("GEMINI_API_KEY=".count))
                    }
                }
            }
        }

        return ""
    }

    func parseEvent(from text: String) async throws -> CalendarEvent {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-preview:generateContent?key=\(apiKey)")!

        let now = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss EEEE"
        df.locale = Locale(identifier: "en_US_POSIX")
        let currentDateStr = df.string(from: now)
        let localTZ = TimeZone.current
        let tzName = localTZ.identifier
        let tzAbbrev = localTZ.abbreviation() ?? "UTC"

        let prompt = """
        Extract calendar event details from the following text. The current date and time is \(currentDateStr).
        The user's local timezone is \(tzName) (\(tzAbbrev)).

        Return ONLY a JSON object with these fields:
        - "title": string (event title)
        - "start_date": string (ISO 8601 format, e.g. "2025-03-15T14:00:00")
        - "end_date": string (ISO 8601 format; if no end time specified, set 1 hour after start)
        - "location": string or null
        - "notes": string or null (any extra details, include any URLs or links found in the text)
        - "is_all_day": boolean

        IMPORTANT: Convert all times to the user's local timezone (\(tzAbbrev)). For example, if the text says "16:00 GMT" and the user is in EST, return "11:00" in EST.
        All returned dates/times must be in the user's local timezone with NO timezone offset suffix.
        If the year is not specified, assume the current or next occurrence.
        If only a date is given with no time, set is_all_day to true and use T00:00:00 for both start and end.

        Text:
        \(text)
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 1024,
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: body)
        }

        // Parse Gemini response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let textPart = parts.first?["text"] as? String else {
            throw GeminiError.parsingFailed
        }

        // Extract JSON from response (might be wrapped in markdown code blocks)
        let jsonString = extractJSON(from: textPart)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.parsingFailed
        }

        let decoder = JSONDecoder()
        let event = try decoder.decode(CalendarEvent.self, from: jsonData)
        return event
    }

    private func extractJSON(from text: String) -> String {
        // Remove markdown code block markers if present
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst("```json".count))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst("```".count))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast("```".count))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum GeminiError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key not found. Please add your key to the .env file."
        case .invalidResponse:
            return "Invalid response from Gemini API."
        case .apiError(let code, let message):
            return "Gemini API error (\(code)): \(message)"
        case .parsingFailed:
            return "Failed to parse event details from Gemini response."
        }
    }
}
