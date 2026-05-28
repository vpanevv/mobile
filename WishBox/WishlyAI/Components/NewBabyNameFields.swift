import SwiftUI
import UIKit

struct NewBabyNameFields: View {
    @Binding var parentName: String
    @Binding var babyName: String

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xc084fc).opacity(0.85))
                Text("Personalize (optional)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.85))
                Spacer()
            }

            // Parent name field
            nameField(
                icon: "person.fill",
                placeholder: "Parent's name (optional)",
                text: $parentName
            )

            // Baby name field
            nameField(
                icon: "figure.child",
                placeholder: "Baby's name (optional)",
                text: $babyName
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
