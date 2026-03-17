import SwiftUI
import AuthenticationServices

struct HomeIntroView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var appearanceStore: AppearanceStore
    let onContinue: () -> Void

    @State private var logoIsVisible = false
    @State private var contentIsVisible = false
    @State private var pulse = false
    @State private var usernameLogin = ""
    @State private var authError: String?
    @State private var pendingAppleUserID: String?
    @State private var pendingAppleEmail: String?
    @State private var pendingUsername = ""
    @State private var pendingAge = ""
    @State private var showingAppleRegistration = false

    var body: some View {
        ZStack {
            IntroBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 32)

                VStack(spacing: 28) {
                    AILogoMark(isAnimating: pulse)
                        .scaleEffect(logoIsVisible ? 1 : 0.72)
                        .opacity(logoIsVisible ? 1 : 0)
                        .rotationEffect(.degrees(logoIsVisible ? 0 : -12))

                    VStack(spacing: 12) {
                        Text("TODO AI")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .tracking(4)
                            .foregroundStyle(primaryTitleColor)

                        Text("Plan smarter. Achieve more.")
                            .font(.headline.weight(.medium))
                            .foregroundStyle(secondaryTitleColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .offset(y: contentIsVisible ? 0 : 26)
                    .opacity(contentIsVisible ? 1 : 0)

                    appearanceToggle
                        .offset(y: contentIsVisible ? 0 : 22)
                        .opacity(contentIsVisible ? 1 : 0)

                    VStack(spacing: 14) {
                        if store.isAuthenticated {
                            Button(action: onContinue) {
                                HStack(spacing: 12) {
                                    Text("CONTINUE AS \(store.profile?.name.uppercased() ?? "USER")")
                                        .font(.headline.weight(.black))
                                        .tracking(1.2)

                                    Image(systemName: "arrow.right")
                                        .font(.headline.weight(.black))
                                }
                                .foregroundStyle(callToActionTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: buttonGradientColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
                                .overlay {
                                    Capsule()
                                        .stroke(buttonStrokeColor, lineWidth: 1.2)
                                }
                                .shadow(color: buttonShadowColor, radius: 22, y: 12)
                            }
                            .buttonStyle(.plain)
                        } else {
                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.email]
                            } onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                            .signInWithAppleButtonStyle(appearanceStore.appearance.isDark ? .white : .black)
                            .frame(height: 56)
                            .clipShape(Capsule())

                            VStack(spacing: 10) {
                                TextField("Log in with username", text: $usernameLogin)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                    .background(loginFieldBackgroundColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .foregroundStyle(loginPrimaryTextColor)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(loginFieldStrokeColor, lineWidth: 1)
                                    }

                                Button(action: signInWithUsername) {
                                    Text("Log In with Username")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(loginButtonTextColor)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .background(loginButtonBackgroundColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .disabled(usernameLogin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .opacity(usernameLogin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                            }

                            if let authError {
                                Text(authError)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(errorTextColor)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .offset(y: contentIsVisible ? 0 : 30)
                    .opacity(contentIsVisible ? 1 : 0)

                    Text("Your AI-powered daily buddy")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(footerTextColor)
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .opacity(contentIsVisible ? 1 : 0)
                }

                Spacer()

                Text("v1.0")
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: versionGradientColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: versionShadowColor, radius: 18, y: 6)
                    .padding(.bottom, 10)
                    .opacity(contentIsVisible ? 1 : 0)
            }
            .padding(.vertical, 44)
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.72)) {
                logoIsVisible = true
            }

            withAnimation(.spring(response: 0.82, dampingFraction: 0.84).delay(0.16)) {
                contentIsVisible = true
            }

            pulse = true
        }
        .sheet(isPresented: $showingAppleRegistration) {
            NavigationStack {
                VStack(spacing: 18) {
                    Text("Finish Your Account")
                        .font(.title2.weight(.black))
                        .foregroundStyle(Color.black.opacity(0.86))

                    if let pendingAppleEmail {
                        Text(pendingAppleEmail)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.black.opacity(0.58))
                    }

                    TextField("Username", text: $pendingUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    TextField("Age", text: $pendingAge)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    Button(action: finishAppleRegistration) {
                        Text("Create Account")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.black)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 0.84, green: 0.96, blue: 1.0),
                                        Color(red: 0.68, green: 0.91, blue: 0.99),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)

                    if let authError {
                        Text(authError)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.red.opacity(0.78))
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
                .padding(24)
                .background(AppBackground())
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            showingAppleRegistration = false
                            pendingAppleUserID = nil
                            pendingAppleEmail = nil
                        }
                    }
                }
            }
        }
    }

    private var appearanceToggle: some View {
        HStack(spacing: 10) {
            ForEach(AppAppearance.allCases, id: \.rawValue) { appearance in
                Button {
                    appearanceStore.appearance = appearance
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: appearance.symbolName)
                            .font(.subheadline.weight(.bold))

                        Text(appearance.title)
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(toggleTextColor(active: appearanceStore.appearance == appearance))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(minWidth: 110)
                    .background(
                        Capsule()
                            .fill(toggleBackgroundColor(active: appearanceStore.appearance == appearance))
                    )
                    .overlay {
                        Capsule()
                            .stroke(toggleStrokeColor(active: appearanceStore.appearance == appearance), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(toggleContainerColor, in: Capsule())
    }

    private var loginFieldBackgroundColor: Color {
        appearanceStore.appearance.isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.82)
    }

    private var loginFieldStrokeColor: Color {
        appearanceStore.appearance.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    private var loginPrimaryTextColor: Color {
        appearanceStore.appearance.isDark ? .white : Color.black.opacity(0.84)
    }

    private var loginButtonBackgroundColor: Color {
        appearanceStore.appearance.isDark ? Color.white.opacity(0.92) : Color.black.opacity(0.88)
    }

    private var loginButtonTextColor: Color {
        appearanceStore.appearance.isDark ? .black : .white
    }

    private var errorTextColor: Color {
        appearanceStore.appearance.isDark ? Color.red.opacity(0.86) : Color.red.opacity(0.74)
    }

    private var primaryTitleColor: Color {
        appearanceStore.appearance.isDark ? .white : Color.black.opacity(0.9)
    }

    private var secondaryTitleColor: Color {
        appearanceStore.appearance.isDark ? .white.opacity(0.72) : Color.black.opacity(0.62)
    }

    private var callToActionTextColor: Color {
        Color.black.opacity(0.88)
    }

    private var buttonGradientColors: [Color] {
        appearanceStore.appearance.isDark ? [
            Color.white,
            Color(red: 0.67, green: 0.98, blue: 0.96),
            Color(red: 0.42, green: 0.95, blue: 0.99),
        ] : [
            Color.white,
            Color(red: 0.84, green: 0.96, blue: 1.0),
            Color(red: 0.68, green: 0.91, blue: 0.99),
        ]
    }

    private var buttonStrokeColor: Color {
        appearanceStore.appearance.isDark ? Color.white.opacity(0.65) : Color.black.opacity(0.08)
    }

    private var buttonShadowColor: Color {
        appearanceStore.appearance.isDark ? Color.cyan.opacity(0.42) : Color.cyan.opacity(0.22)
    }

    private var footerTextColor: Color {
        appearanceStore.appearance.isDark ? .white.opacity(0.5) : Color.black.opacity(0.48)
    }

    private var versionGradientColors: [Color] {
        appearanceStore.appearance.isDark ? [
            Color.white.opacity(0.92),
            Color.cyan.opacity(0.95),
        ] : [
            Color.black.opacity(0.86),
            Color.cyan.opacity(0.88),
        ]
    }

    private var versionShadowColor: Color {
        appearanceStore.appearance.isDark ? Color.cyan.opacity(0.35) : Color.cyan.opacity(0.18)
    }

    private var toggleContainerColor: Color {
        appearanceStore.appearance.isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.6)
    }

    private func toggleBackgroundColor(active: Bool) -> Color {
        if active {
            return appearanceStore.appearance.isDark ? Color.white.opacity(0.94) : Color.white.opacity(0.94)
        }

        return appearanceStore.appearance.isDark ? Color.white.opacity(0.06) : Color.white.opacity(0.28)
    }

    private func toggleTextColor(active: Bool) -> Color {
        if active {
            return Color.black.opacity(0.86)
        }

        return appearanceStore.appearance.isDark ? .white.opacity(0.76) : Color.black.opacity(0.64)
    }

    private func toggleStrokeColor(active: Bool) -> Color {
        if active {
            return appearanceStore.appearance.isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.08)
        }

        return appearanceStore.appearance.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        authError = nil

        guard case .success(let authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authError = "Apple sign-in failed. Try again."
            return
        }

        if store.signInWithApple(userID: credential.user, email: credential.email) {
            onContinue()
            return
        }

        guard let email = credential.email, !email.isEmpty else {
            authError = "Apple did not return an email. Please try again."
            return
        }

        pendingAppleUserID = credential.user
        pendingAppleEmail = email
        pendingUsername = ""
        pendingAge = ""
        showingAppleRegistration = true
    }

    private func finishAppleRegistration() {
        authError = nil

        guard let pendingAppleUserID, let pendingAppleEmail else {
            authError = "Apple account data is missing. Try again."
            return
        }

        guard let age = Int(pendingAge.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            authError = "Enter a valid age."
            return
        }

        do {
            try store.registerAppleAccount(
                appleUserID: pendingAppleUserID,
                email: pendingAppleEmail,
                username: pendingUsername,
                age: age
            )
            showingAppleRegistration = false
            onContinue()
        } catch {
            authError = error.localizedDescription
        }
    }

    private func signInWithUsername() {
        authError = nil

        if store.signIn(username: usernameLogin) {
            onContinue()
        } else {
            authError = "No user was found for that username on this device."
        }
    }
}

private struct IntroBackground: View {
    @EnvironmentObject private var appearanceStore: AppearanceStore

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let isDark = appearanceStore.appearance.isDark

            ZStack {
                LinearGradient(
                    colors: isDark ? [
                        Color(red: 0.01, green: 0.02, blue: 0.08),
                        Color(red: 0.04, green: 0.10, blue: 0.22),
                        Color(red: 0.03, green: 0.23, blue: 0.30),
                    ] : [
                        Color(red: 0.99, green: 0.99, blue: 1.00),
                        Color(red: 0.93, green: 0.97, blue: 1.00),
                        Color(red: 0.84, green: 0.94, blue: 0.99),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.38, green: 0.97, blue: 0.95).opacity(isDark ? 0.28 : 0.18),
                        .clear,
                    ],
                    center: .topTrailing,
                    startRadius: 40,
                    endRadius: 280
                )
                .offset(x: -20, y: -80)

                RadialGradient(
                    colors: [
                        Color(red: 0.32, green: 0.49, blue: 1.00).opacity(isDark ? 0.30 : 0.16),
                        .clear,
                    ],
                    center: .bottomLeading,
                    startRadius: 20,
                    endRadius: 300
                )
                .offset(x: 10, y: 120)

                movingOrb(
                    color: isDark ? Color.cyan.opacity(0.22) : Color.cyan.opacity(0.16),
                    size: 320,
                    x: -110 + cos(time * 0.23) * 24,
                    y: -240 + sin(time * 0.16) * 30
                )

                movingOrb(
                    color: isDark ? Color.blue.opacity(0.18) : Color.blue.opacity(0.12),
                    size: 260,
                    x: 140 + sin(time * 0.19) * 28,
                    y: -40 + cos(time * 0.21) * 34
                )

                movingOrb(
                    color: isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.52),
                    size: 280,
                    x: -40 + cos(time * 0.12) * 40,
                    y: 290 + sin(time * 0.18) * 22
                )

                CircuitGrid(time: time)
            }
            .ignoresSafeArea()
        }
    }

    private func movingOrb(color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 34)
            .offset(x: x, y: y)
    }
}

private struct CircuitGrid: View {
    @EnvironmentObject private var appearanceStore: AppearanceStore
    let time: TimeInterval

    var body: some View {
        let isDark = appearanceStore.appearance.isDark

        ZStack {
            Path { path in
                let width: CGFloat = 420
                let height: CGFloat = 860
                let spacing: CGFloat = 54

                stride(from: 0 as CGFloat, through: width, by: spacing).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }

                stride(from: 0 as CGFloat, through: height, by: spacing).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
            .frame(width: 420, height: 860)
            .rotationEffect(.degrees(-12))
            .offset(y: 30)

            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 2) ? Color.cyan.opacity(isDark ? 0.48 : 0.34) : (isDark ? Color.white.opacity(0.32) : Color.black.opacity(0.16)))
                    .frame(width: index.isMultiple(of: 2) ? 8 : 5, height: index.isMultiple(of: 2) ? 8 : 5)
                    .blur(radius: index.isMultiple(of: 2) ? 0.2 : 0.8)
                    .offset(
                        x: CGFloat(-160 + (index * 48)),
                        y: CGFloat(-220 + ((index % 4) * 138)) + sin(time * 0.45 + Double(index)) * 16
                    )
            }
        }
    }
}

private struct AILogoMark: View {
    @EnvironmentObject private var appearanceStore: AppearanceStore
    let isAnimating: Bool

    var body: some View {
        let isDark = appearanceStore.appearance.isDark

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (isDark ? Color.white : Color.blue).opacity(0.24),
                            Color.cyan.opacity(0.14),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 124
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect(isAnimating ? 1.06 : 0.95)

            Circle()
                .stroke(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
                .frame(width: 208, height: 208)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 18).repeatForever(autoreverses: false), value: isAnimating)

            Circle()
                .trim(from: 0.08, to: 0.92)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.cyan.opacity(0.1),
                            (isDark ? Color.white : Color.black).opacity(0.95),
                            Color.cyan.opacity(0.8),
                            (isDark ? Color.white : Color.black).opacity(0.1),
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 176, height: 176)
                .rotationEffect(.degrees(isAnimating ? -360 : 0))
                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: isAnimating)

            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isDark ? [
                            Color(red: 0.10, green: 0.13, blue: 0.24),
                            Color(red: 0.05, green: 0.08, blue: 0.16),
                        ] : [
                            Color.white.opacity(0.98),
                            Color(red: 0.88, green: 0.95, blue: 0.99),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 148, height: 148)
                .overlay {
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .stroke(isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.08), lineWidth: 1.2)
                }
                .shadow(color: isDark ? Color.cyan.opacity(0.24) : Color.cyan.opacity(0.16), radius: 24, y: 14)

            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    chipNode

                    VStack(alignment: .leading, spacing: 8) {
                        taskRow(width: 54, isCompleted: true)
                        taskRow(width: 40, isCompleted: true)
                    }
                }

                HStack(spacing: 12) {
                    taskRow(width: 64, isCompleted: false)

                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.cyan)
                        .frame(width: 30, height: 30)
                        .background((isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            ForEach(0..<4, id: \.self) { index in
                connectionDot(angle: Double(index) * 90, active: index.isMultiple(of: 2))
            }
        }
        .frame(width: 280, height: 280)
    }

    private var chipNode: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.95),
                            Color(red: 0.31, green: 0.59, blue: 1.00),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)

            Image(systemName: "brain.head.profile")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(Color.black.opacity(0.84))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke((appearanceStore.appearance.isDark ? Color.white : Color.black).opacity(appearanceStore.appearance.isDark ? 0.3 : 0.08), lineWidth: 1)
        }
    }

    private func taskRow(width: CGFloat, isCompleted: Bool) -> some View {
        let isDark = appearanceStore.appearance.isDark

        return HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isCompleted ? Color.cyan.opacity(0.95) : (isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.08)))
                    .frame(width: 24, height: 24)

                Image(systemName: isCompleted ? "checkmark" : "circle")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(isCompleted ? Color.black.opacity(0.82) : (isDark ? .white.opacity(0.72) : Color.black.opacity(0.54)))
            }

            Capsule()
                .fill(isCompleted ? (isDark ? Color.white.opacity(0.72) : Color.black.opacity(0.6)) : (isDark ? Color.white.opacity(0.22) : Color.black.opacity(0.14)))
                .frame(width: width, height: 8)
        }
    }

    private func connectionDot(angle: Double, active: Bool) -> some View {
        let radians = angle * .pi / 180
        let isDark = appearanceStore.appearance.isDark

        return Circle()
            .fill(active ? Color.cyan.opacity(0.92) : (isDark ? Color.white.opacity(0.55) : Color.black.opacity(0.26)))
            .frame(width: active ? 12 : 8, height: active ? 12 : 8)
            .overlay {
                Circle()
                    .stroke((isDark ? Color.white : Color.black).opacity(isDark ? 0.2 : 0.08), lineWidth: 1)
            }
            .offset(
                x: cos(radians) * 108,
                y: sin(radians) * 108
            )
    }
}
