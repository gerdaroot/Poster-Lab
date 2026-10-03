import SwiftUI
import Observation

@Observable
final class Library {
    var projects: [WallpaperProject] = []

    @ObservationIgnored
    private let fileURL: URL = {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("library.json")
    }()

    init() { load() }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([WallpaperProject].self, from: data) {
            projects = decoded.sorted { $0.modifiedAt > $1.modifiedAt }
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(projects) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func upsert(_ project: WallpaperProject) {
        var p = project
        p.modifiedAt = Date()
        if let idx = projects.firstIndex(where: { $0.id == p.id }) {
            projects[idx] = p
        } else {
            projects.insert(p, at: 0)
        }
        projects.sort { $0.modifiedAt > $1.modifiedAt }
        save()
    }

    func delete(_ project: WallpaperProject) {
        for layer in project.layers {
            if case let .photo(imageID, _) = layer.content { ImageStore.shared.delete(imageID) }
        }
        if case let .photo(imageID) = project.background { ImageStore.shared.delete(imageID) }
        projects.removeAll { $0.id == project.id }
        save()
    }

    func duplicate(_ project: WallpaperProject) {
        var copy = project
        copy.id = UUID()
        copy.name = project.name + " copy"
        copy.createdAt = Date()
        upsert(copy)
    }
}
