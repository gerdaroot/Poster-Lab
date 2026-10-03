import UIKit
import Photos

enum ExportError: LocalizedError {
    case noAccess
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .noAccess: return String(localized: "No access to your photo library. Allow it in Settings → PosterLab.")
        case .renderFailed: return String(localized: "Couldn't render the image.")
        }
    }
}

enum PhotoExporter {

    static func save(_ image: UIImage) async throws {
        let status = await requestAddAccess()
        guard status == .authorized || status == .limited else { throw ExportError.noAccess }

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success { cont.resume() }
                else { cont.resume(throwing: error ?? ExportError.renderFailed) }
            }
        }
    }

    private static func requestAddAccess() async -> PHAuthorizationStatus {
        await withCheckedContinuation { cont in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { cont.resume(returning: $0) }
        }
    }
}
