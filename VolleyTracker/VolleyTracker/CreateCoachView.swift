//
//  CreateCoachView.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 27/01/2026.
//

import SwiftUI // import the SwiftUI framework

struct CreateCoachView: View { // Define the CreateCoachView struct screen
    var body: some View { //
        VStack(spacing: 12) { // вертикално подреждане на елементи
            //отгоре надолу с разстояние 12pt
            Text("Create Coach") // заглавие
                .font(.title.bold()) // прави текста bold

            Text("Next: field for coach name + SwiftData save.") // описание
                .foregroundStyle(.secondary)
            // .secondary цвят за по-слабо акцентиране
        }
        .padding() // padding около VStack
        .navigationTitle("Coach") // заглавие на навигационната лента
        .navigationBarTitleDisplayMode(.inline) // заглавието е в средата
    }
}

#Preview {
    NavigationStack {
        CreateCoachView()
    }
}
