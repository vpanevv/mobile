import Foundation

struct HydrationEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let amountML: Int
    let date: Date

    init(id: UUID = UUID(), amountML: Int, date: Date = .now) {
        self.id = id
        self.amountML = amountML
        self.date = date
    }
}
