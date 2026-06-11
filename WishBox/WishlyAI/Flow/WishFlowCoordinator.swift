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
    private var generationTask: Task<Void, Never>?

    // ── Navigation ────────────────────────────────────────────────────
    enum Step: Hashable {
        case occasion, language, name, tone, length, generating, result
    }

    func goNext(_ step: Step) { path.append(step) }

    func reset() {
        cancelGeneration()
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

    /// Deep-link: pre-fill occasion + name (and optionally tone/length), jump directly to tone.
    func applyDeepLink(occasion: HolidayType, name: String, tone: WishTone? = nil, length: WishLength? = nil) {
        reset()
        self.occasion    = occasion
        self.name        = name
        self.includeName = !name.isEmpty
        if let tone   { self.tone = tone }
        if let length { self.length = length }
        path.append(Step.tone)
    }

    // ── Generation (streaming) ────────────────────────────────────────
    /// Kicks off a coordinator-owned streaming generation task. The wish text
    /// arrives token-by-token into `generatedWish`; `isGenerating` stays true
    /// until the stream completes. Owning the task here (not in a view) means
    /// navigation transitions can't cancel an in-flight generation.
    func startGeneration() {
        generationTask?.cancel()
        guard let occasion else {
            generationError = "No occasion selected"
            return
        }

        generatedWish   = nil
        generationError = nil
        isGenerating    = true

        let isNewBaby     = occasion == .newBaby
        let isWedding     = occasion == .wedding
        let isAnniversary = occasion == .anniversary

        // Anniversary: combine both partner names into a single "name" field so the
        // prompt becomes "Generate an anniversary wish for Maria and John."
        let anniversaryName: String? = {
            guard isAnniversary else { return nil }
            let a = name.trimmingCharacters(in: .whitespaces)
            let b = parentName.trimmingCharacters(in: .whitespaces)
            switch (a.isEmpty, b.isEmpty) {
            case (false, false): return "\(a) and \(b)"
            case (false, true):  return a
            case (true,  false): return b
            case (true,  true):  return nil
            }
        }()

        generationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let full = try await self.service.generateWishStreaming(
                    holidayType:  occasion.label,
                    occasion:     occasion,
                    name:         isNewBaby || isWedding ? nil
                                    : isAnniversary      ? anniversaryName
                                    : (self.includeName && !self.name.isEmpty) ? self.name : nil,
                    parentName:   isNewBaby ? (self.parentName.isEmpty ? nil : self.parentName) : nil,
                    babyName:     isNewBaby ? (self.babyName.isEmpty   ? nil : self.babyName)   : nil,
                    partner1Name: isWedding ? (self.name.isEmpty        ? nil : self.name)       : nil,
                    partner2Name: isWedding ? (self.parentName.isEmpty  ? nil : self.parentName) : nil,
                    language:     self.language,
                    tone:         self.tone,
                    length:       self.length
                ) { [weak self] delta in
                    guard let self else { return }
                    self.generatedWish = (self.generatedWish ?? "") + delta
                }

                guard !Task.isCancelled else { return }
                self.generatedWish = full
                self.isGenerating  = false
                WishQuota.shared.recordUse()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch is CancellationError {
                self.isGenerating = false
            } catch {
                guard !Task.isCancelled else { self.isGenerating = false; return }
                self.isGenerating    = false
                self.generationError = error.localizedDescription
            }
        }
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
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
        case .wedding, .anniversary:
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
