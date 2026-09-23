import Foundation
import SwiftUI

struct Space: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var storeID: UUID?
    static let defaultID = "default"
    static let initial = Space(id: defaultID, name: "Default", storeID: nil)
}

struct SpaceRoute: Codable, Identifiable, Equatable {
    var host: String
    var spaceID: String
    var id: String { host }
}
