import SwiftUI
import Observation

@Observable
final class EditorState {
    var project: WallpaperProject
    var selectedLayerID: UUID?

    @ObservationIgnored private var undoStack: [WallpaperProject] = []
    @ObservationIgnored private var redoStack: [WallpaperProject] = []

    init(project: WallpaperProject) {
        self.project = project
        self.selectedLayerID = project.layers.last?.id
    }

    var selectedLayer: Layer? {
        get { project.layers.first { $0.id == selectedLayerID } }
        set {
            guard let newValue, let idx = project.layers.firstIndex(where: { $0.id == newValue.id })
            else { return }
            project.layers[idx] = newValue
        }
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func checkpoint() {
        undoStack.append(project)
        if undoStack.count > 50 { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        redoStack.append(project)
        project = last
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(project)
        project = next
    }

    func addLayer(_ layer: Layer) {
        checkpoint()
        project.layers.append(layer)
        selectedLayerID = layer.id
    }

    func deleteSelected() {
        guard let id = selectedLayerID else { return }
        checkpoint()
        if let layer = project.layers.first(where: { $0.id == id }),
           case let .photo(imageID, _) = layer.content {
            ImageStore.shared.delete(imageID)
        }
        project.layers.removeAll { $0.id == id }
        selectedLayerID = project.layers.last?.id
    }

    func duplicateSelected() {
        guard let layer = selectedLayer else { return }
        checkpoint()
        var copy = layer
        copy.id = UUID()
        copy.position.x = min(layer.position.x + 0.04, 0.95)
        copy.position.y = min(layer.position.y + 0.04, 0.95)
        project.layers.append(copy)
        selectedLayerID = copy.id
    }

    func moveSelected(by offset: Int) {
        guard let id = selectedLayerID,
              let idx = project.layers.firstIndex(where: { $0.id == id }) else { return }
        let target = idx + offset
        guard project.layers.indices.contains(target) else { return }
        checkpoint()
        project.layers.swapAt(idx, target)
    }

    func updateSelected(_ transform: (inout Layer) -> Void) {
        guard let id = selectedLayerID,
              let idx = project.layers.firstIndex(where: { $0.id == id }) else { return }
        transform(&project.layers[idx])
    }
}
