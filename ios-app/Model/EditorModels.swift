import SwiftUI

struct RGBAColor: Codable, Hashable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    init(_ color: Color) {
        let ui = UIColor(color)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        ui.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        r = Double(rr); g = Double(gg); b = Double(bb); a = Double(aa)
    }

    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }

    static let white = RGBAColor(r: 1, g: 1, b: 1)
    static let black = RGBAColor(r: 0, g: 0, b: 0)
    static let accent = RGBAColor(r: 0.36, g: 0.45, b: 0.98)
}

struct GradientSpec: Codable, Hashable {
    enum Kind: Int, Codable, CaseIterable { case linear, radial, angular }

    struct Stop: Codable, Hashable, Identifiable {
        var id = UUID()
        var color: RGBAColor
        var location: Double
    }

    var kind: Kind = .linear
    var stops: [Stop]
    var angle: Double = 90

    var gradient: Gradient {
        Gradient(stops: stops
            .sorted { $0.location < $1.location }
            .map { .init(color: $0.color.color, location: $0.location) })
    }

    static let sunset = GradientSpec(
        kind: .linear,
        stops: [.init(color: RGBAColor(r: 0.98, g: 0.36, b: 0.45), location: 0),
                .init(color: RGBAColor(r: 0.36, g: 0.24, b: 0.62), location: 1)],
        angle: 120)

    static let midnight = GradientSpec(
        kind: .linear,
        stops: [.init(color: RGBAColor(r: 0.05, g: 0.06, b: 0.12), location: 0),
                .init(color: RGBAColor(r: 0.16, g: 0.20, b: 0.42), location: 1)],
        angle: 135)
}

enum BackgroundStyle: Codable, Hashable {
    case solid(RGBAColor)
    case gradient(GradientSpec)
    case photo(imageID: UUID)
}

struct TextSpec: Codable, Hashable {
    var string: String = "Text"
    var fontName: String = ""
    var fontSize: Double = 96
    var weight: Int = 5
    var color: RGBAColor = .white
    var tracking: Double = 0
    var lineSpacing: Double = 0
    var alignment: Int = 1

    static let weights: [Font.Weight] = [
        .ultraLight, .thin, .light, .regular, .medium,
        .semibold, .bold, .heavy, .black,
    ]
    var fontWeight: Font.Weight { TextSpec.weights[min(max(weight, 0), TextSpec.weights.count - 1)] }
    var textAlignment: TextAlignment {
        switch alignment { case 0: return .leading; case 2: return .trailing; default: return .center }
    }
    var frameAlignment: Alignment {
        switch alignment { case 0: return .leading; case 2: return .trailing; default: return .center }
    }
}

enum LayerContent: Codable, Hashable {
    case text(TextSpec)
    case photo(imageID: UUID, cornerRadius: Double)
    case sticker(symbol: String, color: RGBAColor)
}

enum BlendMode: String, Codable, CaseIterable, Hashable {
    case normal
    case screenBlendMode
    case multiplyBlendMode
    case overlayBlendMode
    case exclusionBlendMode
    case lightenBlendMode
    case darkenBlendMode
    case linearDodgeBlendMode
    case colorDodgeBlendMode

    var label: String {
        switch self {
        case .normal: return String(localized: "Normal")
        case .screenBlendMode: return String(localized: "Screen")
        case .multiplyBlendMode: return String(localized: "Multiply")
        case .overlayBlendMode: return String(localized: "Overlay")
        case .exclusionBlendMode: return String(localized: "Exclusion")
        case .lightenBlendMode: return String(localized: "Lighten")
        case .darkenBlendMode: return String(localized: "Darken")
        case .linearDodgeBlendMode: return String(localized: "Linear Dodge")
        case .colorDodgeBlendMode: return String(localized: "Color Dodge")
        }
    }
}

enum DepthPlane: Int, Codable, CaseIterable, Hashable {
    case background = 0
    case floating = 1
    case foreground = 2

    var label: String {
        switch self {
        case .background: return String(localized: "Background")
        case .floating: return String(localized: "Middle")
        case .foreground: return String(localized: "In front of clock")
        }
    }
    var systemImage: String {
        switch self {
        case .background: return "square.3.layers.3d.bottom.filled"
        case .floating: return "square.3.layers.3d.middle.filled"
        case .foreground: return "square.3.layers.3d.top.filled"
        }
    }
}

struct SpinSpec: Codable, Hashable {
    var enabled: Bool = false
    var turns: Double = 1
    var duration: Double = 30
    var clockwise: Bool = true
}

enum HomeMove: String, Codable, CaseIterable, Hashable {
    case none
    case exitLeft, exitRight, exitUp, exitDown
    case enterLeft, enterRight, enterUp, enterDown

    var label: String {
        switch self {
        case .none: return String(localized: "Stays in place")
        case .exitLeft: return String(localized: "Exits left")
        case .exitRight: return String(localized: "Exits right")
        case .exitUp: return String(localized: "Exits up")
        case .exitDown: return String(localized: "Exits down")
        case .enterLeft: return String(localized: "Flies in from left")
        case .enterRight: return String(localized: "Flies in from right")
        case .enterUp: return String(localized: "Flies in from top")
        case .enterDown: return String(localized: "Flies in from bottom")
        }
    }

    var isEnter: Bool {
        switch self { case .enterLeft, .enterRight, .enterUp, .enterDown: return true; default: return false }
    }

    var offset: (dx: Double, dy: Double) {
        let a = 1.3
        switch self {
        case .exitLeft, .enterLeft: return (-a, 0)
        case .exitRight, .enterRight: return (a, 0)
        case .exitUp, .enterUp: return (0, -a)
        case .exitDown, .enterDown: return (0, a)
        case .none: return (0, 0)
        }
    }
}

struct StateBehavior: Codable, Hashable {
    var onLock: Bool = true
    var onHome: Bool = true
    var move: HomeMove = .none
    var homeScale: Double = 1

    var isDefault: Bool { onLock && onHome && move == .none && homeScale == 1 }

    func positions(base: CGPoint) -> (lock: CGPoint, home: CGPoint) {
        let o = move.offset
        if move.isEnter {

            return (CGPoint(x: base.x + o.dx, y: base.y + o.dy), base)
        } else {

            return (base, CGPoint(x: base.x + o.dx, y: base.y + o.dy))
        }
    }

    enum CodingKeys: String, CodingKey { case onLock, onHome, move, homeScale }
    init() {}
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        onLock = try c.decodeIfPresent(Bool.self, forKey: .onLock) ?? true
        onHome = try c.decodeIfPresent(Bool.self, forKey: .onHome) ?? true
        move = try c.decodeIfPresent(HomeMove.self, forKey: .move) ?? .none
        homeScale = try c.decodeIfPresent(Double.self, forKey: .homeScale) ?? 1
    }
}

struct Layer: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var content: LayerContent
    var position: CGPoint = CGPoint(x: 0.5, y: 0.5)
    var scale: Double = 1
    var rotation: Double = 0
    var opacity: Double = 1
    var isHidden: Bool = false

    var blend: BlendMode = .normal
    var depth: DepthPlane = .background
    var spin: SpinSpec = SpinSpec()
    var states: StateBehavior = StateBehavior()

    var symbolName: String {
        switch content {
        case .text: return "textformat"
        case .photo: return "photo"
        case .sticker: return "star"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, content, position, scale, rotation, opacity, isHidden
        case blend, depth, spin, states
    }

    init(id: UUID = UUID(), name: String, content: LayerContent,
         position: CGPoint = CGPoint(x: 0.5, y: 0.5), scale: Double = 1,
         rotation: Double = 0, opacity: Double = 1, isHidden: Bool = false,
         blend: BlendMode = .normal, depth: DepthPlane = .background,
         spin: SpinSpec = SpinSpec(), states: StateBehavior = StateBehavior()) {
        self.id = id; self.name = name; self.content = content
        self.position = position; self.scale = scale; self.rotation = rotation
        self.opacity = opacity; self.isHidden = isHidden
        self.blend = blend; self.depth = depth; self.spin = spin; self.states = states
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        content = try c.decode(LayerContent.self, forKey: .content)
        position = try c.decodeIfPresent(CGPoint.self, forKey: .position) ?? CGPoint(x: 0.5, y: 0.5)
        scale = try c.decodeIfPresent(Double.self, forKey: .scale) ?? 1
        rotation = try c.decodeIfPresent(Double.self, forKey: .rotation) ?? 0
        opacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? 1
        isHidden = try c.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
        blend = try c.decodeIfPresent(BlendMode.self, forKey: .blend) ?? .normal
        depth = try c.decodeIfPresent(DepthPlane.self, forKey: .depth) ?? .background
        spin = try c.decodeIfPresent(SpinSpec.self, forKey: .spin) ?? SpinSpec()
        states = try c.decodeIfPresent(StateBehavior.self, forKey: .states) ?? StateBehavior()
    }
}

enum ParticleKind: String, Codable, CaseIterable, Hashable {
    case none, snow, rain, sakura, embers, stars, confetti, bubbles

    var label: String {
        switch self {
        case .none: return String(localized: "None")
        case .snow: return String(localized: "Snow")
        case .rain: return String(localized: "Rain")
        case .sakura: return String(localized: "Petals")
        case .embers: return String(localized: "Embers")
        case .stars: return String(localized: "Stars")
        case .confetti: return String(localized: "Confetti")
        case .bubbles: return String(localized: "Bubbles")
        }
    }
    var symbol: String {
        switch self {
        case .none: return "nosign"
        case .snow: return "snowflake"
        case .rain: return "cloud.rain"
        case .sakura: return "leaf"
        case .embers: return "flame"
        case .stars: return "sparkles"
        case .confetti: return "party.popper"
        case .bubbles: return "circle.circle"
        }
    }
}

struct ParticleEffect: Codable, Hashable {
    var kind: ParticleKind = .none
    var intensity: Double = 0.5
    var speed: Double = 0.5
    var angle: Double = 0
    var fluffy: Double = 0.6

    enum CodingKeys: String, CodingKey { case kind, intensity, speed, angle, fluffy }
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decodeIfPresent(ParticleKind.self, forKey: .kind) ?? .none
        intensity = try c.decodeIfPresent(Double.self, forKey: .intensity) ?? 0.5
        speed = try c.decodeIfPresent(Double.self, forKey: .speed) ?? 0.5
        angle = try c.decodeIfPresent(Double.self, forKey: .angle) ?? 0
        fluffy = try c.decodeIfPresent(Double.self, forKey: .fluffy) ?? 0.6
    }
}

enum RevealAnim: String, Codable, CaseIterable, Hashable {
    case none, fadeIn, slideUp, slideDown, zoomIn, spinIn

    var label: String {
        switch self {
        case .none: return String(localized: "None")
        case .fadeIn: return String(localized: "Fade in")
        case .slideUp: return String(localized: "Bottom to top")
        case .slideDown: return String(localized: "Top to bottom")
        case .zoomIn: return String(localized: "Zoom in")
        case .spinIn: return String(localized: "With spin")
        }
    }
}

enum RevealTarget: String, Codable, CaseIterable, Hashable {
    case foreground, all
    var label: String { self == .foreground ? String(localized: "Subject (in front of clock)") : String(localized: "All layers") }
}

struct RevealConfig: Codable, Hashable {
    var anim: RevealAnim = .none
    var target: RevealTarget = .foreground
    var duration: Double = 0.8
}

struct DevicePreset: Codable, Hashable, Identifiable {
    var id: String { name }
    var name: String
    var pixelWidth: Int
    var pixelHeight: Int

    var aspect: CGFloat { CGFloat(pixelWidth) / CGFloat(pixelHeight) }
    var pixelSize: CGSize { CGSize(width: pixelWidth, height: pixelHeight) }

    static let all: [DevicePreset] = [
        .init(name: "iPhone 15/16 Pro Max", pixelWidth: 1290, pixelHeight: 2796),
        .init(name: "iPhone 15/16 Pro", pixelWidth: 1179, pixelHeight: 2556),
        .init(name: "iPhone 14/13 / mini", pixelWidth: 1170, pixelHeight: 2532),
        .init(name: "iPhone SE", pixelWidth: 750, pixelHeight: 1334),
    ]
    static let `default` = all[0]
}

enum ClockFont: String, Codable, CaseIterable, Hashable {
    case system = "PRTimeFontIdentifierSystem"
    case soft   = "PRTimeFontIdentifierSoft"
    case serif  = "PRTimeFontIdentifierSerif"
    case rounded = "PRTimeFontIdentifierRounded"
    case chubby = "PRTimeFontIdentifierChubby"
    case mono   = "PRTimeFontIdentifierMono"

    var label: String {
        switch self {
        case .system: return String(localized: "System")
        case .soft: return String(localized: "Soft")
        case .serif: return String(localized: "Serif")
        case .rounded: return String(localized: "Rounded")
        case .chubby: return String(localized: "Bold")
        case .mono: return String(localized: "Monospaced")
        }
    }
}

enum ClockNumbering: String, Codable, CaseIterable, Hashable {
    case arabic = ""
    case arabicIndic = "arab"
    case devanagari = "deva"
    case roman = "roman"

    var label: String {
        switch self {
        case .arabic: return String(localized: "Regular (1234)")
        case .arabicIndic: return String(localized: "Arabic-Indic")
        case .devanagari: return String(localized: "Devanagari")
        case .roman: return String(localized: "Roman")
        }
    }
}

struct ClockStyle: Codable, Hashable {
    var font: ClockFont = .soft
    var numbering: ClockNumbering = .arabic
    var tintColor: RGBAColor? = nil
    var weight: Double = 0.5
}

enum PosterRole: String, Codable, CaseIterable, Hashable {
    case lockScreen = "PRPosterRoleLockScreen"
    case home = "PRPosterRoleHomeScreen"

    var label: String { self == .lockScreen ? String(localized: "Lock Screen") : String(localized: "Home Screen") }
}

struct WallpaperProject: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String = "Untitled"
    var background: BackgroundStyle = .gradient(.sunset)
    var layers: [Layer] = []
    var device: DevicePreset = .default
    var clock: ClockStyle = ClockStyle()
    var role: PosterRole = .lockScreen
    var particles: ParticleEffect = ParticleEffect()
    var reveal: RevealConfig = RevealConfig()
    var createdAt = Date()
    var modifiedAt = Date()

    enum CodingKeys: String, CodingKey {
        case id, name, background, layers, device, clock, role, particles, reveal, createdAt, modifiedAt
    }

    init(id: UUID = UUID(), name: String = "Untitled",
         background: BackgroundStyle = .gradient(.sunset), layers: [Layer] = [],
         device: DevicePreset = .default, clock: ClockStyle = ClockStyle(),
         role: PosterRole = .lockScreen, particles: ParticleEffect = ParticleEffect(),
         reveal: RevealConfig = RevealConfig(),
         createdAt: Date = Date(), modifiedAt: Date = Date()) {
        self.id = id; self.name = name; self.background = background
        self.layers = layers; self.device = device; self.clock = clock
        self.role = role; self.particles = particles; self.reveal = reveal
        self.createdAt = createdAt; self.modifiedAt = modifiedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Untitled"
        background = try c.decodeIfPresent(BackgroundStyle.self, forKey: .background) ?? .gradient(.sunset)
        layers = try c.decodeIfPresent([Layer].self, forKey: .layers) ?? []
        device = try c.decodeIfPresent(DevicePreset.self, forKey: .device) ?? .default
        clock = try c.decodeIfPresent(ClockStyle.self, forKey: .clock) ?? ClockStyle()
        role = try c.decodeIfPresent(PosterRole.self, forKey: .role) ?? .lockScreen
        particles = try c.decodeIfPresent(ParticleEffect.self, forKey: .particles) ?? ParticleEffect()
        reveal = try c.decodeIfPresent(RevealConfig.self, forKey: .reveal) ?? RevealConfig()
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        modifiedAt = try c.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? Date()
    }

    static func starter() -> WallpaperProject {
        var p = WallpaperProject(name: String(localized: "New wallpaper"), background: .gradient(.sunset))
        var title = Layer(name: String(localized: "Title"), content: .text(TextSpec(string: "PosterLab", fontSize: 120, weight: 7)))
        title.position = CGPoint(x: 0.5, y: 0.42)
        p.layers = [title]
        return p
    }
}
