import SwiftUI

struct EffectPreset: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let apply: (EditorState) -> Void
}

enum Effects {

    static let catalog: [EffectPreset] = [
        EffectPreset(title: String(localized: "In front of clock"), subtitle: String(localized: "Layer floats above the time (depth)"),
                     symbol: "person.crop.rectangle.stack") { e in
            e.checkpoint(); e.updateSelected { $0.depth = .foreground }
        },
        EffectPreset(title: String(localized: "Send to background"), subtitle: String(localized: "Layer goes behind the clock"),
                     symbol: "square.3.layers.3d.bottom.filled") { e in
            e.checkpoint(); e.updateSelected { $0.depth = .background }
        },
        EffectPreset(title: String(localized: "Glow"), subtitle: String(localized: "Soft Screen blend"),
                     symbol: "sparkles") { e in
            e.checkpoint(); e.updateSelected { $0.blend = .screenBlendMode; $0.opacity = 0.9 }
        },
        EffectPreset(title: String(localized: "Smooth spin"), subtitle: String(localized: "1 turn per 30s"),
                     symbol: "arrow.clockwise") { e in
            e.checkpoint(); e.updateSelected { $0.spin = SpinSpec(enabled: true, turns: 1, duration: 30, clockwise: true) }
        },
        EffectPreset(title: String(localized: "Ring of copies"), subtitle: String(localized: "6 spinning copies in a ring"),
                     symbol: "circle.grid.hex") { e in
            ring(e, count: 6, radius: 0.28)
        },
        EffectPreset(title: String(localized: "Reset"), subtitle: String(localized: "Normal look, no animation"),
                     symbol: "arrow.uturn.backward") { e in
            e.checkpoint(); e.updateSelected { $0.blend = .normal; $0.spin = SpinSpec(); $0.opacity = 1 }
        },
    ]

    private static func ring(_ e: EditorState, count: Int, radius: Double) {
        guard let base = e.selectedLayer else { return }
        e.checkpoint()
        let center = base.position
        for i in 0..<count {
            let angle = Double(i) / Double(count) * 2 * .pi
            var copy = base
            copy.id = UUID()
            copy.name = "\(base.name) \(i + 1)"
            copy.position = CGPoint(x: min(max(center.x + cos(angle) * radius, 0.02), 0.98),
                                    y: min(max(center.y + sin(angle) * radius, 0.02), 0.98))
            copy.spin = SpinSpec(enabled: true, turns: 1,
                                 duration: 20 + Double(i) * 6, clockwise: i % 2 == 0)
            e.project.layers.append(copy)
        }
    }
}
