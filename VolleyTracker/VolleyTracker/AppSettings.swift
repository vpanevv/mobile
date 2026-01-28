//
//  AppSettings.swift
//  VolleyTracker
//
//  Created by Vladimir Panev on 28/01/2026.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    // single-row settings
    var id: UUID
    var activeCoachId: UUID?

    init() {
        self.id = UUID()
        self.activeCoachId = nil
    }
}
