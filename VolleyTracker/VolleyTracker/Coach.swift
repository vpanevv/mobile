//
//  Coach.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 28/01/2026.
//

import Foundation
import SwiftData

@Model
final class Coach {
    var id: UUID
    var name: String
    var createdAt: Date

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
