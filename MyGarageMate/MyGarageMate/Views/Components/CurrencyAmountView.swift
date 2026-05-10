import SwiftUI

struct CurrencyAmountView: View {
    let amountMinor: Int
    let currencyCode: String
    var font: Font = .headline

    var body: some View {
        Text(CurrencyFormatter.string(fromMinor: amountMinor, currencyCode: currencyCode))
            .font(font)
            .monospacedDigit()
            .accessibilityLabel(CurrencyFormatter.string(fromMinor: amountMinor, currencyCode: currencyCode))
    }
}
