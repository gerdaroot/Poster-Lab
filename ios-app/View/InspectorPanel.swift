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
                    animationsSection
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
        .sheet(item: $editingAnimation) { anim in
            CustomAnimationEditor(editor: editor, animationID: anim.id)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddAnimation) {
            KeyPathPicker { kp in
                guard let layer = editor.selectedLayer else { return }
                editor.checkpoint()
                let anim = CustomAnimation.starter(for: kp)
                var updated = layer
                updated.animations.append(anim)
                editor.selectedLayer = updated
                showAddAnimation = false
                editingAnimation = IDBox(id: anim.id)
            }
            .presentationDetents([.medium])
        }
    }

    @State private var showAddAnimation = false
    @State private var editingAnimation: IDBox? = nil

    private var animationsSection: some View {
        card("Custom animations") {
            if let layer = editor.selectedLayer, !layer.animations.isEmpty {
                ForEach(layer.animations) { anim in
                    animationRow(anim)
                }
            } else {
                Text("No animations yet. Add one — any CoreAnimation keyPath with your own keyframes.")
                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }

            Button {
                showAddAnimation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add animation")
                }
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 36)
                .foregroundStyle(Theme.accent)
                .background(Theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private func animationRow(_ anim: CustomAnimation) -> some View {
        Button {
            editingAnimation = IDBox(id: anim.id)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: anim.keyPath.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(anim.keyPath.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(anim.keyframes.count) kf · \(String(format: "%.1fs", anim.duration))\(anim.repeatForever ? " · ∞" : "")\(anim.autoreverses ? " · ↔" : "")")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button(role: .destructive) {
                    guard var layer = editor.selectedLayer else { return }
                    editor.checkpoint()
                    layer.animations.removeAll { $0.id == anim.id }
                    editor.selectedLayer = layer
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.borderless)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(10)
            .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
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

struct IDBox: Identifiable {
    var id: UUID
}

struct KeyPathPicker: View {
    var onPick: (AnimKeyPath) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    ForEach(AnimKeyPath.allCases) { kp in
                        Button {
                            onPick(kp)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: kp.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Theme.accent)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Text(kp.label)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(kp.rawValue)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Pick property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct CustomAnimationEditor: View {
    @Bindable var editor: EditorState
    let animationID: UUID
    @Environment(\.dismiss) private var dismiss

    private var binding: Binding<CustomAnimation>? {
        guard let layer = editor.selectedLayer,
              let idx = layer.animations.firstIndex(where: { $0.id == animationID }) else { return nil }
        return Binding(
            get: {
                editor.selectedLayer?.animations[idx] ?? CustomAnimation(keyPath: .opacity, keyframes: [])
            },
            set: { newVal in
                guard var l = editor.selectedLayer,
                      let i = l.animations.firstIndex(where: { $0.id == animationID }) else { return }
                l.animations[i] = newVal
                editor.selectedLayer = l
            }
        )
    }

    var body: some View {
        NavigationStack {
            if let bind = binding {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header(bind.wrappedValue)

                        timingCard(bind)

                        keyframesCard(bind)

                        Spacer(minLength: 20)
                    }
                    .padding(14)
                }
                .background(Theme.bg)
                .navigationTitle(bind.wrappedValue.keyPath.label)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                }
            } else {
                Text("Animation not found")
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func header(_ a: CustomAnimation) -> some View {
        HStack(spacing: 10) {
            Image(systemName: a.keyPath.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 40, height: 40)
                .background(Theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(a.keyPath.label).font(.headline)
                Text(a.keyPath.rawValue).font(.caption.monospaced()).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    private func timingCard(_ bind: Binding<CustomAnimation>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timing").font(.caption.bold()).foregroundStyle(Theme.textSecondary)
            SliderRow(title: "Duration, s", value: bind.duration, range: 0.1...60, format: "%.2f") { editor.checkpoint() }
            SliderRow(title: "Delay offset, s", value: bind.timeOffset, range: 0...30, format: "%.2f") { editor.checkpoint() }
            HStack {
                Text("Easing").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary)
                Spacer()
                Picker("", selection: bind.timing) {
                    ForEach(AnimTimingFunction.allCases) { t in Text(t.label).tag(t) }
                }.pickerStyle(.menu).tint(Theme.accent)
            }
            Toggle(isOn: bind.repeatForever) { Text("Repeat forever").font(.system(size: 13, weight: .medium)) }.tint(Theme.accent)
            Toggle(isOn: bind.autoreverses) { Text("Autoreverse (play back and forth)").font(.system(size: 13, weight: .medium)) }.tint(Theme.accent)
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func keyframesCard(_ bind: Binding<CustomAnimation>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Keyframes (\(bind.wrappedValue.keyframes.count))").font(.caption.bold()).foregroundStyle(Theme.textSecondary)
                Spacer()
                Button {
                    editor.checkpoint()
                    let kp = bind.wrappedValue.keyPath
                    let last = bind.wrappedValue.keyframes.last?.value ?? kp.defaultEnd
                    let lastT = bind.wrappedValue.keyframes.last?.time ?? 0
                    let t = min(1, lastT + 0.25)
                    bind.wrappedValue.keyframes.append(AnimKeyframe(time: t, value: last))
                    bind.wrappedValue.keyframes.sort { $0.time < $1.time }
                } label: {
                    Label("Add keyframe", systemImage: "plus")
                        .font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.accent.opacity(0.14), in: Capsule())
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }

            ForEach(bind.wrappedValue.keyframes) { kf in
                keyframeRow(bind, kf.id)
            }

            Text("Time: 0 = animation start, 1 = animation end. Value is in CoreAnimation units — same keyPath you'd use in CAPlayground.")
                .font(.system(size: 10))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func keyframeRow(_ bind: Binding<CustomAnimation>, _ kfID: UUID) -> some View {
        let kp = bind.wrappedValue.keyPath
        let idx = bind.wrappedValue.keyframes.firstIndex(where: { $0.id == kfID })

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let i = idx {
                    Text("#\(i + 1)")
                        .font(.caption2.monospaced().bold())
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if bind.wrappedValue.keyframes.count > 2 {
                    Button(role: .destructive) {
                        editor.checkpoint()
                        bind.wrappedValue.keyframes.removeAll { $0.id == kfID }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red.opacity(0.75))
                    }
                    .buttonStyle(.borderless)
                }
            }

            SliderRow(title: "Time", value: Binding(
                get: { bind.wrappedValue.keyframes.first { $0.id == kfID }?.time ?? 0 },
                set: { v in
                    if let i = bind.wrappedValue.keyframes.firstIndex(where: { $0.id == kfID }) {
                        bind.wrappedValue.keyframes[i].time = v
                    }
                }
            ), range: 0...1, format: "%.2f") { editor.checkpoint() }

            SliderRow(title: "Value", value: Binding(
                get: { bind.wrappedValue.keyframes.first { $0.id == kfID }?.value ?? 0 },
                set: { v in
                    if let i = bind.wrappedValue.keyframes.firstIndex(where: { $0.id == kfID }) {
                        bind.wrappedValue.keyframes[i].value = v
                    }
                }
            ), range: kp.defaultRange, format: valueFormat(for: kp)) { editor.checkpoint() }
        }
        .padding(10)
        .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func valueFormat(for kp: AnimKeyPath) -> String {
        switch kp {
        case .rotationZ: return "%.2f rad"
        case .opacity, .scale, .scaleX, .scaleY: return "%.2f"
        default: return "%.0f"
        }
    }
}
