import UIKit

final class ImageStore {
    static let shared = ImageStore()

    private let dir: URL
    private var cache: [UUID: UIImage] = [:]

    private init() {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dir = base.appendingPathComponent("Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    private func url(_ id: UUID) -> URL {
        dir.appendingPathComponent(id.uuidString).appendingPathExtension("png")
    }

    private static func hasAlpha(_ image: UIImage) -> Bool {
        guard let info = image.cgImage?.alphaInfo else { return false }
        switch info {
        case .first, .last, .premultipliedFirst, .premultipliedLast: return true
        default: return false
        }
    }

    @discardableResult
    func save(_ image: UIImage, maxDimension: CGFloat = 2400) -> UUID {
        let id = UUID()
        let scaled = ImageStore.downscale(image, maxDimension: maxDimension)
        cache[id] = scaled

        let data = ImageStore.hasAlpha(scaled)
            ? scaled.pngData()
            : (scaled.jpegData(compressionQuality: 0.9) ?? scaled.pngData())
        if let data { try? data.write(to: url(id)) }
        return id
    }

    func load(_ id: UUID) -> UIImage? {
        if let img = cache[id] { return img }
        guard let img = UIImage(contentsOfFile: url(id).path) else { return nil }
        cache[id] = img
        return img
    }

    func delete(_ id: UUID) {
        cache[id] = nil
        try? FileManager.default.removeItem(at: url(id))
    }

    static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }
        let factor = maxDimension / longest
        let newSize = CGSize(width: size.width * factor, height: size.height * factor)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
