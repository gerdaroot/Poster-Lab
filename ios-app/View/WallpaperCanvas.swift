import SwiftUI

struct WallpaperCanvas: View {
    let project: WallpaperProject
    let size: CGSize
    var animated: Bool = true

    var stateProgress: Double? = nil

    private var scale: CGFloat { size.width / 1000 }

    private var anySpinning: Bool { project.layers.contains { $0.spin.enabled && !$0.isHidden } }

    var body: some View {

        TimelineView(.animation(paused: !(animated && anySpinning))) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                background
                ForEach(project.layers) { layer in
                    if !layer.isHidden {
                        let st = stateEffect(layer)
                        layerView(layer)
                            .rotationEffect(spinAngle(layer, t))
                            .scaleEffect(st.scale)
                            .position(x: (layer.position.x + st.dx) * size.width,
                                      y: (layer.position.y + st.dy) * size.height)
                            .opacity(layer.opacity * st.opacity)
                    }
                }
                if animated, project.particles.kind != .none {
                    ParticleOverlay(effect: project.particles, size: size)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }

    private func spinAngle(_ layer: Layer, _ t: TimeInterval) -> Angle {
        guard animated, layer.spin.enabled, layer.spin.duration > 0 else { return .zero }
        let dir = layer.spin.clockwise ? 1.0 : -1.0
        let turns = (t / layer.spin.duration) * layer.spin.turns
        return .radians(dir * turns.truncatingRemainder(dividingBy: 1) * 2 * .pi)
    }

    private func stateEffect(_ layer: Layer) -> (dx: CGFloat, dy: CGFloat, opacity: Double, scale: CGFloat) {
        guard let p = stateProgress else { return (0, 0, 1, 1) }
        let s = layer.states
        let (lockP, homeP) = s.positions(base: layer.position)
        let curX = lockP.x + (homeP.x - lockP.x) * p
        let curY = lockP.y + (homeP.y - lockP.y) * p
        let lockO = s.onLock ? 1.0 : 0.0
        let homeO = s.onHome ? 1.0 : 0.0
        let opacity = lockO + (homeO - lockO) * p
        let scale = 1 + (s.homeScale - 1) * p
        return (CGFloat(curX - layer.position.x), CGFloat(curY - layer.position.y), opacity, CGFloat(scale))
    }

    @ViewBuilder
    private var background: some View {
        switch project.background {
        case let .solid(color):
            color.color
        case let .gradient(spec):
            gradientView(spec)
        case let .photo(imageID):
            if let img = ImageStore.shared.load(imageID) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                Color.black
            }
        }
    }

    @ViewBuilder
    private func gradientView(_ spec: GradientSpec) -> some View {
        switch spec.kind {
        case .linear:
            let a = Angle(degrees: spec.angle)
            LinearGradient(gradient: spec.gradient,
                           startPoint: unitPoint(for: a, start: true),
                           endPoint: unitPoint(for: a, start: false))
        case .radial:
            RadialGradient(gradient: spec.gradient, center: .center,
                           startRadius: 0, endRadius: max(size.width, size.height) * 0.7)
        case .angular:
            AngularGradient(gradient: spec.gradient, center: .center,
                            angle: Angle(degrees: spec.angle))
        }
    }

    private func unitPoint(for angle: Angle, start: Bool) -> UnitPoint {
        let rad = angle.radians
        let dx = cos(rad) * 0.5, dy = sin(rad) * 0.5
        return start ? UnitPoint(x: 0.5 - dx, y: 0.5 - dy)
                     : UnitPoint(x: 0.5 + dx, y: 0.5 + dy)
    }

    @ViewBuilder
    private func layerView(_ layer: Layer) -> some View {
        Group {
            switch layer.content {
            case let .text(spec):
                textView(spec)
                    .scaleEffect(layer.scale)
            case let .photo(imageID, cornerRadius):
                if let img = ImageStore.shared.load(imageID) {

                    let aspect = img.size.height > 0 ? img.size.width / img.size.height : 1
                    let w = 600 * scale
                    let h = w / max(0.25, min(4, aspect))
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius * scale, style: .continuous))
                        .scaleEffect(layer.scale)
                }
            case let .sticker(symbol, color):
                Image(systemName: symbol)
                    .font(.system(size: 240 * scale, weight: .semibold))
                    .foregroundStyle(color.color)
                    .scaleEffect(layer.scale)
            }
        }
        .rotationEffect(.radians(layer.rotation))
    }

    @ViewBuilder
    private func textView(_ spec: TextSpec) -> some View {
        let font: Font = spec.fontName.isEmpty
            ? .system(size: spec.fontSize * scale, weight: spec.fontWeight)
            : .custom(spec.fontName, size: spec.fontSize * scale)
        Text(spec.string.isEmpty ? " " : spec.string)
            .font(font)
            .fontWeight(spec.fontName.isEmpty ? spec.fontWeight : nil)
            .tracking(spec.tracking * scale)
            .lineSpacing(spec.lineSpacing * scale)
            .multilineTextAlignment(spec.textAlignment)
            .foregroundStyle(spec.color.color)
            .frame(maxWidth: 880 * scale, alignment: spec.frameAlignment)
            .fixedSize(horizontal: false, vertical: true)
    }
}
