import Foundation

enum CurrencyFormatter {
    static func string(fromMinor amountMinor: Int, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale(for: currencyCode)
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let majorAmount = Decimal(amountMinor) / 100
        return formatter.string(from: majorAmount as NSDecimalNumber) ?? "\(currencyCode) \(majorAmount)"
    }

    /// A compact, axis-friendly representation (e.g. "€1.2k", "$340").
    static func compactString(fromMinor amountMinor: Int, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale(for: currencyCode)
        formatter.maximumFractionDigits = 0

        let major = Double(amountMinor) / 100
        if abs(major) >= 1000 {
            formatter.maximumFractionDigits = 1
            let symbol = formatter.currencySymbol ?? ""
            let value = (major / 1000)
            let trimmed = value.formatted(.number.precision(.fractionLength(0...1)))
            return "\(symbol)\(trimmed)k"
        }

        return formatter.string(from: major as NSNumber) ?? "\(Int(major))"
    }

    static func minorUnits(from text: String) -> Int {
        let sanitized = text
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }

        guard !sanitized.isEmpty, let decimal = Decimal(string: sanitized) else {
            return 0
        }

        let multiplied = decimal * 100
        return NSDecimalNumber(decimal: multiplied).rounding(accordingToBehavior: nil).intValue
    }

    private static func locale(for currencyCode: String) -> Locale {
        switch currencyCode {
        case "USD":
            Locale(identifier: "en_US")
        default:
            Locale(identifier: "en_EU")
        }
    }
}
