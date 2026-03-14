import Foundation

enum AIMode: String, CaseIterable, Identifiable {
    case quick
    case smart

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quick:
            return "Quick AI"
        case .smart:
            return "Smart AI"
        }
    }

    var subtitle: String {
        switch self {
        case .quick:
            return "On-device extraction"
        case .smart:
            return "Expanded cloud planning"
        }
    }

    var symbolName: String {
        switch self {
        case .quick:
            return "bolt.circle.fill"
        case .smart:
            return "brain.head.profile"
        }
    }
}

enum AISuggestionService {
    static func suggestions(
        for focus: String,
        userName: String,
        mode: AIMode,
        now: Date = .now
    ) async throws -> [AISuggestedTask] {
        switch mode {
        case .quick:
            return AIPlanner.suggestions(for: focus, userName: userName, now: now)
        case .smart:
            return try await SmartAIProxyClient().suggestions(for: focus, userName: userName, now: now)
        }
    }
}

struct SmartAIProxyClient {
    func suggestions(for focus: String, userName: String, now: Date = .now) async throws -> [AISuggestedTask] {
        guard let proxyURL = AppConfiguration.smartAIProxyURL else {
            throw SmartAIProxyError.missingProxyURL
        }

        var request = URLRequest(url: proxyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder.todoAIEncoder.encode(
            SmartAIProxyRequest(
                note: focus,
                userName: userName,
                requestedAt: now,
                maxTasks: 5
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SmartAIProxyError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server response"
            throw SmartAIProxyError.serverError(message)
        }

        let payload = try JSONDecoder.todoAIDecoder.decode(SmartAIProxyResponse.self, from: data)
        let suggestions = payload.tasks
            .map {
                AISuggestedTask(
                    title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    priority: TaskPriority(apiValue: $0.priority)
                )
            }
            .filter { !$0.title.isEmpty }

        guard !suggestions.isEmpty else {
            throw SmartAIProxyError.emptySuggestions
        }

        return Array(suggestions.prefix(5))
    }
}

private struct SmartAIProxyRequest: Encodable {
    let note: String
    let userName: String
    let requestedAt: Date
    let maxTasks: Int
}

private struct SmartAIProxyResponse: Decodable {
    let tasks: [Task]

    struct Task: Decodable {
        let title: String
        let priority: String
    }
}

private enum SmartAIProxyError: LocalizedError {
    case missingProxyURL
    case invalidResponse
    case serverError(String)
    case emptySuggestions

    var errorDescription: String? {
        switch self {
        case .missingProxyURL:
            return "Smart AI proxy URL is missing in Info.plist."
        case .invalidResponse:
            return "Smart AI proxy returned an invalid response."
        case .serverError(let message):
            return "Smart AI proxy failed: \(message)"
        case .emptySuggestions:
            return "Smart AI proxy returned no usable tasks."
        }
    }
}

private extension JSONDecoder {
    static var todoAIDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension JSONEncoder {
    static var todoAIEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension TaskPriority {
    init(apiValue: String) {
        self = TaskPriority(rawValue: apiValue) ?? .important
    }
}
