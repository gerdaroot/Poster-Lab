import SwiftUI

enum Theme {

    static let bg = Color(.sRGB, red: 0.086, green: 0.082, blue: 0.078)
    static let surface = Color(.sRGB, red: 0.142, green: 0.135, blue: 0.128)
    static let surfaceHigh = Color(.sRGB, red: 0.205, green: 0.195, blue: 0.183)
    static let stroke = Color.white.opacity(0.08)
    static let textPrimary = Color(.sRGB, red: 0.97, green: 0.96, blue: 0.95)
    static let textSecondary = Color.white.opacity(0.52)

    static let accent = Color(.sRGB, red: 1.0, green: 0.33, blue: 0.22)
    static let accent2 = Color(.sRGB, red: 1.0, green: 0.76, blue: 0.24)
    static let accentSoft = Color(.sRGB, red: 1.0, green: 0.33, blue: 0.22).opacity(0.16)

    static let accentGradient = LinearGradient(
        colors: [Color(.sRGB, red: 1.0, green: 0.33, blue: 0.22),
                 Color(.sRGB, red: 1.0, green: 0.55, blue: 0.2)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let corner: CGFloat = 24
    static let cornerSmall: CGFloat = 15

    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 16
    static let s4: CGFloat = 24
    static let s5: CGFloat = 32

    static func display(_ size: CGFloat, _ weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension View {

    func panelCard() -> some View {
        self
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1))
    }
}

struct ToolButton: View {
    let systemName: String
    var label: String? = nil
    var tint: Color = Theme.textPrimary
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName).font(.system(size: 18, weight: .semibold))
                if let label { Text(label).font(.system(size: 10, weight: .medium)) }
            }
            .foregroundStyle(isDisabled ? Theme.textSecondary.opacity(0.4) : tint)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .disabled(isDisabled)
    }
}
