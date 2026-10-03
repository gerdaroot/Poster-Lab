import SwiftUI

enum WallpaperRenderer {
    @MainActor
    static func render(_ project: WallpaperProject) -> UIImage? {

        let pointSize = CGSize(width: 1000,
                               height: 1000 / project.device.aspect)
        let canvas = WallpaperCanvas(project: project, size: pointSize)
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = CGFloat(project.device.pixelWidth) / pointSize.width
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
