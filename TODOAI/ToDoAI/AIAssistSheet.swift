import SwiftUI
import StoreKit

struct AISuggestedTask: Identifiable {
    let id = UUID()
    let title: String
    let priority: TaskPriority
}

enum AIPlanner {
    static func suggestions(for focus: String, userName: String, now: Date = .now) -> [AISuggestedTask] {
        let fragments = actionableFragments(from: focus)
        let tasks = fragments
            .compactMap { taskTitle(from: $0) }
            .uniqued()

        if tasks.isEmpty {
            let hour = Calendar.autoupdatingCurrent.component(.hour, from: now)
            let warmupTitle = hour < 12 ? "Set the top 3 wins for the morning" : "Reset the plan for the rest of the day"

            return [
                AISuggestedTask(title: "\(warmupTitle), \(userName)", priority: .high),
                AISuggestedTask(title: "Clear one small task in under 10 minutes", priority: .quick),
                AISuggestedTask(title: "Review progress before the day ends", priority: .important),
            ]
        }

        return tasks.prefix(3).enumerated().map { index, task in
            AISuggestedTask(title: task, priority: [TaskPriority.high, .important, .quick][min(index, 2)])
        }
    }

    static func actionableFragments(from focus: String) -> [String] {
        var text = focus.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let separators = ["\n", ".", ",", ";", " then ", " after that ", " also ", " plus ", " and "]
        for separator in separators {
            text = text.replacingOccurrences(of: separator, with: "|")
        }

        return text
            .split(separator: "|")
            .map { sanitizeFragment(String($0)) }
            .filter { !$0.isEmpty }
    }

    private static func sanitizeFragment(_ fragment: String) -> String {
        var text = fragment.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))

        let prefixes = [
            "today i have to ",
            "today i need to ",
            "today i want to ",
            "today i have ",
            "today i'm ",
            "today i am ",
            "tonight i have to ",
            "tonight i need to ",
            "tonight i want to ",
            "tonight i have ",
            "tonight i'm ",
            "tonight i am ",
            "i have to ",
            "i have an ",
            "i have a ",
            "i have ",
            "i need to ",
            "i want to ",
            "i should ",
            "i must ",
            "i'm on ",
            "i'm at ",
            "i'm going to ",
            "i'm ",
            "i am on ",
            "i am at ",
            "i am going to ",
            "i am ",
            "help me ",
            "can you help me ",
            "please ",
        ]

        var removedPrefix = true
        while removedPrefix {
            removedPrefix = false
            for prefix in prefixes where text.hasPrefix(prefix) {
                text.removeFirst(prefix.count)
                text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
                removedPrefix = true
            }
        }

        return text
    }

    private static func taskTitle(from fragment: String) -> String? {
        guard !fragment.isEmpty else { return nil }

        if let actionTask = actionTask(from: fragment) {
            return actionTask
        }

        if let communicationTask = communicationTask(from: fragment) {
            return communicationTask
        }

        if let eventTask = eventTask(from: fragment) {
            return eventTask
        }

        if let conciseNounPhrase = conciseNounPhrase(from: fragment) {
            return conciseNounPhrase
        }

        return nil
    }

    static func actionTask(from fragment: String) -> String? {
        if let videoTask = mediaTask(from: fragment) {
            return videoTask
        }

        let actionPrefixes: [(String, String)] = [
            ("answer ", "Answer"),
            ("finish ", "Finish"),
            ("review ", "Review"),
            ("prepare ", "Prepare"),
            ("practice ", "Practice"),
            ("watch ", "Watch"),
            ("plan ", "Plan"),
            ("book ", "Book"),
            ("buy ", "Buy"),
            ("call ", "Call"),
            ("schedule ", "Schedule"),
            ("send ", "Send"),
            ("reply to ", "Reply to"),
            ("clean ", "Clean"),
            ("organize ", "Organize"),
        ]

        for (prefix, action) in actionPrefixes where fragment.hasPrefix(prefix) {
            let target = cleanTarget(String(fragment.dropFirst(prefix.count)))
            guard !target.isEmpty else { return nil }
            return sentenceCase("\(action) \(target)")
        }

        if containsAny(["workout", "exercise", "gym", "run"], in: fragment) {
            let suffix = timeSuffix(in: fragment)
            return sentenceCase(["workout", suffix].compactMap { $0 }.joined(separator: " "))
        }

        return nil
    }

    static func communicationTask(from fragment: String) -> String? {
        guard containsAny(["email", "emails", "message", "messages", "inbox", "text", "texts"], in: fragment) else {
            return nil
        }

        if fragment.contains("client") {
            return "Reply to client messages"
        }

        return "Reply to messages"
    }

    private static func mediaTask(from fragment: String) -> String? {
        guard containsAny(["video", "videos", "film", "films", "highlight", "highlights"], in: fragment) else {
            return nil
        }

        let target: String
        if let forRange = fragment.range(of: "for ") {
            target = cleanTarget(String(fragment[forRange.upperBound...]))
        } else if let eventTarget = conciseNounPhrase(from: fragment, dropping: ["video", "videos", "film", "films", "highlight", "highlights", "watch"]) {
            target = eventTarget.lowercased()
        } else {
            target = ""
        }

        guard !target.isEmpty else { return nil }
        return sentenceCase("Watch videos for \(target)")
    }

    static func eventTask(from fragment: String) -> String? {
        let eventKeywords = [
            "game",
            "party",
            "meeting",
            "appointment",
            "class",
            "dinner",
            "lunch",
            "date",
            "exam",
            "interview",
            "trip",
            "flight",
            "practice",
            "training",
            "rehearsal",
            "presentation",
            "match",
        ]

        let words = tokens(from: fragment)

        for keyword in eventKeywords {
            guard let keywordIndex = words.firstIndex(of: keyword) else { continue }

            var components = leadingContext(before: keywordIndex, in: words)
            components.append(keyword)

            if let suffix = timeSuffix(in: fragment) {
                components.append(suffix)
            }

            let phrase = components.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !phrase.isEmpty {
                return sentenceCase(phrase)
            }
        }

        return nil
    }

    private static func cleanTarget(_ target: String) -> String {
        var text = target.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))

        let stopTokens = [" with ", " using ", " by ", " before ", " after ", " tonight", " today", " tomorrow", " this morning", " this afternoon"]
        for token in stopTokens {
            if let range = text.range(of: token) {
                text = String(text[..<range.lowerBound])
            }
        }

        let words = tokens(from: text).filter { !disposableWords.contains($0) }
        return words.joined(separator: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
    }

    private static func containsAny(_ values: [String], in text: String) -> Bool {
        values.contains { text.contains($0) }
    }

    static func conciseNounPhrase(from fragment: String, dropping extraDrops: Set<String> = []) -> String? {
        let suffix = timeSuffix(in: fragment)
        let dropWords = stopWords.union(disposableWords).union(extraDrops)
        let coreWords = tokens(from: fragment).filter { !dropWords.contains($0) }

        guard !coreWords.isEmpty else { return nil }

        let phraseWords = Array(coreWords.prefix(3))
        let phrase = phraseWords.joined(separator: " ")
        guard !phrase.isEmpty else { return nil }

        if let suffix {
            return sentenceCase("\(phrase) \(suffix)")
        }

        return sentenceCase(phrase)
    }

    private static func leadingContext(before index: Int, in words: [String]) -> [String] {
        guard index > 0 else { return [] }

        var context: [String] = []
        var pointer = index - 1

        while pointer >= 0 && context.count < 2 {
            let word = words[pointer]
            if stopWords.contains(word) || disposableWords.contains(word) {
                pointer -= 1
                continue
            }

            context.insert(word, at: 0)
            pointer -= 1
        }

        return context
    }

    private static func tokens(from text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private static func timeSuffix(in fragment: String) -> String? {
        if fragment.contains("tonight") {
            return "tonight"
        }
        if fragment.contains("tomorrow") {
            return "tomorrow"
        }
        if fragment.contains("this morning") {
            return "this morning"
        }
        if fragment.contains("this afternoon") {
            return "this afternoon"
        }

        return nil
    }

    private static let stopWords: Set<String> = [
        "a", "an", "the", "my", "your", "our", "their", "his", "her",
        "today", "tonight", "tomorrow", "this", "that",
        "have", "need", "want", "should", "must", "going", "go",
        "am", "im", "i", "to", "for", "on", "at", "in", "of",
    ]

    private static let disposableWords: Set<String> = [
        "important", "small", "big", "great", "nice", "special", "busy", "long", "real"
    ]

    private static func sentenceCase(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

struct AIAssistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptions: SmartAISubscriptionStore

    @State private var focus = ""
    @State private var suggestions: [AISuggestedTask] = []
    @State private var selectedMode: AIMode = .quick
    @State private var showingSmartAIPaywall = false
    @State private var isGenerating = false
    @State private var generationError: String?

    let userName: String
    let onAdd: ([AISuggestedTask]) -> Void

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 18) {
                        sheetHeader

                        Spacer(minLength: suggestions.isEmpty ? 0 : 8)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("AI Task Assist")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.black.opacity(0.86))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)

                            Text("Describe your day or goal, and ToDoAI will break it into tasks for today.")
                                .foregroundStyle(Color.black.opacity(0.64))
                                .multilineTextAlignment(.center)

                            aiModePicker

                            TextField(
                                "Example: finish the client proposal, answer messages, and go for a workout",
                                text: $focus,
                                axis: .vertical
                            )
                            .lineLimit(3...6)
                            .textInputAutocapitalization(.sentences)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            }
                            .foregroundStyle(Color.black.opacity(0.84))

                            if let generationError {
                                Text(generationError)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(Color.red.opacity(0.78))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button(action: generateSuggestions) {
                                Label(generateButtonTitle, systemImage: isGenerating ? "hourglass" : "sparkles")
                                    .font(.headline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                            .disabled(isGenerating || focus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .foregroundStyle(.black)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 0.86, green: 0.97, blue: 0.99),
                                        Color(red: 0.77, green: 0.93, blue: 1.0),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            }
                            .shadow(color: Color.cyan.opacity(0.18), radius: 16, y: 8)
                            .opacity(isGenerating || focus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.72 : 1)
                        }
                        .padding(22)
                        .background(sheetCardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                        }
                        .shadow(color: Color.white.opacity(0.24), radius: 18, y: 8)

                        if !suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Suggested tasks")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color.black.opacity(0.84))

                                ForEach(suggestions) { suggestion in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "sparkles")
                                            .foregroundStyle(.cyan)

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(suggestion.title)
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(Color.black.opacity(0.84))
                                            PriorityBadge(priority: suggestion.priority)
                                        }

                                        Spacer()
                                    }
                                }
                            }
                            .padding(22)
                            .background(sheetCardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                            }
                            .shadow(color: Color.white.opacity(0.24), radius: 18, y: 8)

                            Button(action: addSuggestedTasks) {
                                Text("Add All for Today")
                                    .font(.headline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.black)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 0.86, green: 0.97, blue: 0.99),
                                        Color(red: 0.77, green: 0.93, blue: 1.0),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: proxy.size.height - 40)
                    .padding(20)
                }
            }
            .background(AppBackground())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSmartAIPaywall) {
                SmartAIPaywallSheet(
                    onUnlocked: {
                        selectedMode = .smart
                    }
                )
            }
        }
    }

    private func generateSuggestions() {
        let trimmedFocus = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFocus.isEmpty else { return }

        if selectedMode == .smart && !subscriptions.hasSmartAIAccess {
            showingSmartAIPaywall = true
            return
        }

        suggestions = []
        generationError = nil
        isGenerating = true

        Task {
            do {
                let entitlementProof = selectedMode == .smart ? try await subscriptions.currentEntitlementProof() : nil
                let generated = try await AISuggestionService.suggestions(
                    for: trimmedFocus,
                    userName: userName,
                    mode: selectedMode,
                    entitlementProof: entitlementProof
                )

                await MainActor.run {
                    suggestions = generated
                    if generated.isEmpty {
                        generationError = "No suggestions were generated. Try adding more detail."
                    }
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    generationError = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }

    private func addSuggestedTasks() {
        guard !suggestions.isEmpty else { return }
        onAdd(suggestions)
        dismiss()
    }

    private var sheetHeader: some View {
        VStack(spacing: 10) {
            Label("AI Planner", systemImage: "sparkles")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.black.opacity(0.84))

            LiveClockHeader(style: .contrastOnLight)
        }
        .padding(22)
        .background(sheetCardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
        }
        .shadow(color: Color.white.opacity(0.24), radius: 18, y: 8)
    }

    private var aiModePicker: some View {
        HStack(spacing: 12) {
            ForEach(AIMode.allCases) { mode in
                Button {
                    if mode == .smart && !subscriptions.hasSmartAIAccess {
                        showingSmartAIPaywall = true
                        return
                    }

                    selectedMode = mode
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: mode.symbolName)
                                .foregroundStyle(mode == .smart ? Color.blue.opacity(0.84) : Color.cyan.opacity(0.88))

                            Text(mode.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.black.opacity(0.84))

                            if mode == .smart && !subscriptions.hasSmartAIAccess {
                                Text("PRO")
                                    .font(.caption2.weight(.black))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.92), in: Capsule())
                                    .foregroundStyle(.white)
                            }
                        }

                        Text(mode.subtitle)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.black.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(selectedMode == mode ? Color.white.opacity(0.92) : Color.white.opacity(0.58))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selectedMode == mode ? Color.black.opacity(0.14) : Color.black.opacity(0.07), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var generateButtonTitle: String {
        if isGenerating {
            return selectedMode == .smart ? "Planning with Smart AI..." : "Generating with Quick AI..."
        }

        return selectedMode == .smart ? "Expand Plan with Smart AI" : "Generate with Quick AI"
    }

    private var sheetCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 1.0, blue: 1.0),
                            Color(red: 0.89, green: 0.97, blue: 0.99),
                            Color(red: 0.97, green: 0.98, blue: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.cyan.opacity(0.16))
                .frame(width: 180, height: 180)
                .blur(radius: 18)
                .offset(x: -120, y: -90)

            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 22)
                .offset(x: 110, y: 80)
        }
    }
}

private struct SmartAIPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptions: SmartAISubscriptionStore

    @State private var isWorking = false

    let onUnlocked: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.cyan.opacity(0.24),
                                        Color.blue.opacity(0.22),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 94, height: 94)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(Color.black.opacity(0.84))
                    }

                    Text("Unlock Smart AI")
                        .font(.title2.weight(.black))
                        .foregroundStyle(Color.black.opacity(0.88))

                    Text("Quick AI stays free on device. Smart AI uses a premium cloud model to expand your day into sharper, better-planned tasks.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.black.opacity(0.62))
                }

                VStack(alignment: .leading, spacing: 14) {
                    paywallRow(symbol: "sparkles.rectangle.stack.fill", title: "Smarter planning", detail: "Turns events into prep tasks, timing tasks, and clean day structure.")
                    paywallRow(symbol: "lock.shield.fill", title: "Premium feature", detail: "Reserved for subscribers who want stronger AI than the free on-device mode.")
                    paywallRow(symbol: "server.rack", title: "API-backed", detail: "Ready for a real remote LLM integration instead of just local extraction.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                }

                Button {
                    purchaseSmartAI()
                } label: {
                    Text(primaryButtonTitle)
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .disabled(isWorking || subscriptions.purchaseState == .purchasing || subscriptions.purchaseState == .restoring)
                .foregroundStyle(.black)
                .background(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.84, green: 0.97, blue: 0.99),
                            Color(red: 0.73, green: 0.91, blue: 0.98),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                }

                Button("Restore Purchases") {
                    restorePurchases()
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.72))

                if let product = subscriptions.smartAIProduct {
                    Text("Subscription: \(product.displayName) • \(product.displayPrice)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.black.opacity(0.58))
                }

                if subscriptions.isLoadingProducts {
                    ProgressView()
                        .tint(.cyan)
                }

                if let statusMessage = subscriptions.statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.black.opacity(0.58))
                }

                Text("Smart AI now uses StoreKit 2 entitlements. Configure the subscription product in App Store Connect and add your OpenAI API settings to Info.plist.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.black.opacity(0.5))

                Spacer(minLength: 0)
            }
            .padding(24)
            .background(AppBackground())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Not now") {
                        dismiss()
                    }
                }
            }
            .task {
                await subscriptions.refresh()
            }
        }
    }

    private func paywallRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .foregroundStyle(.cyan)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.black.opacity(0.84))

                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Color.black.opacity(0.58))
            }
        }
    }

    private var primaryButtonTitle: String {
        if subscriptions.hasSmartAIAccess {
            return "Continue with Smart AI"
        }

        switch subscriptions.purchaseState {
        case .purchasing:
            return "Purchasing..."
        case .restoring:
            return "Restoring..."
        default:
            return "Unlock Smart AI"
        }
    }

    private func purchaseSmartAI() {
        if subscriptions.hasSmartAIAccess {
            onUnlocked()
            dismiss()
            return
        }

        isWorking = true

        Task {
            await subscriptions.purchaseSmartAI()

            await MainActor.run {
                isWorking = false
                if subscriptions.hasSmartAIAccess {
                    onUnlocked()
                    dismiss()
                }
            }
        }
    }

    private func restorePurchases() {
        isWorking = true

        Task {
            await subscriptions.restorePurchases()

            await MainActor.run {
                isWorking = false
                if subscriptions.hasSmartAIAccess {
                    onUnlocked()
                    dismiss()
                }
            }
        }
    }
}
