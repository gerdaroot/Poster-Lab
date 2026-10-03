import SwiftUI

struct EditorView: View {
    @Environment(Library.self) private var library
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var editor: EditorState
    @State private var panel: Panel = .layers
    @State private var exportState: ExportState = .idle
    @State private var showSetWallpaper = false
    @State private var lastRendered: UIImage?
    @State private var lastTendies: URL?
    @State private var showPreview = false
    @State private var stateView = 0
    @State private var showExportName = false
    @State private var exportName = ""

    enum Panel: String, CaseIterable, Identifiable {
        case layers = "Layers"
        case background = "Background"
        case inspect = "Layer"
        case add = "Add"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .layers: return "square.3.layers.3d"
            case .background: return "square.fill.on.circle.fill"
            case .inspect: return "slider.horizontal.3"
            case .add: return "plus"
            }
        }
    }

    enum ExportState: Equatable { case idle, rendering, saved, failed(String) }

    init(project: WallpaperProject) {
        _editor = State(initialValue: EditorState(project: project))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            canvasArea
            stateToggle
            panelBar
            panelContent
                .frame(height: 280)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showSetWallpaper) {
            if let image = lastRendered {
                SetWallpaperGuide(image: image, tendiesURL: lastTendies) { url in
                    Task { await appVM.importTendieFiles(urls: [url]) }
                }
            }
        }
        .fullScreenCover(isPresented: $showPreview) {
            PosterPreview(project: editor.project)
        }
        .alert("File name", isPresented: $showExportName) {
            TextField("Name", text: $exportName)
            Button("Export") { performTendiesExport(name: exportName) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Name for the .tendies file")
        }
        .onAppear {
            if ProcessInfo.processInfo.environment["POSTERLAB_PREVIEW"] == "1" { showPreview = true }
            if ProcessInfo.processInfo.environment["POSTERLAB_EXPORT"] == "1" {
                if let url = try? TendiesExporter.export(editor.project) {
                    let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("export.tendies")
                    try? FileManager.default.removeItem(at: dest)
                    try? FileManager.default.copyItem(at: url, to: dest)
                }
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                library.upsert(editor.project)
                dismiss()
            } label: {
                Image(systemName: "chevron.left").font(.headline)
            }

            TextField("Name", text: Binding(
                get: { editor.project.name },
                set: { editor.project.name = $0 }))
                .font(.headline)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)

            ToolButton(systemName: "arrow.uturn.backward", isDisabled: !editor.canUndo) { editor.undo() }
            ToolButton(systemName: "arrow.uturn.forward", isDisabled: !editor.canRedo) { editor.redo() }
            ToolButton(systemName: "play.rectangle.fill") { showPreview = true }

            Menu {
                Button { exportTendies() } label: { Label("Export .tendies", systemImage: "square.stack.3d.up") }
                Button { exportPhoto() } label: { Label("Save Photo", systemImage: "photo") }
            } label: {
                Group {
                    switch exportState {
                    case .rendering: ProgressView().tint(.white)
                    case .saved: Image(systemName: "checkmark")
                    case .failed: Image(systemName: "exclamationmark.triangle")
                    default: Image(systemName: "square.and.arrow.up")
                    }
                }
                .font(.headline)
                .frame(width: 40, height: 34)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var canvasArea: some View {
        GeometryReader { geo in
            let canvasSize = fittedSize(in: geo.size)
            ZStack {
                WallpaperCanvas(project: editor.project, size: canvasSize,
                                stateProgress: Double(stateView))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1))
                    .shadow(color: .black.opacity(0.5), radius: 24, y: 12)

                if let sel = editor.selectedLayer, !sel.isHidden {
                    selectionBox(for: sel, canvasSize: canvasSize)
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .contentShape(Rectangle())
            .highPriorityGesture(moveGesture(canvasSize: canvasSize))
            .simultaneousGesture(magnifyGesture())
            .simultaneousGesture(rotateGesture())
            .onTapGesture { location in selectLayer(at: location, canvasSize: canvasSize) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    private func fittedSize(in available: CGSize) -> CGSize {
        let aspect = editor.project.device.aspect
        var w = available.width
        var h = w / aspect
        if h > available.height {
            h = available.height
            w = h * aspect
        }
        return CGSize(width: w, height: h)
    }

    private func selectionBox(for layer: Layer, canvasSize: CGSize) -> some View {
        let base = canvasSize.width * 0.34
        let side = max(44, base * layer.scale)
        let center = CGPoint(x: layer.position.x * canvasSize.width,
                             y: layer.position.y * canvasSize.height)
        return RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(Theme.accent, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            .frame(width: side, height: side)
            .rotationEffect(.radians(layer.rotation))
            .position(center)
            .allowsHitTesting(false)
    }

    @State private var dragStart: CGPoint?
    @State private var scaleStart: Double?
    @State private var rotationStart: Double?

    private func moveGesture(canvasSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                if editor.selectedLayer == nil {

                    selectLayer(at: value.startLocation, canvasSize: canvasSize)
                }
                guard editor.selectedLayer != nil else { return }
                if dragStart == nil {
                    dragStart = editor.selectedLayer?.position
                    editor.checkpoint()
                }
                guard let start = dragStart else { return }
                editor.updateSelected { layer in
                    layer.position = CGPoint(
                        x: min(max(start.x + value.translation.width / canvasSize.width, 0), 1),
                        y: min(max(start.y + value.translation.height / canvasSize.height, 0), 1))
                }
            }
            .onEnded { _ in dragStart = nil }
    }

    private func magnifyGesture() -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                guard editor.selectedLayer != nil else { return }
                if scaleStart == nil {
                    scaleStart = editor.selectedLayer?.scale
                    editor.checkpoint()
                }
                guard let start = scaleStart else { return }
                editor.updateSelected { $0.scale = min(max(start * value.magnification, 0.1), 8) }
            }
            .onEnded { _ in scaleStart = nil }
    }

    private func rotateGesture() -> some Gesture {
        RotateGesture()
            .onChanged { value in
                guard editor.selectedLayer != nil else { return }
                if rotationStart == nil {
                    rotationStart = editor.selectedLayer?.rotation
                    editor.checkpoint()
                }
                guard let start = rotationStart else { return }
                editor.updateSelected { $0.rotation = start + value.rotation.radians }
            }
            .onEnded { _ in rotationStart = nil }
    }

    private func selectLayer(at location: CGPoint, canvasSize: CGSize) {
        let p = CGPoint(x: location.x / canvasSize.width,
                        y: location.y / canvasSize.height)
        var best: (id: UUID, dist: Double)?
        for layer in editor.project.layers where !layer.isHidden {
            let dx = Double(layer.position.x - p.x)
            let dy = Double(layer.position.y - p.y)
            let d = dx * dx + dy * dy
            if best == nil || d < best!.dist { best = (layer.id, d) }
        }
        if let best, best.dist < 0.09 {
            editor.selectedLayerID = best.id
            panel = .inspect
        } else {
            editor.selectedLayerID = nil
        }
    }

    private var hasStateLayers: Bool {
        editor.project.layers.contains { !$0.states.isDefault }
    }

    @ViewBuilder
    private var stateToggle: some View {
        if hasStateLayers {
            VStack(spacing: 3) {
                Picker("", selection: $stateView.animation(.spring(response: 0.4, dampingFraction: 0.82))) {
                    Text("Lock Screen").tag(0)
                    Text("Home Screen").tag(1)
                }
                .pickerStyle(.segmented)
                Text(stateView == 0 ? "Lock Screen layout" : "Home Screen layout — flying-in layers are in place")
                    .font(.system(size: 10)).foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
        }
    }

    private var panelBar: some View {
        HStack(spacing: 6) {
            ForEach(Panel.allCases) { p in
                let selected = panel == p
                Button {
                    if p == .add { addMenuTapped() }
                    else { withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { panel = p } }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: p.icon).font(.system(size: 17, weight: .bold))
                        Text(p.rawValue.loc).font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(selected ? .white : Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.accentGradient)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .padding(6)
        .background(Theme.surface)
    }

    @State private var showAddSheet = false

    private func addMenuTapped() { showAddSheet = true }

    @ViewBuilder
    private var panelContent: some View {
        Group {
            switch panel {
            case .layers: LayerListPanel(editor: editor)
            case .background: BackgroundPanel(editor: editor)
            case .inspect: InspectorPanel(editor: editor)
            case .add: LayerListPanel(editor: editor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .sheet(isPresented: $showAddSheet) {
            AddLayerSheet(editor: editor) { panel = .inspect }
                .presentationDetents([.medium])
        }
    }

    private func exportTendies() {
        exportName = editor.project.name
        showExportName = true
    }

    private func performTendiesExport(name: String) {
        exportState = .rendering
        Task { @MainActor in
            do {
                let url = try TendiesExporter.export(editor.project, fileName: name)
                lastTendies = url
                lastRendered = WallpaperRenderer.render(editor.project)
                library.upsert(editor.project)
                exportState = .saved
                showSetWallpaper = true
                try? await Task.sleep(for: .seconds(1.5))
                exportState = .idle
            } catch {
                exportState = .failed(error.localizedDescription)
                try? await Task.sleep(for: .seconds(2))
                exportState = .idle
            }
        }
    }

    private func exportPhoto() {
        exportState = .rendering
        Task { @MainActor in
            guard let image = WallpaperRenderer.render(editor.project) else {
                exportState = .failed("render"); return
            }
            lastRendered = image
            do {
                try await PhotoExporter.save(image)
                exportState = .saved
                library.upsert(editor.project)
                try? await Task.sleep(for: .seconds(2))
                exportState = .idle
            } catch {
                exportState = .failed(error.localizedDescription)
            }
        }
    }
}
