import Foundation

/// Talks to the WishlyAI Supabase Edge Function (`wishlyai-generate-wish`),
/// NOT to Anthropic directly. The Anthropic API key lives only as a server
/// secret, so it never ships in the app binary. The function builds the prompt
/// server-side and passes Anthropic's response (JSON or SSE) straight back,
/// so the parsing here is unchanged from talking to Anthropic directly.
struct AnthropicService {
    private let endpoint: URL
    private let anonKey: String

    init() {
        let dict: NSDictionary? = {
            guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else { return nil }
            return NSDictionary(contentsOfFile: path)
        }()

        // Both values are public client keys, safe to embed. Config.plist can
        // override them, but the hardcoded defaults keep the app working on a
        // fresh clone (Config.plist is gitignored).
        let defaultURL  = "https://rjhmmvsjtiomivkozcxk.supabase.co"
        let defaultAnon = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqaG1tdnNqdGlvbWl2a296Y3hrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MjQwNDcsImV4cCI6MjA5MzIwMDA0N30.-VOEUBTJV1gdtGi2LNqTtdje0HlJfC6LPjrWoUO6upA"

        let baseURL = (dict?["SUPABASE_URL"] as? String) ?? defaultURL
        self.anonKey = (dict?["SUPABASE_ANON_KEY"] as? String) ?? defaultAnon
        self.endpoint = URL(string: baseURL + "/functions/v1/wishlyai-generate-wish")!
    }

    // MARK: - Request payload sent to the proxy (structured, not raw prompts)

    private struct ProxyRequest: Encodable {
        let occasion: String       // HolidayType.rawValue
        let name: String?
        let parentName: String?
        let babyName: String?
        let partner1Name: String?
        let partner2Name: String?
        let language: String       // WishLanguage.rawValue
        let tone: Int              // WishTone.rawValue
        let length: String         // WishLength.rawValue
        let stream: Bool
    }

    // Anthropic's response shapes (passed through verbatim by the function)
    private struct APIResponse: Decodable {
        let content: [ContentBlock]
        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
    }
    private struct APIErrorBody: Decodable {
        let error: ErrorDetail
        struct ErrorDetail: Decodable { let message: String }
    }
    private struct StreamEvent: Decodable {
        let type: String
        let delta: Delta?
        let error: ErrorDetail?
        struct Delta: Decodable { let type: String?; let text: String? }
        struct ErrorDetail: Decodable { let message: String? }
    }

    // MARK: - Request builder

    private func makeRequest(
        occasion: HolidayType,
        name: String?, parentName: String?, babyName: String?,
        partner1Name: String?, partner2Name: String?,
        language: WishLanguage, tone: WishTone, length: WishLength,
        stream: Bool
    ) throws -> URLRequest {
        let payload = ProxyRequest(
            occasion: occasion.rawValue,
            name: name, parentName: parentName, babyName: babyName,
            partner1Name: partner1Name, partner2Name: partner2Name,
            language: language.rawValue, tone: tone.rawValue, length: length.rawValue,
            stream: stream
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        // Supabase function gate (verify_jwt) — the anon key is a public client key.
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(payload)
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
        let request = try makeRequest(
            occasion: occasion, name: name, parentName: parentName, babyName: babyName,
            partner1Name: partner1Name, partner2Name: partner2Name,
            language: language, tone: tone, length: length, stream: false
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw WishError.networkError("Invalid response")
        }
        guard http.statusCode == 200 else {
            if let apiError = try? JSONDecoder().decode(APIErrorBody.self, from: data) {
                throw WishError.apiError(apiError.error.message)
            }
            throw WishError.networkError("HTTP \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        guard let text = decoded.content.first?.text, !text.isEmpty else {
            throw WishError.emptyResponse
        }
        return text
    }

    // MARK: - Streaming generation

    /// Streams the wish token-by-token. Calls `onDelta` with each chunk and
    /// returns the full text when the stream finishes.
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
        let request = try makeRequest(
            occasion: occasion, name: name, parentName: parentName, babyName: babyName,
            partner1Name: partner1Name, partner2Name: partner2Name,
            language: language, tone: tone, length: length, stream: true
        )

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw WishError.networkError("Invalid response")
        }
        guard http.statusCode == 200 else {
            var body = ""
            for try await line in bytes.lines {
                body += line
                if body.count > 4000 { break }
            }
            if let data = body.data(using: .utf8),
               let apiError = try? JSONDecoder().decode(APIErrorBody.self, from: data) {
                throw WishError.apiError(apiError.error.message)
            }
            throw WishError.networkError("HTTP \(http.statusCode)")
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
