//
//  Group.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 01/02/2026.
//


import SwiftData
import Foundation

@Model
final class Group {
    var id: UUID
    var name: String
    var createdAt: Date

    var coachId: UUID   // ✅ ключът за филтриране
    var coach: Coach?   // по желание, за навигация/връзки

    init(id: UUID = UUID(), name: String, createdAt: Date = .now, coachId: UUID, coach: Coach? = nil) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.coachId = coachId
        self.coach = coach
    }
}
