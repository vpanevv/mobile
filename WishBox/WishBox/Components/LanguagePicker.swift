import SwiftUI
import UIKit

struct LanguagePicker: View {
    @Binding var selected: WishLanguage

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(WishLanguage.allCases) { language in
                    let isSelected = selected == language
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                            selected = language
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(language.flag)
                                .font(.system(size: 13))
                            Text(language.label)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        }
                        .foregroundStyle(isSelected ? Color.neonViolet : .white.opacity(0.45))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            isSelected
                                ? Color.neonViolet.opacity(0.10)
                                : Color.white.opacity(0.04)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected
                                        ? Color.neonViolet.opacity(0.60)
                                        : Color.white.opacity(0.07),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isSelected ? Color.neonViolet.opacity(0.22) : .clear,
                            radius: 8
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
