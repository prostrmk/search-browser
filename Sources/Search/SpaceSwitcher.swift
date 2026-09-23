import SwiftUI

struct SpaceSwitcher: View {
    @ObservedObject var browser: Browser
    @ObservedObject var spaces: Spaces
    var compact = false
    @State private var name = ""
    @State private var edit: Edit?
    @State private var confirmingRemoval = false

    private enum Edit: String, Identifiable, Equatable {
        case create, rename
        var id: String { rawValue }
    }

    var body: some View {
        Menu {
            ForEach(spaces.items) { space in
                Button {
                    browser.switchSpace(space.id)
                } label: {
                    if space.id == spaces.activeID {
                        Label(space.name, systemImage: "checkmark")
                    } else {
                        Text(space.name)
                    }
                }
            }
            Divider()
            Button("New Space…") { name = ""; edit = .create }
            Button("Rename Space…") { name = spaces.active.name; edit = .rename }
            if spaces.items.count > 1 && spaces.activeID != Space.defaultID {
                Button("Remove Space…", role: .destructive) { confirmingRemoval = true }
            }
            if let host = browser.active?.address?.host() {
                Menu("Route \(host) to…") {
                    ForEach(spaces.items) { space in
                        Button(space.name) { spaces.route(host: host, to: space.id) }
                    }
                    if let route = spaces.route(for: host) {
                        Divider()
                        Button("Remove Route for \(route.host)") { spaces.unroute(host: route.host) }
                    }
                }
            }
        } label: {
            Group {
                if compact {
                    Image(systemName: "square.stack.3d.up")
                } else {
                    Label(spaces.active.name, systemImage: "square.stack.3d.up")
                        .lineLimit(1)
                }
            }
            .help("Spaces — \(spaces.active.name)")
        }
        .menuStyle(.borderlessButton)
        .alert(edit == .create ? "New Space" : "Rename Space", isPresented: Binding(
            get: { edit != nil }, set: { if !$0 { edit = nil } }
        )) {
            TextField("Name", text: $name)
            Button("Save") {
                let value = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    if edit == .create { browser.createSpace(named: value) }
                    else { spaces.rename(spaces.activeID, to: value) }
                }
                edit = nil
            }
            Button("Cancel", role: .cancel) { edit = nil }
        }
        .confirmationDialog("Remove \(spaces.active.name)?", isPresented: $confirmingRemoval) {
            Button("Remove Space", role: .destructive) { browser.removeSpace(spaces.activeID) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Its tabs, cookies, passwords, and downloads will be removed.")
        }
    }
}
