import UIKit
import Vision
import CoreImage

enum SubjectCutout {
    enum CutoutError: LocalizedError {
        case noSubject
        case failed
        var errorDescription: String? {
            switch self {
            case .noSubject: return String(localized: "Couldn't find a subject — added the full photo.")
            case .failed: return String(localized: "Couldn't cut out the subject — added the full photo.")
            }
        }
    }

    static func cutout(_ image: UIImage) async throws -> UIImage {
        try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                do { cont.resume(returning: try perform(image)) }
                catch { cont.resume(throwing: error) }
            }
        }
    }

    private static func perform(_ image: UIImage) throws -> UIImage {
        guard let cg = image.cgImage else { throw CutoutError.failed }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cg, orientation: cgOrientation(image.imageOrientation))
        try handler.perform([request])

        guard let result = request.results?.first, !result.allInstances.isEmpty else {
            throw CutoutError.noSubject
        }
        let maskBuffer = try result.generateMaskedImage(
            ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: true)

        let ci = CIImage(cvPixelBuffer: maskBuffer)
        let srgb = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let ctx = CIContext(options: [.workingColorSpace: srgb])
        guard let out = ctx.createCGImage(ci, from: ci.extent, format: .RGBA8, colorSpace: srgb) else {
            throw CutoutError.failed
        }

        guard opaqueFraction(out) > 0.02 else { throw CutoutError.noSubject }

        return UIImage(cgImage: out, scale: image.scale, orientation: .up)
    }

    private static func opaqueFraction(_ cg: CGImage) -> Double {
        let w = 48, h = 48
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &bytes, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return 1 }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var opaque = 0
        var i = 3
        while i < bytes.count { if bytes[i] > 20 { opaque += 1 }; i += 4 }
        return Double(opaque) / Double(w * h)
    }

    private static func cgOrientation(_ o: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch o {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
