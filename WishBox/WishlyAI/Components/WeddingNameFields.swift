import SwiftUI
import UIKit

struct WeddingNameFields: View {
    @Binding var partner1Name: String
    @Binding var partner2Name: String

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "rings.wedding")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xc084fc).opacity(0.85))
                Text("Personalize (optional)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.85))
                Spacer()
            }

            // Partner 1
            nameField(
                icon: "person.fill",
                placeholder: "First partner's name (optional)",
                text: $partner1Name
            )

            // Partner 2
            nameField(
                icon: "person.fill",
                placeholder: "Second partner's name (optional)",
                text: $partner2Name
            )
        }
        .padding(18)
        .glassCard()
    }

    private func nameField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: 0xc084fc).opacity(0.7))
                .frame(width: 18)

            TextField(placeholder, text: text)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.primary)
                .tint(Color(hex: 0xc084fc))
                .autocapitalization(.words)
                .submitLabel(.done)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: 0xc084fc).opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: 0xc084fc).opacity(0.28), lineWidth: 1)
        )
    }
}
