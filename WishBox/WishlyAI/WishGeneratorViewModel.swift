import SwiftUI
import UIKit
import Combine

@MainActor
final class WishGeneratorViewModel: ObservableObject {
    @Published var selectedHoliday: HolidayType = .birthday
    @Published var selectedLanguage: WishLanguage = .english
    @Published var includeName = false
    @Published var name = ""
    @Published var parentName = ""   // New Baby — parent
    @Published var babyName   = ""   // New Baby — baby
    @Published var generatedWish: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // Persisted selections (tone is now Int-backed; length stays String)
    @AppStorage("lastToneRaw") var selectedToneRaw:   Int    = WishTone.friendly.rawValue
    @AppStorage("lastLength")  var selectedLengthRaw: String = WishLength.medium.rawValue

    var selectedTone: WishTone {
        get { WishTone(rawValue: selectedToneRaw) ?? .friendly }
        set { selectedToneRaw = newValue.rawValue }
    }
    var selectedLength: WishLength {
        get { WishLength(rawValue: selectedLengthRaw) ?? .medium }
        set { selectedLengthRaw = newValue.rawValue }
    }

    private let service = AnthropicService()

    func generateWish() {
        guard !isLoading else { return }

        isLoading = true
        generatedWish = nil

        Task {
            do {
                let isNewBaby = selectedHoliday == .newBaby
                let wish = try await service.generateWish(
                    holidayType: selectedHoliday.label,
                    occasion:    selectedHoliday,
                    name:        (!isNewBaby && includeName) ? name : nil,
                    parentName:  isNewBaby ? parentName : nil,
                    babyName:    isNewBaby ? babyName   : nil,
                    language:    selectedLanguage,
                    tone:        selectedTone,
                    length:      selectedLength
                )
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                    generatedWish = wish
                }
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.error)
            }
            isLoading = false
        }
    }
}
