import AuthenticationServices
import SwiftData
import SwiftUI

struct SignInView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.35), Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    VStack(spacing: 18) {
                        Image(systemName: "steeringwheel.and.key")
                            .font(.system(size: 62, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.primary)
                            .frame(width: 118, height: 118)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))

                        VStack(spacing: 10) {
                            Text("GarageMate")
                                .font(.largeTitle.bold())
                            Text("A polished local-first garage for your cars, services, reminders, and notes.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }

                    Spacer()

                    VStack(spacing: 14) {
                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            viewModel.handleAppleResult(result, modelContext: modelContext)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityLabel("Continue with Apple")

                        Button {
                            viewModel.continueWithoutApple(modelContext: modelContext)
                        } label: {
                            Label("Continue without Apple", systemImage: "person.crop.circle.badge.checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
            }
            .navigationBarHidden(true)
        }
    }
}
