import Foundation

struct LocationTimeSnapshot: Identifiable, Equatable {
    let id: String
    let location: WorldLocation
    let currentTimeText: String
    let dateText: String
    let timeZoneName: String
    let differenceText: String
    let comparisonText: String
}

struct SelectedLocationState: Equatable {
    enum Status: Equatable {
        case idle
        case loading(WorldLocation.Source)
        case loaded(LocationTimeSnapshot)
        case failed(String)
    }

    var status: Status = .idle
}
