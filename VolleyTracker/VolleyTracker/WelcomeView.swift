//
//  WelcomeView.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 27/01/2026.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        ZStack {
            // 1) Background image
            Image("volleyball")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 6)

            // 2) Dark overlay за да изпъква текстът
            LinearGradient(
                colors: [
                    .black.opacity(0.55),
                    .black.opacity(0.35),
                    .black.opacity(0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 3) Content
            VStack(spacing: 14) {
                Spacer()

                Text("VolleyTracker")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Track attendance fast. Stay organized.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.90))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer()

                NavigationLink {
                    CreateCoachView()
                } label: {
                    HStack(spacing: 10) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.horizontal, 24)

                Spacer().frame(height: 30)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
