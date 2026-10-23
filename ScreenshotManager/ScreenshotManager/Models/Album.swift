import SwiftUI

/// The fixed set of albums. `recent` is backed live by the Photos library's
/// screenshots; every other album holds images the user filed into it.
enum Album: String, CaseIterable, Identifiable, Hashable, Codable {
    case recent, work, chats, travel, personal, notes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent: "Recent"
        case .work: "Work"
        case .chats: "Chats"
        case .travel: "Travel"
        case .personal: "Personal"
        case .notes: "Notes"
        }
    }

    var symbol: String {
        switch self {
        case .recent: "photo.on.rectangle"
        case .work: "folder"
        case .chats: "bubble.left"
        case .travel: "airplane"
        case .personal: "moon"
        case .notes: "doc.text"
        }
    }

    var tint: Color {
        switch self {
        case .recent: .indigo
        case .work: .blue
        case .chats: .green
        case .travel: .teal
        case .personal: .purple
        case .notes: .orange
        }
    }

    var isLibraryBacked: Bool { self == .recent }

    /// Albums the user can file screenshots into.
    static var userAlbums: [Album] { allCases.filter { !$0.isLibraryBacked } }
}

enum AlbumSort: String, CaseIterable, Identifiable {
    case all = "All"
    case mostItems = "Most Items"
    case updated = "Recently Updated"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .all: "square.grid.2x2"
        case .mostItems: "number"
        case .updated: "clock"
        }
    }
}
