import SwiftUI

struct InspectorPanel: View {
    @Bindable var editor: EditorState
    @State private var showEffects = false

    var body: some View {
        ScrollView {
            if editor.selectedLayer == nil {
                Text("Select a layer on the canvas.")
                    .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                    .padding(.top, 40)
            } else {
                VStack(spacing: 12) {
                    actions
                    depthAndBlend
                    transform
                    spinSection
                    statesSection
                    contentControls
                }
                .padding(14)
            }
        }
        .sheet(isPresented: $showEffects) {
            EffectsSheet(editor: editor)
                .presentationDetents([.medium, .large])
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            actionButton("Effects", "wand.and.stars", tint: Theme.accent) { showEffects = true }
            actionButton("Duplicate", "plus.square.on.square") { editor.duplicateSelected() }
            actionButton("Up", "arrow.up") { editor.moveSelected(by: 1) }
            actionButton("Down", "arrow.down") { editor.moveSelected(by: -1) }
            actionButton("Delete", "trash", tint: .red) { editor.deleteSelected() }
        }
    }

    private func actionButton(_ title: String, _ icon: String, tint: Color = Theme.textPrimary,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                Text(title.loc).font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var depthAndBlend: some View {
        card("Depth & blending") {
            HStack {
                Text("Layer").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Picker("", selection: bindDepth) {
                    ForEach(DepthPlane.allCases, id: \.self) { Text($0.label).tag($0) }
                }.pickerStyle(.segmented)
            }
            HStack {
                Text("Blend").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Picker("", selection: bindBlend) {
                    ForEach(BlendMode.allCases, id: \.self) { Text($0.label).tag($0) }
                }.pickerStyle(.menu).tint(Theme.accent)
            }
        }
    }

    private var transform: some View {
        card("Transform") {
            SliderRow(title: "Opacity", value: bindOpacity, range: 0...1) { editor.checkpoint() }
            SliderRow(title: "Scale", value: bindScale, range: 0.1...8, format: "%.2f×") { editor.checkpoint() }
            SliderRow(title: "Rotation", value: bindRotationDeg, range: -180...180, format: "%.0f°") { editor.checkpoint() }
        }
    }

    private var spinSection: some View {
        card("Spin animation") {
            Toggle(isOn: bindSpinEnabled) {
                Text("Spin forever").font(.system(size: 13, weight: .medium))
            }.tint(Theme.accent)
            if editor.selectedLayer?.spin.enabled == true {
                SliderRow(title: "Duration, s", value: bindSpinDuration, range: 3...120, format: "%.0f") { editor.checkpoint() }
                SliderRow(title: "Turns", value: bindSpinTurns, range: 0.25...5, format: "%.2f") { editor.checkpoint() }
                Toggle(isOn: bindSpinCW) { Text("Clockwise").font(.system(size: 13, weight: .medium)) }.tint(Theme.accent)
            }
        }
    }

    private var statesSection: some View {
        card("Lock → Home transition") {
            HStack {
                Text("Movement").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Picker("", selection: bindMove) {
                    ForEach(HomeMove.allCases, id: \.self) { Text($0.label).tag($0) }
                }.pickerStyle(.menu).tint(Theme.accent)
            }
            Text("“Exits…” flies the object off-screen on the Home Screen. “Flies in…” means the object rests on the Home Screen and isn’t on the Lock Screen — it appears from off-screen during the transition.")
                .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            Toggle(isOn: bindOnLock) { Text("Visible on Lock Screen").font(.system(size: 13, weight: .medium)) }.tint(Theme.accent)
            Toggle(isOn: bindOnHome) { Text("Visible on Home Screen").font(.system(size: 13, weight: .medium)) }.tint(Theme.accent)
            SliderRow(title: "Scale (Home Screen)", value: bindHomeScale, range: 0.2...2.5, format: "%.2f×") { editor.checkpoint() }
            Text("Preview the transition in the emulator (▶︎ at the top, swipe up).")
                .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
        }
    }

    @ViewBuilder
    private var contentControls: some View {
        if let layer = editor.selectedLayer {
            switch layer.content {
            case .text: textControls
            case .photo: photoControls
            case .sticker: stickerControls
            }
        }
    }

    private var textControls: some View {
        card("Text") {
            if case let .text(spec) = editor.selectedLayer?.content {
                TextField("Text", text: Binding(
                    get: { spec.string },
                    set: { v in editor.updateSelected { if case var .text(s) = $0.content { s.string = v; $0.content = .text(s) } } }))
                    .textFieldStyle(.roundedBorder).foregroundStyle(.black)
                SliderRow(title: "Font size", value: Binding(
                    get: { spec.fontSize },
                    set: { v in editor.updateSelected { if case var .text(s) = $0.content { s.fontSize = v; $0.content = .text(s) } } }),
                          range: 20...300, format: "%.0f")
                ColorPicker("Color", selection: Binding(
                    get: { spec.color.color },
                    set: { v in editor.updateSelected { if case var .text(s) = $0.content { s.color = RGBAColor(v); $0.content = .text(s) } } }))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
    }

    private var photoControls: some View {
        card("Photo") {
            if case let .photo(id, radius) = editor.selectedLayer?.content {
                SliderRow(title: "Corner radius", value: Binding(
                    get: { radius },
                    set: { v in editor.updateSelected { if case let .photo(pid, _) = $0.content { $0.content = .photo(imageID: pid, cornerRadius: v) } } }),
                          range: 0...200, format: "%.0f")
                Text("id: \(id.uuidString.prefix(8))").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var stickerControls: some View {
        card("Sticker") {
            if case let .sticker(symbol, color) = editor.selectedLayer?.content {
                Text(symbol).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                ColorPicker("Color", selection: Binding(
                    get: { color.color },
                    set: { v in editor.updateSelected { if case let .sticker(sym, _) = $0.content { $0.content = .sticker(symbol: sym, color: RGBAColor(v)) } } }))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
    }

    private func card<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.loc.uppercased()).font(.system(size: 11, weight: .bold)).tracking(0.6)
                .foregroundStyle(Theme.textSecondary)
            content()
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).panelCard()
    }

    private var bindDepth: Binding<DepthPlane> {
        .init(get: { editor.selectedLayer?.depth ?? .background },
              set: { v in editor.checkpoint(); editor.updateSelected { $0.depth = v } })
    }
    private var bindBlend: Binding<BlendMode> {
        .init(get: { editor.selectedLayer?.blend ?? .normal },
              set: { v in editor.checkpoint(); editor.updateSelected { $0.blend = v } })
    }
    private var bindOpacity: Binding<Double> {
        .init(get: { editor.selectedLayer?.opacity ?? 1 }, set: { v in editor.updateSelected { $0.opacity = v } })
    }
    private var bindScale: Binding<Double> {
        .init(get: { editor.selectedLayer?.scale ?? 1 }, set: { v in editor.updateSelected { $0.scale = v } })
    }
    private var bindRotationDeg: Binding<Double> {
        .init(get: { (editor.selectedLayer?.rotation ?? 0) * 180 / .pi },
              set: { v in editor.updateSelected { $0.rotation = v * .pi / 180 } })
    }
    private var bindSpinEnabled: Binding<Bool> {
        .init(get: { editor.selectedLayer?.spin.enabled ?? false },
              set: { v in editor.checkpoint(); editor.updateSelected { $0.spin.enabled = v } })
    }
    private var bindSpinDuration: Binding<Double> {
        .init(get: { editor.selectedLayer?.spin.duration ?? 30 }, set: { v in editor.updateSelected { $0.spin.duration = v } })
    }
    private var bindSpinTurns: Binding<Double> {
        .init(get: { editor.selectedLayer?.spin.turns ?? 1 }, set: { v in editor.updateSelected { $0.spin.turns = v } })
    }
    private var bindSpinCW: Binding<Bool> {
        .init(get: { editor.selectedLayer?.spin.clockwise ?? true }, set: { v in editor.updateSelected { $0.spin.clockwise = v } })
    }
    private var bindOnLock: Binding<Bool> {
        .init(get: { editor.selectedLayer?.states.onLock ?? true },
              set: { v in editor.checkpoint(); editor.updateSelected { $0.states.onLock = v } })
    }
    private var bindOnHome: Binding<Bool> {
        .init(get: { editor.selectedLayer?.states.onHome ?? true },
              set: { v in editor.checkpoint(); editor.updateSelected { $0.states.onHome = v } })
    }
    private var bindMove: Binding<HomeMove> {
        .init(get: { editor.selectedLayer?.states.move ?? .none },
              set: { v in editor.checkpoint(); editor.updateSelected { $0.states.move = v } })
    }
    private var bindHomeScale: Binding<Double> {
        .init(get: { editor.selectedLayer?.states.homeScale ?? 1 }, set: { v in editor.updateSelected { $0.states.homeScale = v } })
    }
}

struct EffectsSheet: View {
    @Bindable var editor: EditorState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(Effects.catalog) { preset in
                        Button { preset.apply(editor); dismiss() } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: preset.symbol).font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                                Text(preset.title).font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(preset.subtitle).font(.system(size: 11))
                                    .foregroundStyle(Theme.textSecondary).lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                            .padding(14)
                            .panelCard()
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Effects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}
