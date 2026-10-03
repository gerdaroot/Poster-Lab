import PhotosUI
import SwiftUI
import XCTest
@testable import PosterLab_iOS

@MainActor
final class CardPhotoPickerTests: XCTestCase {
    func testBackRetainsLibraryAndAllowsAnotherCropWithoutSaving() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let originalKeyWindow = scene.windows.first(where: \.isKeyWindow)
        var saveCount = 0
        let coordinator = CardPhotoPicker { _ in saveCount += 1 }.makeCoordinator()
        let container = CardPhotoPicker.Container()
        let picker = container.picker
        picker.delegate = coordinator
        let window = UIWindow(windowScene: scene)
        window.rootViewController = container
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            originalKeyWindow?.makeKey()
        }
        try await settle("initial library", diagnostic: { "window=\(picker.view.window === window), transition=\(String(describing: picker.transitionCoordinator))" }) { picker.view.window === window && picker.transitionCoordinator == nil }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 200)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 300, height: 200))
        }

        // Exercise Back twice to prove the retained library can open another editor.
        for _ in 0..<2 {
            coordinator.presentCrop(image, from: picker)
            let crop = try XCTUnwrap(container.presentedViewController as? UIHostingController<CardPhotoCropView>)
            try await settle("crop presented", diagnostic: { "window=\(crop.view.window === window), presenting=\(crop.isBeingPresented), transition=\(String(describing: crop.transitionCoordinator))" }) {
                crop.view.window === window && !crop.isBeingPresented && crop.transitionCoordinator == nil
            }
            XCTAssertTrue(crop.presentingViewController === container)
            crop.dismiss(animated: false)
            try await settle("crop dismissed", diagnostic: { "presented=\(String(describing: container.presentedViewController)), window=\(picker.view.window === window), transition=\(String(describing: picker.transitionCoordinator)), dismissing=\(crop.isBeingDismissed)" }) {
                container.presentedViewController == nil && picker.view.window === window && picker.transitionCoordinator == nil
            }
            XCTAssertTrue(window.rootViewController === container)
            XCTAssertTrue(container.picker === picker)
            XCTAssertEqual(saveCount, 0)
        }
    }

    private func settle(_ phase: String, diagnostic: () -> String, _ condition: () -> Bool) async throws {
        // UIKit may create its transition coordinator on the next run-loop pass.
        // Require a stable mounted state before starting the next transition.
        var stablePasses = 0
        for _ in 0..<100 {
            try await Task.sleep(nanoseconds: 50_000_000)
            stablePasses = condition() ? stablePasses + 1 : 0
            if stablePasses == 3 { return }
        }
        XCTFail("\(phase) did not settle: \(diagnostic())")
        throw PresentationTimeout()
    }

    private struct PresentationTimeout: Error {}
}
