import Foundation

struct AnthropicService {
    private let apiKey: String
    private let model = "claude-sonnet-4-20250514"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["ANTHROPIC_API_KEY"] as? String else {
            fatalError("Missing Config.plist or ANTHROPIC_API_KEY")
        }
        self.apiKey = key
    }

    struct APIRequest: Encodable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]
        var stream: Bool = false

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct APIResponse: Decodable {
        let content: [ContentBlock]

        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
    }

    struct APIError: Decodable {
        let error: ErrorDetail

        struct ErrorDetail: Decodable {
            let message: String
        }
    }

    // SSE event frame for streaming responses
    private struct StreamEvent: Decodable {
        let type: String
        let delta: Delta?
        let error: ErrorDetail?

        struct Delta: Decodable {
            let type: String?
            let text: String?
        }
        struct ErrorDetail: Decodable {
            let message: String?
        }
    }

    // MARK: - Prompt building (shared by both paths)

    private func buildPrompts(
        holidayType: String,
        occasion: HolidayType,
        name: String?,
        parentName: String?,
        babyName: String?,
        partner1Name: String?,
        partner2Name: String?,
        language: WishLanguage,
        tone: WishTone,
        length: WishLength
    ) -> (system: String, user: String) {
        let systemPrompt = "You are WishlyAI, a creative wish generator. \(tone.apiInstruction) \(length.apiInstruction) Never use clichés like 'May your day be filled with joy'. Be original and specific. Return ONLY the wish text — no quotes, no labels, no extra formatting."

        // Occasion-specific guidance appended to the user prompt
        var occasionGuidance = ""
        if occasion == .valentinesDay {
            occasionGuidance = " This is a Valentine's Day message — romantic, affectionate, and warm. Adapt the level of romance to the chosen tone: Formal/Professional → a tasteful, warm note suitable for friends, family, or coworkers; Warm/Friendly → a sweet, sincere message; Playful/Funny → a flirty, lighthearted message with charm. Do not assume the recipient is a romantic partner unless the context makes it clear — keep the message versatile."
        }

        let basePrompt: String
        if occasion == .newBaby {
            let clause = newBabyClause(parent: parentName ?? "", baby: babyName ?? "")
            basePrompt = "Generate a new baby congratulations message. \(clause)"
        } else if occasion == .wedding {
            let clause = weddingClause(p1: partner1Name ?? "", p2: partner2Name ?? "")
            basePrompt = "Generate a wedding congratulations message. \(clause)"
        } else if let name, !name.isEmpty {
            basePrompt = "Generate a \(holidayType.lowercased()) wish for \(name)."
        } else {
            basePrompt = "Generate a \(holidayType.lowercased()) wish."
        }
        let userPrompt = "\(basePrompt)\(occasionGuidance) \(language.promptInstruction)"
        return (systemPrompt, userPrompt)
    }

    private func makeRequest(system: String, user: String, stream: Bool) throws -> URLRequest {
        let requestBody = APIRequest(
            model: model,
            max_tokens: 400,
            system: system,
            messages: [.init(role: "user", content: user)],
            stream: stream
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(requestBody)
        return request
    }

    // MARK: - One-shot generation

    func generateWish(
        holidayType: String,
        occasion: HolidayType = .birthday,
        name: String? = nil,
        parentName: String? = nil,
        babyName: String? = nil,
        partner1Name: String? = nil,
        partner2Name: String? = nil,
        language: WishLanguage = .english,
        tone: WishTone = .friendly,
        length: WishLength = .medium
    ) async throws -> String {
        let (system, user) = buildPrompts(
            holidayType: holidayType, occasion: occasion, name: name,
            parentName: parentName, babyName: babyName,
            partner1Name: partner1Name, partner2Name: partner2Name,
            language: language, tone: tone, length: length
        )
        let request = try makeRequest(system: system, user: user, stream: false)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WishError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                throw WishError.apiError(apiError.error.message)
            }
            throw WishError.networkError("HTTP \(httpResponse.statusCode)")
        }

        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)

        guard let text = apiResponse.content.first?.text, !text.isEmpty else {
            throw WishError.emptyResponse
        }

        return text
    }

    // MARK: - Streaming generation

    /// Streams the wish token-by-token. Calls `onDelta` with each new text chunk
    /// and returns the complete wish when the stream finishes.
    func generateWishStreaming(
        holidayType: String,
        occasion: HolidayType = .birthday,
        name: String? = nil,
        parentName: String? = nil,
        babyName: String? = nil,
        partner1Name: String? = nil,
        partner2Name: String? = nil,
        language: WishLanguage = .english,
        tone: WishTone = .friendly,
        length: WishLength = .medium,
        onDelta: @escaping (String) -> Void
    ) async throws -> String {
        let (system, user) = buildPrompts(
            holidayType: holidayType, occasion: occasion, name: name,
            parentName: parentName, babyName: babyName,
            partner1Name: partner1Name, partner2Name: partner2Name,
            language: language, tone: tone, length: length
        )
        let request = try makeRequest(system: system, user: user, stream: true)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WishError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            // Drain enough of the body to surface the API's error message
            var body = ""
            for try await line in bytes.lines {
                body += line
                if body.count > 4000 { break }
            }
            if let data = body.data(using: .utf8),
               let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                throw WishError.apiError(apiError.error.message)
            }
            throw WishError.networkError("HTTP \(httpResponse.statusCode)")
        }

        var full = ""
        let decoder = JSONDecoder()

        for try await line in bytes.lines {
            try Task.checkCancellation()
            guard line.hasPrefix("data:") else { continue }
            let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            guard !payload.isEmpty,
                  let data = payload.data(using: .utf8),
                  let event = try? decoder.decode(StreamEvent.self, from: data) else { continue }

            switch event.type {
            case "content_block_delta":
                if let text = event.delta?.text, !text.isEmpty {
                    full += text
                    onDelta(text)
                }
            case "error":
                throw WishError.apiError(event.error?.message ?? "Streaming error")
            default:
                break
            }
        }

        guard !full.isEmpty else { throw WishError.emptyResponse }
        return full
    }

    // MARK: - Occasion clauses

    private func weddingClause(p1: String, p2: String) -> String {
        let a = p1.trimmingCharacters(in: .whitespaces)
        let b = p2.trimmingCharacters(in: .whitespaces)
        switch (a.isEmpty, b.isEmpty) {
        case (false, false): return "Congratulate \(a) and \(b) on their wedding. Use both names naturally."
        case (false, true):  return "Congratulate \(a) on their wedding. Use the name \(a)."
        case (true,  false): return "Congratulate \(b) on their wedding. Use the name \(b)."
        case (true,  true):  return "Congratulate the couple on their wedding. No specific names — keep it warm and celebratory."
        }
    }

    private func newBabyClause(parent: String, baby: String) -> String {
        let p = parent.trimmingCharacters(in: .whitespaces)
        let b = baby.trimmingCharacters(in: .whitespaces)
        switch (p.isEmpty, b.isEmpty) {
        case (false, false): return "Congratulate \(p) on the arrival of their new baby \(b). Use both names naturally."
        case (false, true):  return "Congratulate \(p) on the arrival of their new baby. Use the parent's name \(p)."
        case (true,  false): return "Congratulate the family on the arrival of baby \(b). Use the baby's name \(b)."
        case (true,  true):  return "Congratulate the family on the arrival of their new baby. No specific names — keep it warm and general."
        }
    }
}

enum WishError: LocalizedError {
    case networkError(String)
    case apiError(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "Network error: \(msg)"
        case .apiError(let msg): return "API error: \(msg)"
        case .emptyResponse: return "No wish was generated. Please try again."
        }
    }
}
