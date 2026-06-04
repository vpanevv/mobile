import SwiftUI
import SwiftData
import UIKit

struct FavoritesView: View {
    @EnvironmentObject var store: FavoritesStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("wishlyai.isDark") private var isDark: Bool = true
    @AppStorage("favPeopleBannerDismissed") private var bannerDismissed: Bool = false

    @Query private var people: [Person]

    /// Called to open the People sheet (provided by the presenter, e.g. WelcomeScreen).
    var onOpenPeople: () -> Void = {}

    @State private var appeared = false

    private var showBanner: Bool {
        !store.favorites.isEmpty && people.isEmpty && !bannerDismissed
    }

    var body: some View {
        ZStack {
            NeuralBackground()
            FlowAmbientLayer()

            VStack(spacing: 0) {
                header

                if store.favorites.isEmpty {
                    EmptyFavoritesState(onCreateWish: { dismiss() })
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(store.favorites.enumerated()), id: \.element.id) { idx, wish in
                                FavoriteWishCard(
                                    wish: wish,
                                    onDelete: { removeWish(wish) },
                                    onRegenerate: { regenerate(from: wish) }
                                )
                                .environmentObject(store)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 18)
                                .animation(
                                    .spring(response: 0.45, dampingFraction: 0.8).delay(Double(idx) * 0.05),
                                    value: appeared
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        if showBanner {
                            AddPeopleBanner(
                                onTap:   { openPeople() },
                                onClose: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                        bannerDismissed = true
                                    }
                                }
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeInOut(duration: 0.4).delay(0.3), value: appeared)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { appeared = true }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Favorites")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("\(store.favorites.count) saved \(store.favorites.count == 1 ? "wish" : "wishes")")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.55))
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Actions

    private func removeWish(_ wish: FavoriteWish) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            store.remove(wish)
        }
    }

    private func openPeople() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onOpenPeople()
        }
    }

    private func regenerate(from wish: FavoriteWish) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            AppRouter.shared.pendingWish = AppRouter.PendingWish(
                name:     wish.recipientName ?? "",
                occasion: HolidayType(rawValue: wish.occasion) ?? .birthday,
                tone:     WishTone.allCases.first { $0.label == wish.tone },
                length:   WishLength(rawValue: wish.length)
            )
        }
    }
}
