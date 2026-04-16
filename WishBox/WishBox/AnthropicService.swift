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

    func generateWish(holidayType: String, name: String?, language: WishLanguage = .english) async throws -> String {
        let systemPrompt = "You are a warm, creative wish generator. Write heartfelt, joyful, and slightly poetic wishes. Keep them 2–4 sentences. Never use generic clichés. Vary style each time."

        let basePrompt: String
        if let name, !name.isEmpty {
            basePrompt = "Generate a \(holidayType) wish for \(name)."
        } else {
            basePrompt = "Generate a \(holidayType) wish."
        }
        let userPrompt = "\(basePrompt) \(language.promptInstruction)"

        let requestBody = APIRequest(
            model: model,
            max_tokens: 300,
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
