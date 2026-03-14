import Foundation

enum AppConfiguration {
    static var smartAIProductID: String {
        stringValue(for: "TODOAI_SMART_AI_PRODUCT_ID") ?? "todoai.smartai.monthly"
    }

    static var smartAIProxyURL: URL? {
        if let value = stringValue(for: "TODOAI_SMART_AI_PROXY_URL"), let url = URL(string: value) {
            return url
        }

        return nil
    }

    private static func stringValue(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
