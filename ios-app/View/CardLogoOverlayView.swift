import SwiftUI
import UIKit

enum PaymentLogo: String, CaseIterable, Identifiable {
    case visa = "Visa"
    case mastercard = "Mastercard"

    var id: String { rawValue }

    var assetName: String {
        switch self {
        case .visa: return "VisaLogo"
        case .mastercard: return "MastercardLogo"
        }
    }

    func image() -> UIImage {
        UIImage(named: assetName) ?? UIImage()
    }
}

struct CardLogoOverlayView: View {
    let cardImage: UIImage
    let onSave: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedLogo: PaymentLogo = .visa
    @State private var logoOffset: CGSize = .zero
    @State private var dragStart: CGSize = .zero
    @State private var logoScale: CGFloat = 1.0
    @State private var cardSize: CGSize = .zero

    private let cardAspect: CGFloat = 1536.0 / 969.0
    private let logoBaseSize = CGSize(width: 72, height: 46)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                logoPicker

                GeometryReader { geo in
                    let availW = max(geo.size.width - 32, 1)
                    let availH = max(geo.size.height - 60, 1)
                    let cardW = min(availW, availH * cardAspect)
                    let cardH = cardW / cardAspect

                    ZStack {
                        Image(uiImage: cardImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: cardW, height: cardH)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                            .frame(width: cardW, height: cardH)

                        let lw = logoBaseSize.width * logoScale
                        let lh = logoBaseSize.height * logoScale
                        let logoImg = selectedLogo.image()

                        Image(uiImage: logoImg)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: lw, height: lh)
                            .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                            .offset(clampedOffset(cardW: cardW, cardH: cardH, logoW: lw, logoH: lh))
                            .gesture(
                                DragGesture(coordinateSpace: .named("cardArea"))
                                    .onChanged { value in
                                        let raw = CGSize(
                                            width: dragStart.width + value.translation.width,
                                            height: dragStart.height + value.translation.height
                                        )
                                        logoOffset = clamp(raw, cardW: cardW, cardH: cardH, logoW: lw, logoH: lh)
                                    }
                                    .onEnded { _ in
                                        dragStart = logoOffset
                                    }
                            )
                    }
                    .frame(width: cardW, height: cardH)
                    .clipped()
                    .coordinateSpace(name: "cardArea")
                    .contentShape(Rectangle())
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .onAppear {
                        cardSize = CGSize(width: cardW, height: cardH)
                        logoOffset = CGSize(width: cardW * 0.3, height: cardH * 0.25)
                        dragStart = logoOffset
                    }
                    .onChange(of: geo.size) {
                        let newW = min(max(geo.size.width - 32, 1), max(geo.size.height - 60, 1) * cardAspect)
                        let newH = newW / cardAspect
                        cardSize = CGSize(width: newW, height: newH)
                    }
                }

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $logoScale, in: 0.5...2.5, step: 0.1)
                        Text("\(logoScale, specifier: "%.1f")×")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 36)
                    }

                    Text("Drag logo to position it on the card")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Add Logo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        let result = compositeImage()
                        onSave(result)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }

    private func clampedOffset(cardW: CGFloat, cardH: CGFloat, logoW: CGFloat, logoH: CGFloat) -> CGSize {
        clamp(logoOffset, cardW: cardW, cardH: cardH, logoW: logoW, logoH: logoH)
    }

    private func clamp(_ offset: CGSize, cardW: CGFloat, cardH: CGFloat, logoW: CGFloat, logoH: CGFloat) -> CGSize {
        let maxX = (cardW - logoW) / 2
        let maxY = (cardH - logoH) / 2
        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }

    private var logoPicker: some View {
        HStack(spacing: 10) {
            ForEach(PaymentLogo.allCases) { logo in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedLogo = logo
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(uiImage: logo.image())
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 54, height: 34)

                        Text(logo.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(selectedLogo == logo ? Theme.accent : .secondary)
                    }
                    .padding(8)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedLogo == logo ? Theme.accent.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(selectedLogo == logo ? Theme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func compositeImage() -> UIImage {
        let normalized = ImageEngine.normalizeAndDownsample(cardImage, maxDimension: 2560)
        let imgW = normalized.size.width
        let imgH = normalized.size.height
        guard imgW > 0, imgH > 0, cardSize.width > 0, cardSize.height > 0 else { return cardImage }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: imgW, height: imgH), format: format)

        return renderer.image { _ in
            normalized.draw(at: .zero)

            let sx = imgW / cardSize.width
            let sy = imgH / cardSize.height

            let lw = logoBaseSize.width * logoScale * sx
            let lh = logoBaseSize.height * logoScale * sy

            let cx = imgW / 2 + logoOffset.width * sx
            let cy = imgH / 2 + logoOffset.height * sy

            let logoImg = selectedLogo.image()
            let logoRect = CGRect(x: cx - lw / 2, y: cy - lh / 2, width: lw, height: lh)

            let origAspect = logoImg.size.width / max(logoImg.size.height, 1)
            let fitW: CGFloat
            let fitH: CGFloat
            if origAspect > lw / max(lh, 1) {
                fitW = lw
                fitH = lw / max(origAspect, 0.01)
            } else {
                fitH = lh
                fitW = lh * origAspect
            }
            let fitRect = CGRect(
                x: logoRect.midX - fitW / 2,
                y: logoRect.midY - fitH / 2,
                width: fitW,
                height: fitH
            )
            logoImg.draw(in: fitRect)
        }
    }
}
