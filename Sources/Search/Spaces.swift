import Foundation
import SwiftUI

@MainActor
final class Spaces: ObservableObject {
    @Published private(set) var items: [Space]
    @Published private(set) var routes: [SpaceRoute]
    @Published var activeID: String { didSet { persist() } }
    private var sessions: [String: Session.Shape]

    private struct Archive: Codable {
        var items: [Space]
        var sessions: [String: Session.Shape]
        var routes: [SpaceRoute]
        var activeID: String
    }

    init() {
        if let data = try? Data(contentsOf: Store.file("spaces.json")),
           let saved = try? JSONDecoder().decode(Archive.self, from: data), !saved.items.isEmpty {
            items = saved.items
            sessions = saved.sessions
            routes = saved.routes
            activeID = saved.items.contains { $0.id == saved.activeID } ? saved.activeID : saved.items[0].id
        } else {
            items = [.initial]
            sessions = [Space.defaultID: Session.read()]
            routes = []
            activeID = Space.defaultID
            persist()
        }
    }

    var active: Space { items.first { $0.id == activeID } ?? .initial }
    func session(_ id: String) -> Session.Shape { sessions[id] ?? .init(tabs: [], active: 0) }
    func save(_ shape: Session.Shape, for id: String) { sessions[id] = shape; persist() }

    @discardableResult
    func create(name: String) -> Space {
        let id = UUID().uuidString
        let space = Space(id: id, name: name, storeID: UUID(uuidString: id))
        items.append(space)
        sessions[space.id] = .init(tabs: [], active: 0)
        persist()
        return space
    }

    func rename(_ id: String, to name: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].name = name
        persist()
    }

    func remove(_ id: String) {
        guard id != Space.defaultID, items.count > 1 else { return }
        items.removeAll { $0.id == id }
        sessions.removeValue(forKey: id)
        routes.removeAll { $0.spaceID == id }
        if activeID == id { activeID = items[0].id }
        persist()
    }

    func route(host: String, to id: String) {
        let key = host.lowercased()
        routes.removeAll { $0.host == key }
        routes.append(.init(host: key, spaceID: id))
        persist()
    }

    func unroute(host: String) {
        routes.removeAll { $0.host == host.lowercased() }
        persist()
    }

    func target(for url: URL) -> String? {
        guard let host = url.host()?.lowercased() else { return nil }
        return route(for: host)?.spaceID
    }

    func route(for host: String) -> SpaceRoute? {
        let host = host.lowercased()
        return routes.first { host == $0.host || host.hasSuffix("." + $0.host) }
    }

    private func persist() {
        let archive = Archive(items: items, sessions: sessions, routes: routes, activeID: activeID)
        guard let data = try? JSONEncoder().encode(archive) else { return }
        try? FileManager.default.createDirectory(at: Store.folder, withIntermediateDirectories: true)
        try? data.write(to: Store.file("spaces.json"), options: .atomic)
    }
}
