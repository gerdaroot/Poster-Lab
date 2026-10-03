import SwiftUI
import PhotosUI

struct AddLayerSheet: View {
    @Bindable var editor: EditorState
    var onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var cutoutBackground = true
    @State private var busy = false
    @State private var errorText: String?

    private let stickers = ["star.fill", "heart.fill", "sparkle", "bolt.fill", "flame.fill",
                            "moon.stars.fill", "cloud.fill", "leaf.fill", "crown.fill", "gamecontroller.fill"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    photoSection
                    textSection
                    stickerSection
                    if let errorText {
                        Text(errorText).font(.system(size: 12)).foregroundStyle(.red)
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Add layer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .overlay { if busy { ProgressView("Cutting out subject…").padding(24).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16)) } }
        }
        .preferredColorScheme(.dark)
        .onChange(of: photoItem) { _, item in handlePhoto(item) }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PHOTO").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.textSecondary)
            Toggle(isOn: $cutoutBackground) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cut out subject").font(.system(size: 14, weight: .medium))
                    Text("The subject goes in front of the clock (depth effect)").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }
            }.tint(Theme.accent)
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Choose photo", systemImage: "photo.badge.plus")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
        .padding(14).panelCard()
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TEXT").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.textSecondary)
            Button { addText() } label: {
                Label("Add text", systemImage: "textformat")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(14).panelCard()
    }

    private var stickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STICKERS").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.textSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 10)], spacing: 10) {
                ForEach(stickers, id: \.self) { symbol in
                    Button { addSticker(symbol) } label: {
                        Image(systemName: symbol).font(.system(size: 24))
                            .frame(width: 56, height: 56)
                            .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
        .padding(14).panelCard()
    }

    private func addText() {
        let layer = Layer(name: String(localized: "Text"), content: .text(TextSpec(string: String(localized: "Text"), fontSize: 120, weight: 7)),
                          position: CGPoint(x: 0.5, y: 0.5))
        editor.addLayer(layer)
        finish()
    }

    private func addSticker(_ symbol: String) {
        let layer = Layer(name: String(localized: "Sticker"), content: .sticker(symbol: symbol, color: .white),
                          position: CGPoint(x: 0.5, y: 0.5), depth: .floating)
        editor.addLayer(layer)
        finish()
    }

    private func handlePhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        busy = true; errorText = nil
        Task {
            defer { Task { @MainActor in busy = false } }
            guard let data = try? await item.loadTransferable(type: Data.self),
                  var img = UIImage(data: data) else {
                await MainActor.run { errorText = "Couldn't load the photo." }
                return
            }
            var depth: DepthPlane = .background
            if cutoutBackground {
                do { img = try await SubjectCutout.cutout(img); depth = .foreground }
                catch { await MainActor.run { errorText = error.localizedDescription } }
            }
            await MainActor.run {
                let id = ImageStore.shared.save(img)
                let layer = Layer(name: cutoutBackground ? String(localized: "Subject") : String(localized: "Photo"),
                                  content: .photo(imageID: id, cornerRadius: 0),
                                  position: CGPoint(x: 0.5, y: 0.62), depth: depth)
                editor.addLayer(layer)
                finish()
            }
        }
    }

    private func finish() { onAdd(); dismiss() }
}
