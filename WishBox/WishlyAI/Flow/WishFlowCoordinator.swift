import SwiftUI
import UIKit
import Combine

// MARK: - WishFlowCoordinator

@MainActor
final class WishFlowCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    // ── Wizard state ──────────────────────────────────────────────────
    @Published var occasion: HolidayType? = nil
    @Published var includeName: Bool = false
    @Published var name: String = ""        // Standard name; Wedding = partner1
    @Published var parentName: String = ""  // NewBaby = parent;  Wedding = partner2
    @Published var babyName: String = ""    // NewBaby only

    // ── Generation results ────────────────────────────────────────────
    @Published var generatedWish: String? = nil
    @Published var isGenerating: Bool = false
    @Published var generationError: String? = nil

    // ── Persisted prefs (shared key with old ViewModel) ───────────────
    @AppStorage("lastToneRaw")     var toneRaw:     Int    = WishTone.friendly.rawValue
    @AppStorage("lastLength")      var lengthRaw:   String = WishLength.medium.rawValue
    @AppStorage("lastLanguageRaw") var languageRaw: String = WishLanguage.english.rawValue

    var tone: WishTone {
        get { WishTone(rawValue: toneRaw) ?? .friendly }
        set { toneRaw = newValue.rawValue }
    }
    var length: WishLength {
        get { WishLength(rawValue: lengthRaw) ?? .medium }
        set { lengthRaw = newValue.rawValue }
    }
    var language: WishLanguage {
        get { WishLanguage(rawValue: languageRaw) ?? .english }
        set { languageRaw = newValue.rawValue }
    }

    private let service = AnthropicService()

    // ── Navigation ────────────────────────────────────────────────────
    enum Step: Hashable {
        case occasion, language, name, tone, length, generating, result
    }

    func goNext(_ step: Step) { path.append(step) }

    func reset() {
        path          = NavigationPath()
        occasion      = nil
        includeName   = false
        name          = ""
        parentName    = ""
        babyName      = ""
        generatedWish = nil
        generationError = nil
        isGenerating  = false
    }

    /// Deep-link: pre-fill occasion + name, jump directly to tone.
    func applyDeepLink(occasion: HolidayType, name: String) {
        reset()
        self.occasion    = occasion
        self.name        = name
        self.includeName = !name.isEmpty
        path.append(Step.tone)
    }

    // ── Generation ────────────────────────────────────────────────────
    /// Async; throws on API/network errors. Respects Task cancellation.
    func generate() async throws -> String {
        guard let occasion else { throw WishError.apiError("No occasion selected") }
        isGenerating    = true
        generationError = nil

        let isNewBaby = occasion == .newBaby
        let isWedding = occasion == .wedding

        return try await service.generateWish(
            holidayType:  occasion.label,
            occasion:     occasion,
            name:         (!isNewBaby && !isWedding && includeName && !name.isEmpty) ? name : nil,
            parentName:   isNewBaby ? (parentName.isEmpty ? nil : parentName) : nil,
            babyName:     isNewBaby ? (babyName.isEmpty   ? nil : babyName)   : nil,
            partner1Name: isWedding ? (name.isEmpty        ? nil : name)       : nil,
            partner2Name: isWedding ? (parentName.isEmpty  ? nil : parentName) : nil,
            language:     language,
            tone:         tone,
            length:       length
        )
    }

    // ── Display helpers ───────────────────────────────────────────────
    var recipientNameForDisplay: String? {
        guard let occasion else { return nil }
        switch occasion {
        case .newBaby:
            let p = parentName.trimmingCharacters(in: .whitespaces)
            let b = babyName.trimmingCharacters(in: .whitespaces)
            if !p.isEmpty && !b.isEmpty { return "\(p) & baby \(b)" }
            if !p.isEmpty { return p }
            if !b.isEmpty { return "baby \(b)" }
            return nil
        case .wedding:
            let a = name.trimmingCharacters(in: .whitespaces)
            let b = parentName.trimmingCharacters(in: .whitespaces)
            if !a.isEmpty && !b.isEmpty { return "\(a) & \(b)" }
            return a.isEmpty ? (b.isEmpty ? nil : b) : a
        default:
            return (includeName && !name.trimmingCharacters(in: .whitespaces).isEmpty) ? name : nil
        }
    }
}

// MARK: - Step helpers

extension WishFlowCoordinator.Step {
    var progressIndex: Int {
        switch self {
        case .occasion:   return 0
        case .language:   return 1
        case .name:       return 2
        case .tone:       return 3
        case .length:     return 4
        case .generating: return 5
        case .result:     return 6
        }
    }
}
