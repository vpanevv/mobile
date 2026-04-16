import SwiftUI
import UIKit
import Combine

@MainActor
final class WishGeneratorViewModel: ObservableObject {
    @Published var selectedHoliday: HolidayType = .birthday
    @Published var selectedLanguage: WishLanguage = .english
    @Published var includeName = false
    @Published var name = ""
    @Published var generatedWish: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let service = AnthropicService()

    func generateWish() {
        guard !isLoading else { return }

        isLoading = true
        generatedWish = nil

        Task {
            do {
                let wish = try await service.generateWish(
                    holidayType: selectedHoliday.label,
                    name: includeName ? name : nil,
                    language: selectedLanguage
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
