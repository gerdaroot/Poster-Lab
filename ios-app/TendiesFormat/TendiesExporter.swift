import SwiftUI
import UIKit

enum TendiesExportError: LocalizedError {
    case rasterFailed
    case zipFailed
    var errorDescription: String? {
        switch self {
        case .rasterFailed: return String(localized: "Couldn't render the layer.")
        case .zipFailed: return String(localized: "Couldn't package the .tendies.")
        }
    }
}

enum TendiesExporter {

    static let docW: Double = 390
    static let docH: Double = 844
    static let assetScale: CGFloat = 3
    static let screenClass = "390w-844h@3x~iphone"
    static let baseName = "7400.Custom"
    static let identifier = "7400"

    private enum F {
        static let role = "com.apple.posterkit.role.identifier"
        static let descriptorID = "com.apple.posterkit.provider.descriptor.identifier"
        static let providerInfo = "providerInfo.plist"
        static let suggestion = "com.apple.posterkit.provider.identifierURL.suggestionMetadata.plist"
        static let complication = "com.apple.posterkit.provider.instance.complicationLayout.plist"
        static let titleStyle = "com.apple.posterkit.provider.instance.titleStyleConfiguration.plist"
        static let otherMetadata = "com.apple.posterkit.provider.contents.otherMetadata.plist"
        static let configurable = ".com.apple.posterkit.provider.contents.configurableOptions.plist"
        static let userInfo = "com.apple.posterkit.provider.contents.userInfo"
        static let homescreen = "com.apple.posterkit.provider.supplementURL.homescreenConfiguration.plist"
    }

    @MainActor
    static func export(_ project: WallpaperProject, fileName: String? = nil) throws -> URL {
        let fm = FileManager.default
        let work = fm.temporaryDirectory.appendingPathComponent("tendies-\(UUID().uuidString)", isDirectory: true)
        let descriptors = work.appendingPathComponent("descriptors", isDirectory: true)
        let desc = descriptors.appendingPathComponent(UUID().uuidString.uppercased(), isDirectory: true)
        let version = desc.appendingPathComponent("versions/1", isDirectory: true)
        let contents = version.appendingPathComponent("contents", isDirectory: true)
        let supplements = version.appendingPathComponent("supplements/0", isDirectory: true)
        try fm.createDirectory(at: contents, withIntermediateDirectories: true)
        try fm.createDirectory(at: supplements, withIntermediateDirectories: true)

        try project.role.rawValue.write(to: desc.appendingPathComponent(F.role), atomically: true, encoding: .utf8)
        try identifier.write(to: desc.appendingPathComponent(F.descriptorID), atomically: true, encoding: .utf8)
        try PosterPlists.providerInfo().write(to: desc.appendingPathComponent(F.providerInfo))
        try TendiesTemplate.suggestionMetadata.write(to: desc.appendingPathComponent(F.suggestion))

        try TendiesTemplate.complicationLayout.write(to: version.appendingPathComponent(F.complication))
        try PosterPlists.titleStyleConfiguration(project.clock).write(to: version.appendingPathComponent(F.titleStyle))

        let wallpaperDirName = "\(baseName)-\(screenClass).wallpaper"
        try PosterPlists.otherMetadata(displayName: project.name).write(to: contents.appendingPathComponent(F.otherMetadata))
        try TendiesTemplate.configurableOptions.write(to: contents.appendingPathComponent(F.configurable))
        try PosterPlists.userInfo(wallpaperFileName: wallpaperDirName, identifier: identifier)
            .write(to: contents.appendingPathComponent(F.userInfo))

        try TendiesTemplate.homescreenConfiguration.write(to: supplements.appendingPathComponent(F.homescreen))

        try buildWallpaper(project, into: contents.appendingPathComponent(wallpaperDirName, isDirectory: true))

        let outName = (fileName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? project.name
        return try zip(descriptors: descriptors, outName: outName)
    }

    @MainActor
    private static func buildWallpaper(_ project: WallpaperProject, into dir: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let wallpaperPlist: [String: Any] = [
            "appearanceAware": false,
            "assets": ["lockAndHome": ["default": [
                "assetFileName": "wallpaper.ca",
                "identifier": 7920,
                "name": "Lavender",
                "type": "ParameterizedCA",
            ]]],
            "contentVersion": 1.07,
            "family": "Marble",
            "identifier": 7920,
            "logicalScreenClass": "any",
            "name": "Lavender",
            "preferredProminentColor": ["default": "#FFFFFF"],
            "preferredTitleColor": ["#FFFFFF02"],
            "productTypes": ["iPhone18,3"],
            "version": 6,
            "wantsDeviceMotion": true,
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: wallpaperPlist, format: .binary, options: 0)
        try data.write(to: dir.appendingPathComponent("Wallpaper.plist"))

        let caDir = dir.appendingPathComponent("wallpaper.ca", isDirectory: true)
        let assets = caDir.appendingPathComponent("assets", isDirectory: true)
        try fm.createDirectory(at: assets, withIntermediateDirectories: true)

        var backgroundItems: [CAMLItem] = []
        var floatingItems: [CAMLItem] = []
        var properties: [WallpaperProperty] = []
        var index = 0

        if let png = renderBackground(project.background).pngData() {
            let file = "background.png"
            try png.write(to: assets.appendingPathComponent(file))
            backgroundItems.append(CAMLItem(id: "bgimg", name: "BG", assetFile: file,
                                            boundsW: docW, boundsH: docH,
                                            centerX: docW / 2, centerY: docH / 2,
                                            rotationZ: 0, opacity: 1, blend: .normal))
        }

        let visible = project.layers.filter { !$0.isHidden }
        for layer in visible {

            let toFloating = layer.depth != .background
            let view = toFloating ? "Floating" : "Background"
            if let item = try makeLayerItem(layer, index: index, view: view, assets: assets,
                                            reveal: project.reveal, properties: &properties) {
                if toFloating { floatingItems.append(item) } else { backgroundItems.append(item) }
            }
            index += 1
        }

        let (particleItems, particleSprites) = particleContent(project.particles)
        for (file, image) in particleSprites {
            if let png = image.pngData() { try png.write(to: assets.appendingPathComponent(file)) }
        }
        floatingItems.append(contentsOf: particleItems)

        try CAML.assetManifest.write(to: caDir.appendingPathComponent("assetManifest.caml"), atomically: true, encoding: .utf8)
        try CAML.indexXMLMinimal.write(to: caDir.appendingPathComponent("index.xml"), atomically: true, encoding: .utf8)
        try CAML.parameterizedMain(docW: docW, docH: docH, background: backgroundItems,
                                   floating: floatingItems, properties: properties)
            .write(to: caDir.appendingPathComponent("main.caml"), atomically: true, encoding: .utf8)
    }

    @MainActor
    private static func makeLayerItem(_ layer: Layer, index: Int, view: String, assets: URL,
                                      reveal: RevealConfig, properties: inout [WallpaperProperty]) throws -> CAMLItem? {
        guard let (img, ptSize) = renderLayer(layer), let png = img.pngData() else { return nil }
        let file = "layer_\(index).png"
        try png.write(to: assets.appendingPathComponent(file))
        let w = ptSize.width * layer.scale
        let h = ptSize.height * layer.scale
        let name = "\(layer.name) \(index)"
        let s = layer.states

        let (lockN, homeN) = s.positions(base: layer.position)

        let lockX = lockN.x * docW, lockY = (1.0 - lockN.y) * docH
        let homeX = homeN.x * docW, homeY = (1.0 - homeN.y) * docH
        let lockO = s.onLock ? layer.opacity : 0
        let homeO = s.onHome ? layer.opacity : 0

        var anims: [CAMLAnim] = []
        if layer.spin.enabled {
            let end = (layer.spin.clockwise ? 1.0 : -1.0) * layer.spin.turns * 2 * .pi
            anims.append(CAMLAnim(keyPath: "transform.rotation.z", values: [0, end],
                                  duration: layer.spin.duration, repeatForever: true))
        }
        let applyReveal = reveal.anim != .none && (reveal.target == .all || view == "Floating")
        if applyReveal, let r = revealAnim(reveal, centerY: lockY) { anims.append(r) }

        for ca in layer.animations where ca.keyframes.count >= 2 {
            let sorted = ca.keyframes.sorted { $0.time < $1.time }
            anims.append(CAMLAnim(
                keyPath: ca.keyPath.rawValue,
                values: sorted.map { $0.value },
                keyTimes: sorted.map { max(0, min(1, $0.time)) },
                duration: max(0.1, ca.duration),
                timeOffset: ca.timeOffset,
                autoreverses: ca.autoreverses,
                repeatForever: ca.repeatForever,
                timingFunction: ca.timing.camlName
            ))
        }

        properties.append(WallpaperProperty(keyPath: "position.x", layerName: name, view: view,
            vLock: lockX, vHome: homeX, vSleep: lockX))
        properties.append(WallpaperProperty(keyPath: "position.y", layerName: name, view: view,
            vLock: lockY, vHome: homeY, vSleep: lockY))
        if lockO != 1 || homeO != 1 {
            properties.append(WallpaperProperty(keyPath: "opacity", layerName: name, view: view,
                vLock: lockO, vHome: homeO, vSleep: lockO))
        }
        if s.homeScale != 1 {
            properties.append(WallpaperProperty(keyPath: "bounds.size.width", layerName: name, view: view,
                vLock: w, vHome: w * s.homeScale, vSleep: w))
            properties.append(WallpaperProperty(keyPath: "bounds.size.height", layerName: name, view: view,
                vLock: h, vHome: h * s.homeScale, vSleep: h))
        }

        return CAMLItem(id: "l\(index)\(abs(layer.id.hashValue % 100000))",
                        name: name, assetFile: file, boundsW: w, boundsH: h,
                        centerX: lockX, centerY: lockY,
                        rotationZ: layer.rotation, opacity: lockO, blend: layer.blend, anims: anims)
    }

    private static func revealAnim(_ r: RevealConfig, centerY: Double) -> CAMLAnim? {
        switch r.anim {
        case .none: return nil
        case .fadeIn:
            return CAMLAnim(keyPath: "opacity", values: [0, 1], duration: r.duration, repeatForever: false)
        case .slideUp:

            return CAMLAnim(keyPath: "position.y", values: [centerY - 160, centerY], duration: r.duration, repeatForever: false)
        case .slideDown:

            return CAMLAnim(keyPath: "position.y", values: [centerY + 160, centerY], duration: r.duration, repeatForever: false)
        case .zoomIn:
            return CAMLAnim(keyPath: "transform.scale", values: [0.6, 1], duration: r.duration, repeatForever: false)
        case .spinIn:
            return CAMLAnim(keyPath: "transform.rotation.z", values: [-2 * .pi, 0], duration: r.duration, repeatForever: false)
        }
    }

    static func particleContent(_ effect: ParticleEffect) -> ([CAMLItem], [String: UIImage]) {
        guard let style = ParticleSystem.style(for: effect.kind) else { return ([], [:]) }
        let particles = ParticleSystem.particles(for: effect)
        var sprites: [String: UIImage] = [:]
        var spriteFiles: [String] = []
        for (ci, color) in style.colors.enumerated() {
            let file = "particle_\(effect.kind.rawValue)_\(ci).png"
            sprites[file] = ParticleSystem.sprite(shape: style.shape, color: color)
            spriteFiles.append(file)
        }
        guard !spriteFiles.isEmpty else { return ([], [:]) }

        var items: [CAMLItem] = []
        for (idx, p) in particles.enumerated() {
            let file = spriteFiles[min(p.colorIndex, spriteFiles.count - 1)]
            let w = p.size
            let h = style.shape == .streak ? p.size * 3 : p.size
            let cx = p.x * docW

            let yBelowScreen = -h, yAboveScreen = docH + h
            let vertical = style.rises ? [yBelowScreen, yAboveScreen] : [yAboveScreen, yBelowScreen]
            let phaseOffset = p.phase * p.cross
            let yInitial = vertical[0] + p.phase * (vertical[1] - vertical[0])
            var anims: [CAMLAnim] = [
                CAMLAnim(keyPath: "position.y", values: vertical, duration: p.cross,
                         timeOffset: phaseOffset, autoreverses: false, repeatForever: true)
            ]

            let dx = tan(effect.angle * .pi / 180) * (docH + 2 * h)
            if abs(dx) > 0.5 || p.sway > 0 {
                let x0 = cx - dx / 2, x1 = cx + dx / 2
                let xValues: [Double] = p.sway > 0
                    ? [x0, x0 + dx * 0.33 + p.sway, x0 + dx * 0.66 - p.sway, x1]
                    : [x0, x1]
                anims.append(CAMLAnim(keyPath: "position.x", values: xValues, duration: p.cross,
                                      timeOffset: phaseOffset, autoreverses: false, repeatForever: true))
            }
            if p.spinTurns > 0 {
                anims.append(CAMLAnim(keyPath: "transform.rotation.z", values: [0, p.spinTurns * 2 * .pi],
                                      duration: p.cross, timeOffset: phaseOffset, repeatForever: true))
            }
            if style.flickers {
                anims.append(CAMLAnim(keyPath: "opacity", values: [p.opacity * 0.15, p.opacity],
                                      duration: max(0.6, p.cross * 0.12), timeOffset: phaseOffset,
                                      autoreverses: true, repeatForever: true))
            }
            items.append(CAMLItem(id: "p\(idx)", name: "particle", assetFile: file,
                                  boundsW: w, boundsH: h, centerX: cx, centerY: yInitial,
                                  rotationZ: 0, opacity: p.opacity, blend: .normal, anims: anims))
        }
        return (items, sprites)
    }

    @MainActor
    private static func renderBackground(_ style: BackgroundStyle) -> UIImage {
        var bgOnly = WallpaperProject()
        bgOnly.background = style
        bgOnly.layers = []
        let view = WallpaperCanvas(project: bgOnly, size: CGSize(width: docW, height: docH), animated: false)
        let renderer = ImageRenderer(content: view)
        renderer.scale = assetScale
        renderer.isOpaque = true
        return renderer.uiImage ?? UIImage()
    }

    @MainActor
    private static func renderLayer(_ layer: Layer) -> (UIImage, CGSize)? {
        let k = docW / 1000.0
        let view = LayerContentView(content: layer.content, scale: k)
        let renderer = ImageRenderer(content: view)
        renderer.scale = assetScale
        renderer.isOpaque = false
        guard let img = renderer.uiImage else { return nil }
        let ptSize = CGSize(width: img.size.width, height: img.size.height)
        return (img, ptSize)
    }

    private static func zip(descriptors: URL, outName: String) throws -> URL {
        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        var result: URL?
        var thrown: Error?
        coordinator.coordinate(readingItemAt: descriptors, options: [.forUploading], error: &coordError) { zipURL in
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent(safeName(outName))
                .appendingPathExtension("tendies")
            try? FileManager.default.removeItem(at: dest)
            do {
                try FileManager.default.copyItem(at: zipURL, to: dest)
                result = dest
            } catch { thrown = error }
        }
        if let coordError { throw coordError }
        if let thrown { throw thrown }
        guard let result else { throw TendiesExportError.zipFailed }
        return result
    }

    private static func safeName(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.isEmpty ? "Wallpaper" : trimmed
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        return String(cleaned.unicodeScalars.filter { allowed.contains($0) })
    }
}

private struct LayerContentView: View {
    let content: LayerContent
    let scale: CGFloat

    var body: some View {
        switch content {
        case let .text(spec):
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
                .fixedSize(horizontal: true, vertical: true)
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
            } else {
                Color.clear.frame(width: 1, height: 1)
            }
        case let .sticker(symbol, color):
            Image(systemName: symbol)
                .font(.system(size: 240 * scale, weight: .semibold))
                .foregroundStyle(color.color)
        }
    }
}
