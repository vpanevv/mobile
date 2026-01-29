//
//  WelcomeView.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 27/01/2026.
//

import SwiftUI
// import the SwiftUI
// This is the welcome view for the VolleyTracker app.

struct WelcomeView: View { // Define the WelcomeView struct conforming to the View protocol
    
    var body: some View { // Define the body property of the view
        ZStack { // Use a ZStack to layer views on top of each other
            // 1) Background image
            Image("volleyball") // Load the background image named "volleyball"
                .resizable() // Make the image resizable
                .scaledToFill() // Scale the image to fill the screen
                .ignoresSafeArea() // Ignore safe area to cover the entire screen
                .blur(radius: 4)

            // 2) Dark overlay за да изпъква текстът
            LinearGradient(
                colors: [
                    .black.opacity(0.55),
                    .black.opacity(0.35),
                    .black.opacity(0.65),
                    .black.opacity(0.85)
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
                    .colorInvert()
                    

                Spacer()

                NavigationLink {
                    CreateCoachView()
                } label: {
                    HStack(spacing: 10) {
                           Text("Get Started")
                               .font(.system(size: 18, weight: .semibold))

                           Image(systemName: "arrow.right")
                               .font(.system(size: 18, weight: .semibold))
                       }
                       .foregroundStyle(.white)
                       .padding(.horizontal, 28)
                       .padding(.vertical, 14)
                       .background(
                           Capsule()
                               .fill(Color.blue)
                               .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
                       )
                   }

                Spacer().frame(height: 30)
            }
        }
    }
}

#Preview { // Preview provider for the WelcomeView
    NavigationStack {
        WelcomeView()
    }
}
