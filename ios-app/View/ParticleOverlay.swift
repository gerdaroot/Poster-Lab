import SwiftUI

struct ParticleOverlay: View {
    let effect: ParticleEffect
    let size: CGSize

    var body: some View {
        if let style = ParticleSystem.style(for: effect.kind) {
            let particles = ParticleSystem.particles(for: effect)
            let scale = size.width / 390.0
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, canvas in
                    for p in particles {
                        draw(p, style: style, t: t, scale: scale, in: canvas, ctx: &ctx)
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func draw(_ p: Particle, style: ParticleStyle, t: Double, scale: CGFloat,
                      in canvas: CGSize, ctx: inout GraphicsContext) {
        let w = p.size * Double(scale)
        let h = (style.shape == .streak ? p.size * 3 : p.size) * Double(scale)
        let margin = h + 4
        let travel = Double(canvas.height) + margin * 2
        var progress = (t / p.cross + p.phase).truncatingRemainder(dividingBy: 1)
        if progress < 0 { progress += 1 }
        let yRaw = style.rises ? (1 - progress) * travel - margin : progress * travel - margin
        let swayX = p.sway * Double(scale) * sin(2 * .pi * (t / max(1, p.cross * 0.5) + p.phase))
        let angleRad = effect.angle * .pi / 180
        let driftX = tan(angleRad) * (progress - 0.5) * travel
        let cx = p.x * Double(canvas.width) + swayX + driftX
        let center = CGPoint(x: cx, y: yRaw)

        var opacity = p.opacity
        if style.flickers {
            opacity *= 0.5 + 0.5 * (0.5 + 0.5 * sin(2 * .pi * (t / max(0.6, p.cross * 0.12) + p.phase)))
        }
        let color = style.colors[min(p.colorIndex, style.colors.count - 1)]
        let ui = Color(.sRGB, red: color.r, green: color.g, blue: color.b, opacity: opacity)
        let rect = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)

        var sub = ctx
        if p.spinTurns > 0 {
            sub.translateBy(x: center.x, y: center.y)
            sub.rotate(by: .radians(p.spinTurns * 2 * .pi * progress))
            sub.translateBy(x: -center.x, y: -center.y)
        }

        switch style.shape {
        case .softCircle:
            sub.fill(Circle().path(in: rect), with: .radialGradient(
                Gradient(stops: [.init(color: ui, location: 0),
                                 .init(color: ui.opacity(0.55), location: 0.45),
                                 .init(color: ui.opacity(0), location: 1)]),
                center: center, startRadius: 0, endRadius: w / 2))
        case .streak:
            sub.fill(Capsule().path(in: CGRect(x: center.x - w * 0.12, y: rect.minY, width: w * 0.24, height: h)), with: .color(ui))
        case .petal:
            sub.fill(Ellipse().path(in: rect.insetBy(dx: w * 0.16, dy: 0)), with: .color(ui))
        case .square:
            sub.fill(Path(rect), with: .color(ui))
        case .ring:
            sub.stroke(Circle().path(in: rect.insetBy(dx: w * 0.12, dy: w * 0.12)), with: .color(ui), lineWidth: w * 0.09)
        case .star:
            sub.fill(starPath(in: rect), with: .color(ui))
        }
    }

    private func starPath(in rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOuter = min(rect.width, rect.height) / 2
        let rInner = rOuter * 0.42
        for i in 0..<10 {
            let r = i % 2 == 0 ? rOuter : rInner
            let a = Double(i) * .pi / 5 - .pi / 2
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}
