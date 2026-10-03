import SwiftUI
import UIKit

enum SpriteShape { case softCircle, streak, petal, square, ring, star }

struct ParticleStyle {
    var shape: SpriteShape
    var colors: [RGBAColor]
    var sizeRange: ClosedRange<Double>
    var crossRange: ClosedRange<Double>
    var rises: Bool
    var swayRange: ClosedRange<Double>
    var rotates: Bool
    var flickers: Bool
    var opacityRange: ClosedRange<Double>
    var baseCount: Int
}

struct Particle {
    var x: Double
    var size: Double
    var cross: Double
    var phase: Double
    var sway: Double
    var colorIndex: Int
    var opacity: Double
    var spinTurns: Double
}

private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(_ seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

enum ParticleSystem {
    static func style(for kind: ParticleKind) -> ParticleStyle? {
        switch kind {
        case .none:
            return nil
        case .snow:
            return ParticleStyle(shape: .softCircle,
                                 colors: [RGBAColor(r: 1, g: 1, b: 1)],
                                 sizeRange: 4...18, crossRange: 7...16, rises: false,
                                 swayRange: 14...44, rotates: false, flickers: false,
                                 opacityRange: 0.5...1.0, baseCount: 120)
        case .rain:
            return ParticleStyle(shape: .streak,
                                 colors: [RGBAColor(r: 0.75, g: 0.85, b: 1.0)],
                                 sizeRange: 7...16, crossRange: 0.9...2.2, rises: false,
                                 swayRange: 0...0, rotates: false, flickers: false,
                                 opacityRange: 0.3...0.7, baseCount: 120)
        case .sakura:
            return ParticleStyle(shape: .petal,
                                 colors: [RGBAColor(r: 1, g: 0.72, b: 0.82),
                                          RGBAColor(r: 1, g: 0.6, b: 0.75),
                                          RGBAColor(r: 1, g: 0.85, b: 0.9)],
                                 sizeRange: 8...18, crossRange: 6...13, rises: false,
                                 swayRange: 20...50, rotates: true, flickers: false,
                                 opacityRange: 0.7...1.0, baseCount: 55)
        case .embers:
            return ParticleStyle(shape: .softCircle,
                                 colors: [RGBAColor(r: 1, g: 0.6, b: 0.2),
                                          RGBAColor(r: 1, g: 0.4, b: 0.1),
                                          RGBAColor(r: 1, g: 0.8, b: 0.3)],
                                 sizeRange: 2...7, crossRange: 5...11, rises: true,
                                 swayRange: 8...26, rotates: false, flickers: true,
                                 opacityRange: 0.4...0.95, baseCount: 70)
        case .stars:
            return ParticleStyle(shape: .star,
                                 colors: [RGBAColor(r: 1, g: 1, b: 0.9),
                                          RGBAColor(r: 0.8, g: 0.9, b: 1)],
                                 sizeRange: 5...13, crossRange: 9...18, rises: false,
                                 swayRange: 0...8, rotates: true, flickers: true,
                                 opacityRange: 0.5...1.0, baseCount: 45)
        case .confetti:
            return ParticleStyle(shape: .square,
                                 colors: [RGBAColor(r: 0.95, g: 0.3, b: 0.4),
                                          RGBAColor(r: 0.3, g: 0.6, b: 0.98),
                                          RGBAColor(r: 1, g: 0.8, b: 0.2),
                                          RGBAColor(r: 0.35, g: 0.85, b: 0.5)],
                                 sizeRange: 7...15, crossRange: 4...9, rises: false,
                                 swayRange: 18...46, rotates: true, flickers: false,
                                 opacityRange: 0.85...1.0, baseCount: 70)
        case .bubbles:
            return ParticleStyle(shape: .ring,
                                 colors: [RGBAColor(r: 0.8, g: 0.95, b: 1)],
                                 sizeRange: 6...22, crossRange: 6...13, rises: true,
                                 swayRange: 14...38, rotates: false, flickers: false,
                                 opacityRange: 0.3...0.7, baseCount: 55)
        }
    }

    static func particles(for effect: ParticleEffect) -> [Particle] {
        guard let s = style(for: effect.kind) else { return [] }
        let count = max(6, Int(Double(s.baseCount) * (0.25 + effect.intensity)))
        let speedMul = 1.7 - effect.speed
        var rng = SeededRNG(UInt64(effect.kind.hashValue & 0xFFFFFFFF) ^ 0xABCDEF)
        func rnd(_ r: ClosedRange<Double>) -> Double { Double.random(in: r, using: &rng) }
        let fluffMul = s.shape == .softCircle ? (0.7 + effect.fluffy * 0.9) : 1.0
        return (0..<count).map { _ in
            Particle(
                x: rnd(0...1),
                size: rnd(s.sizeRange) * fluffMul,
                cross: rnd(s.crossRange) * speedMul,
                phase: rnd(0...1),
                sway: rnd(s.swayRange),
                colorIndex: s.colors.isEmpty ? 0 : Int.random(in: 0..<s.colors.count, using: &rng),
                opacity: rnd(s.opacityRange),
                spinTurns: s.rotates ? rnd(0.5...2.5) : 0)
        }
    }

    static func sprite(shape: SpriteShape, color: RGBAColor, pixels: CGFloat = 48) -> UIImage {
        let size = CGSize(width: pixels, height: shape == .streak ? pixels * 3 : pixels)
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 1; fmt.opaque = false
        return UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            let c = ctx.cgContext
            let ui = UIColor(red: color.r, green: color.g, blue: color.b, alpha: 1)
            let rect = CGRect(origin: .zero, size: size)
            switch shape {
            case .softCircle:

                let colors = [ui.withAlphaComponent(1).cgColor,
                              ui.withAlphaComponent(0.55).cgColor,
                              ui.withAlphaComponent(0).cgColor] as CFArray
                let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                                      locations: [0, 0.45, 1])!
                c.drawRadialGradient(grad, startCenter: CGPoint(x: pixels/2, y: pixels/2), startRadius: 0,
                                     endCenter: CGPoint(x: pixels/2, y: pixels/2), endRadius: pixels/2,
                                     options: [])
            case .streak:
                ui.setFill()
                let path = UIBezierPath(roundedRect: CGRect(x: pixels*0.4, y: 0, width: pixels*0.2, height: size.height),
                                        cornerRadius: pixels*0.1)
                path.fill()
            case .petal:
                ui.setFill()
                UIBezierPath(ovalIn: rect.insetBy(dx: pixels*0.18, dy: pixels*0.02)).fill()
            case .square:
                ui.setFill(); c.fill(rect.insetBy(dx: pixels*0.1, dy: pixels*0.1))
            case .ring:
                ui.setStroke()
                let p = UIBezierPath(ovalIn: rect.insetBy(dx: pixels*0.14, dy: pixels*0.14))
                p.lineWidth = pixels*0.08; p.stroke()
            case .star:
                ui.setFill(); starPath(in: rect.insetBy(dx: pixels*0.08, dy: pixels*0.08)).fill()
            }
        }
    }

    private static func starPath(in rect: CGRect) -> UIBezierPath {
        let p = UIBezierPath()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOuter = min(rect.width, rect.height) / 2
        let rInner = rOuter * 0.42
        for i in 0..<10 {
            let r = i % 2 == 0 ? rOuter : rInner
            let a = Double(i) * .pi / 5 - .pi / 2
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.close()
        return p
    }
}
