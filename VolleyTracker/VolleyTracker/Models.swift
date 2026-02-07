//
//  Models.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 07/02/2026.
//

import Foundation
import SwiftData

@Model
final class Coach {
    var name: String
    var club: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Group.coach)
    var groups: [Group] = []

    init(name: String, club: String, createdAt: Date = .now) {
        self.name = name
        self.club = club
        self.createdAt = createdAt
    }
}

@Model
final class Group {
    var name: String
    var createdAt: Date

    var coach: Coach?

    @Relationship(deleteRule: .cascade, inverse: \Player.group)
    var players: [Player] = []

    init(name: String, coach: Coach? = nil, createdAt: Date = .now) {
        self.name = name
        self.coach = coach
        self.createdAt = createdAt
    }
}

@Model
final class Player {
    var name: String
    var createdAt: Date

    var group: Group?

    init(name: String, group: Group? = nil, createdAt: Date = .now) {
        self.name = name
        self.group = group
        self.createdAt = createdAt
    }
}
