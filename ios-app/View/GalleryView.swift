import SwiftUI

struct GalleryView: View {
    @Environment(Library.self) private var library
    @EnvironmentObject private var appVM: AppViewModel
    @State private var editing: WallpaperProject?
    @State private var showTemplates = false
    @State private var toastMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if library.projects.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(library.projects) { project in
                            ProjectThumbnail(project: project)
                                .contentShape(Rectangle())
                                .onTapGesture { editing = project }
                                .contextMenu {
                                    Button("Add to Wallpapers Library", systemImage: "tray.and.arrow.down.fill") {
                                        addToLibrary(project)
                                    }
                                    Button("Duplicate", systemImage: "plus.square.on.square") {
                                        library.duplicate(project)
                                    }
                                    Divider()
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        library.delete(project)
                                    }
                                }
                        }
                    }
                    .padding(16)
                }
            }
            .overlay(alignment: .bottom) {
                if let msg = toastMessage {
                    Text(msg)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Theme.surfaceHigh, in: Capsule())
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Theme.bg)
            .navigationTitle("Create Wallpaper")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showTemplates = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .fullScreenCover(item: $editing) { project in
                EditorView(project: project)
            }
            .onAppear {

                if ProcessInfo.processInfo.environment["POSTERLAB_OPEN_FIRST"] == "1",
                   editing == nil, let first = library.projects.first {
                    editing = first
                }
            }
            .sheet(isPresented: $showTemplates) {
                TemplatePicker { project in
                    showTemplates = false
                    editing = project
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func addToLibrary(_ project: WallpaperProject) {
        Task { @MainActor in
            do {
                let url = try TendiesExporter.export(project, fileName: project.name)
                await appVM.importTendieFiles(urls: [url])
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    toastMessage = "Added to Wallpapers Library"
                }
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation { toastMessage = nil }
            } catch {
                withAnimation { toastMessage = "Export failed: \(error.localizedDescription)" }
                try? await Task.sleep(for: .seconds(2.4))
                withAnimation { toastMessage = nil }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)
            Text("No wallpapers yet")
                .font(Theme.display(24, .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Tap + and build your first wallpaper\nfrom backgrounds, text and your photos.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
            Button {
                showTemplates = true
            } label: {
                Label("Create wallpaper", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Theme.accent, in: Capsule())
                    .foregroundStyle(.white)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }
}

struct ProjectThumbnail: View {
    let project: WallpaperProject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                WallpaperCanvas(project: project,
                                size: CGSize(width: geo.size.width,
                                             height: geo.size.width / project.device.aspect),
                                animated: false)
                    .allowsHitTesting(false)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1))
            }
            .aspectRatio(project.device.aspect, contentMode: .fit)

            Text(project.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

struct TemplatePicker: View {
    let onPick: (WallpaperProject) -> Void

    private var templates: [(String, WallpaperProject)] {
        [
            ("Blank", { var p = WallpaperProject(name: String(localized: "New wallpaper"), background: .solid(.black)); p.layers = []; return p }()),
            ("Sunset", WallpaperProject.starter()),
            ("Midnight", {
                var p = WallpaperProject(name: String(localized: "Midnight"), background: .gradient(.midnight))
                var t = Layer(name: String(localized: "Date"), content: .text(TextSpec(string: String(localized: "Monday\nSeptember 29"), fontSize: 64, weight: 4)))
                t.position = CGPoint(x: 0.5, y: 0.2)
                p.layers = [t]
                return p
            }()),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 180), spacing: 14)], spacing: 14) {
                    ForEach(Array(templates.enumerated()), id: \.offset) { _, item in
                        Button { onPick(item.1) } label: {
                            VStack(spacing: 8) {
                                ProjectThumbnail(project: item.1)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Start from a template")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
