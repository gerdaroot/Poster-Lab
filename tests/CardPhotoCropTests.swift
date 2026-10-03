import XCTest
import UIKit
import SwiftUI
@testable import PosterLab_iOS

@MainActor
final class CardPhotoCropTests: XCTestCase {
    func testEditorPortraitAndLandscapeAttachments() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let originalKeyWindow = scene.windows.first(where: \.isKeyWindow)
        let controller = UIHostingController(rootView: CardPhotoCropView(image: fixture(), onUse: { _ in }))
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            originalKeyWindow?.makeKey()
        }
        for (name, size) in [("Portrait", CGSize(width: 393, height: 852)),
                             ("Landscape", CGSize(width: 852, height: 393))] {
            window.frame.size = size
            controller.view.frame = window.bounds
            window.setNeedsLayout()
            window.layoutIfNeeded()
            try await Task.sleep(nanoseconds: 300_000_000)
            controller.view.layoutIfNeeded()
            XCTAssertEqual(controller.view.bounds.size, size, "The snapshot must use the requested layout size")
            let crop = try XCTUnwrap(findCropCanvas(in: controller.view), "The photo editor must be mounted")
            XCTAssertGreaterThan(crop.bounds.width, 0)
            XCTAssertGreaterThan(crop.bounds.height, 0)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            var drewHierarchy = false
            let image = UIGraphicsImageRenderer(size: controller.view.bounds.size, format: format).image { _ in
                drewHierarchy = controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            XCTAssertTrue(drewHierarchy, "The editor screenshot must render successfully")
            // Validate actual photo pixels, so an empty/black snapshot cannot pass.
            let expected: [Pixel] = [.red, .green, .blue, .yellow]
            for (index, point) in [(0.15, 0.15), (0.85, 0.15), (0.15, 0.85), (0.85, 0.85)].enumerated() {
                let location = crop.convert(CGPoint(x: crop.bounds.width * point.0,
                                                     y: crop.bounds.height * point.1), to: controller.view)
                assertPixel(sample(image, x: location.x / controller.view.bounds.width,
                                   y: location.y / controller.view.bounds.height), expected[index])
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "Photo crop editor - \(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    private func findCropCanvas(in view: UIView) -> CardPhotoCropScrollView? {
        if let crop = view as? CardPhotoCropScrollView { return crop }
        return view.subviews.lazy.compactMap { self.findCropCanvas(in: $0) }.first
    }

    func testCenterFillRemovesTopAndBottomAndExportsExactCardSize() throws {
        let view = canvas(image: fixture(withEdgeBands: true))
        let output = try XCTUnwrap(view.croppedImage())
        XCTAssertEqual(output.cgImage?.width, 1536)
        XCTAssertEqual(output.cgImage?.height, 969)
        XCTAssertEqual(output.imageOrientation, .up)
        assertQuadrants(output, [.red, .green, .blue, .yellow])
        assertPixel(sample(output, x: 0.15, y: 0.005), .red)
        assertPixel(sample(output, x: 0.85, y: 0.995), .yellow)
        try assertMatchesViewport(view)
    }

    func testZoomAndPanClampAtBothEdgesWithoutBlankPixelsAndResetRestoresCrop() throws {
        let view = canvas(image: fixture())
        view.setRelativeZoom(3)
        view.pan(x: 100, y: 100)
        assertQuadrants(try XCTUnwrap(view.croppedImage()), Array(repeating: .yellow, count: 4))
        try assertMatchesViewport(view)

        view.pan(x: -100, y: -100)
        assertQuadrants(try XCTUnwrap(view.croppedImage()), Array(repeating: .red, count: 4))
        try assertMatchesViewport(view)

        view.resetCrop()
        assertQuadrants(try XCTUnwrap(view.croppedImage()), [.red, .green, .blue, .yellow])
        try assertMatchesViewport(view)
    }

    func testResizingPreservesAnOffCenterZoomedSelection() throws {
        let view = canvas(image: fixture())
        view.setRelativeZoom(2)
        view.pan(x: 0.13, y: 0.19)
        let before = try XCTUnwrap(view.croppedImage())
        view.frame.size = CGSize(width: 480, height: 480 * 969 / 1536)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let after = try XCTUnwrap(view.croppedImage())
        assertSamplesEqual(before, after)
        try assertMatchesViewport(view)
    }

    func testRotatedAndMirroredImageExportMatchesDisplayedOrientation() throws {
        let source = try XCTUnwrap(fixture().cgImage)
        let cases: [(UIImage.Orientation, [Pixel])] = [
            (.right, [.blue, .red, .yellow, .green]),
            (.upMirrored, [.green, .red, .yellow, .blue])
        ]
        for (orientation, expected) in cases {
            let view = canvas(image: UIImage(cgImage: source, scale: 1, orientation: orientation))
            assertQuadrants(try XCTUnwrap(view.croppedImage()), expected)
            try assertMatchesViewport(view)
        }
    }

    private func canvas(image: UIImage) -> CardPhotoCropScrollView {
        let state = CardPhotoCropState()
        let view = CardPhotoCropScrollView(image: image, editor: state)
        view.frame = CGRect(x: 0, y: 0, width: 384, height: 969 / 4)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        return view
    }

    private func fixture(withEdgeBands: Bool = false) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 800, height: 800), format: format).image { context in
            for (index, color) in [UIColor.red, .green, .blue, .yellow].enumerated() {
                color.setFill()
                context.fill(CGRect(x: (index % 2) * 400, y: (index / 2) * 400, width: 400, height: 400))
            }
            if withEdgeBands {
                UIColor.black.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 800, height: 80))
                context.fill(CGRect(x: 0, y: 720, width: 800, height: 80))
            }
        }
    }

    private func assertMatchesViewport(_ view: CardPhotoCropScrollView,
                                       file: StaticString = #filePath, line: UInt = #line) throws {
        view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1536 / view.bounds.width
        let preview = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { context in
            view.layer.render(in: context.cgContext)
        }
        assertSamplesEqual(try XCTUnwrap(view.croppedImage()), preview, file: file, line: line)
    }

    private func assertQuadrants(_ image: UIImage, _ expected: [Pixel],
                                 file: StaticString = #filePath, line: UInt = #line) {
        for (index, point) in [(0.15, 0.15), (0.85, 0.15), (0.15, 0.85), (0.85, 0.85)].enumerated() {
            assertPixel(sample(image, x: point.0, y: point.1), expected[index], file: file, line: line)
        }
    }

    private func assertSamplesEqual(_ first: UIImage, _ second: UIImage,
                                    file: StaticString = #filePath, line: UInt = #line) {
        // The off-center fixture splits at x=0.37 and y=0.31. Compare both
        // sides of those edges, avoiding renderer-specific interpolation at
        // the discontinuity itself (CALayer and UIImage use different filters).
        for x in [0.005, 0.15, 0.365, 0.375, 0.65, 0.85, 0.995] {
            for y in [0.005, 0.15, 0.305, 0.315, 0.65, 0.85, 0.995] {
                assertPixel(sample(first, x: x, y: y), sample(second, x: x, y: y), file: file, line: line)
            }
        }
    }

    private struct Pixel {
        let rgba: [UInt8]
        static let red = Pixel(rgba: [255, 0, 0, 255])
        static let green = Pixel(rgba: [0, 255, 0, 255])
        static let blue = Pixel(rgba: [0, 0, 255, 255])
        static let yellow = Pixel(rgba: [255, 255, 0, 255])
    }

    private func sample(_ image: UIImage, x: Double, y: Double) -> Pixel {
        guard let source = image.cgImage,
              let pixel = source.cropping(to: CGRect(x: Int(Double(source.width - 1) * x),
                                                     y: Int(Double(source.height - 1) * y),
                                                     width: 1, height: 1)) else {
            XCTFail("Could not read a rendered pixel")
            return Pixel(rgba: [0, 0, 0, 0])
        }
        var bytes = [UInt8](repeating: 0, count: 4)
        bytes.withUnsafeMutableBytes { buffer in
            let context = CGContext(data: buffer.baseAddress, width: 1, height: 1,
                                    bitsPerComponent: 8, bytesPerRow: 4,
                                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return Pixel(rgba: bytes)
    }

    private func assertPixel(_ actual: Pixel, _ expected: Pixel,
                             file: StaticString = #filePath, line: UInt = #line) {
        for (actualComponent, expectedComponent) in zip(actual.rgba, expected.rgba) {
            XCTAssertEqual(Double(actualComponent), Double(expectedComponent), accuracy: 3,
                           "Rendered pixel differs: \(actual.rgba) vs \(expected.rgba)", file: file, line: line)
        }
    }
}
