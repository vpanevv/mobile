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
