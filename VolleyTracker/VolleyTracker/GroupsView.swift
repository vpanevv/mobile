//
//  GroupsView.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 28/01/2026.
//

import SwiftUI

struct GroupsView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            Text("Groups (coming soon)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Groups")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { GroupsView() }
}

