import Foundation

struct CarMake: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let models: [String]
}
