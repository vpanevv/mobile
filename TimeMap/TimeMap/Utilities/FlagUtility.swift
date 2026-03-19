import Foundation

enum FlagUtility {
    static func emoji(for countryCode: String?) -> String {
        guard let countryCode, countryCode.count == 2 else {
            return "🌍"
        }

        let base: UInt32 = 127_397
        return countryCode.uppercased().unicodeScalars.compactMap { scalar in
            UnicodeScalar(base + scalar.value)
        }
        .map(String.init)
        .joined()
    }
}
