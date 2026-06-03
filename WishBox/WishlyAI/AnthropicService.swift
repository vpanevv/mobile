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

        let requestBody = APIRequest(
            model: model,
            max_tokens: 400,
            system: systemPrompt,
            messages: [.init(role: "user", content: userPrompt)]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(requestBody)

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
