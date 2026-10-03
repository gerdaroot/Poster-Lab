import SwiftUI
import PhotosUI

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    var format: String = "%.2f"
    var onCommit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title.loc).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(String(format: format, value)).font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
            Slider(value: $value, in: range) { editing in if !editing { onCommit() } }
                .tint(Theme.accent)
        }
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.loc.uppercased())
                .font(.system(size: 11, weight: .bold)).tracking(0.6)
                .foregroundStyle(Theme.textSecondary)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelCard()
    }
}

struct LayerListPanel: View {
    @Bindable var editor: EditorState

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if editor.project.layers.isEmpty {
                    Text("No layers yet. Tap “Add”.")
                        .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                        .padding(.top, 40)
                }
                ForEach(editor.project.layers.reversed()) { layer in
                    row(layer)
                }
            }
            .padding(14)
        }
    }

    private func row(_ layer: Layer) -> some View {
        let selected = layer.id == editor.selectedLayerID
        return HStack(spacing: 12) {
            Image(systemName: layer.symbolName).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(layer.name).font(.system(size: 14, weight: .medium)).lineLimit(1)
                Text(layer.depth.label).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button { editor.updateSelected { _ in }; toggleHidden(layer) } label: {
                Image(systemName: layer.isHidden ? "eye.slash" : "eye")
                    .foregroundStyle(Theme.textSecondary)
            }
            Image(systemName: layer.depth.systemImage).foregroundStyle(Theme.accent.opacity(0.8))
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(12)
        .background(selected ? Theme.surfaceHigh : Theme.surface,
                    in: RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
            .strokeBorder(selected ? Theme.accent : .clear, lineWidth: 1.5))
        .contentShape(Rectangle())
        .onTapGesture { editor.selectedLayerID = layer.id }
    }

    private func toggleHidden(_ layer: Layer) {
        guard let idx = editor.project.layers.firstIndex(where: { $0.id == layer.id }) else { return }
        editor.checkpoint()
        editor.project.layers[idx].isHidden.toggle()
    }
}

struct BackgroundPanel: View {
    @Bindable var editor: EditorState

    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SectionCard(title: "Background") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Choose background photo", systemImage: "photo.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    if case .photo = editor.project.background {
                        Button(role: .destructive) {
                            editor.checkpoint(); editor.project.background = .solid(.black)
                        } label: {
                            Label("Remove photo", systemImage: "trash")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .foregroundStyle(.red)
                        }
                    }
                }

                ParticleControls(editor: editor)
                RevealControls(editor: editor)
                ClockControls(editor: editor)
            }
            .padding(14)
        }
        .onChange(of: photoItem) { _, item in loadPhoto(item) }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                await MainActor.run {
                    let id = ImageStore.shared.save(img)
                    editor.checkpoint()
                    editor.project.background = .photo(imageID: id)
                }
            }
        }
    }
}

struct ClockControls: View {
    @Bindable var editor: EditorState

    var body: some View {
        SectionCard(title: "Clock / passcode") {
            picker("Font", selection: Binding(
                get: { editor.project.clock.font },
                set: { editor.project.clock.font = $0 }), cases: ClockFont.allCases) { $0.label }

            picker("Digits", selection: Binding(
                get: { editor.project.clock.numbering },
                set: { editor.project.clock.numbering = $0 }), cases: ClockNumbering.allCases) { $0.label }

            picker("Screen", selection: Binding(
                get: { editor.project.role },
                set: { editor.project.role = $0 }), cases: PosterRole.allCases) { $0.label }
        }
    }

    private func picker<T: Hashable>(_ title: String, selection: Binding<T>,
                                     cases: [T], label: @escaping (T) -> String) -> some View {
        HStack {
            Text(title.loc).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary)
            Spacer()
            Picker(title, selection: selection) {
                ForEach(cases, id: \.self) { Text(label($0)).tag($0) }
            }
            .pickerStyle(.menu).tint(Theme.accent)
        }
    }
}

struct ParticleControls: View {
    @Bindable var editor: EditorState

    var body: some View {
        SectionCardPublic(title: "Full-screen effect") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 10)], spacing: 10) {
                ForEach(ParticleKind.allCases, id: \.self) { kind in
                    let on = editor.project.particles.kind == kind
                    Button {
                        editor.checkpoint(); editor.project.particles.kind = kind
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: kind.symbol).font(.system(size: 20, weight: .semibold))
                            Text(kind.label).font(.system(size: 11, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(on ? Theme.accent.opacity(0.25) : Theme.surfaceHigh,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(on ? Theme.accent : .clear, lineWidth: 1.5))
                        .foregroundStyle(on ? Theme.accent : Theme.textPrimary)
                    }
                }
            }
            if editor.project.particles.kind != .none {
                SliderRow(title: "Density", value: Binding(
                    get: { editor.project.particles.intensity },
                    set: { editor.project.particles.intensity = $0 }), range: 0...1) { editor.checkpoint() }
                SliderRow(title: "Speed", value: Binding(
                    get: { editor.project.particles.speed },
                    set: { editor.project.particles.speed = $0 }), range: 0...1) { editor.checkpoint() }
            }
        }
    }
}

struct RevealControls: View {
    @Bindable var editor: EditorState

    var body: some View {
        SectionCardPublic(title: "Reveal animation") {
            HStack {
                Text("Effect").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { editor.project.reveal.anim },
                    set: { editor.checkpoint(); editor.project.reveal.anim = $0 })) {
                    ForEach(RevealAnim.allCases, id: \.self) { Text($0.label).tag($0) }
                }.pickerStyle(.menu).tint(Theme.accent)
            }
            if editor.project.reveal.anim != .none {
                HStack {
                    Text("Apply to").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { editor.project.reveal.target },
                        set: { editor.project.reveal.target = $0 })) {
                        ForEach(RevealTarget.allCases, id: \.self) { Text($0.label).tag($0) }
                    }.pickerStyle(.menu).tint(Theme.accent)
                }
                SliderRow(title: "Duration, s", value: Binding(
                    get: { editor.project.reveal.duration },
                    set: { editor.project.reveal.duration = $0 }), range: 0.2...2.5, format: "%.1f") { editor.checkpoint() }
                Text("Plays when the Lock Screen wakes and when revealing the Home Screen.")
                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

struct SectionCardPublic<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.loc.uppercased()).font(.system(size: 11, weight: .bold)).tracking(0.6)
                .foregroundStyle(Theme.textSecondary)
            content
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).panelCard()
    }
}
