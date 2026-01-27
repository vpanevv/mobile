//
//  CreateCoachView.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 27/01/2026.
//

import SwiftUI

struct CreateCoachView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Create Coach")
                .font(.title.bold())

            Text("Next: field for coach name + SwiftData save.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Coach")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CreateCoachView()
    }
}
