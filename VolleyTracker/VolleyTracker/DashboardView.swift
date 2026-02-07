//
//  DashboardView.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 07/02/2026.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    let coach: Coach

    var body: some View {
        ZStack {
            Image("volleyball")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 18)

            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer(minLength: 80)

                VStack(spacing: 6) {
                    Text("Welcome coach")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))

                    Text(coach.name)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(coach.club)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )

                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}
