import SwiftUI

struct SetWallpaperGuide: View {
    let image: UIImage
    var tendiesURL: URL?
    var onAddToLibrary: ((URL) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var addedToLibrary = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(uiImage: image)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.stroke))
                        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)

                    if let tendiesURL {
                        VStack(spacing: 10) {
                            if onAddToLibrary != nil {
                                Button {
                                    onAddToLibrary?(tendiesURL)
                                    addedToLibrary = true
                                } label: {
                                    Label(addedToLibrary ? "Added to Wallpapers Library ✓" : "Add to Wallpapers Library",
                                          systemImage: addedToLibrary ? "checkmark.circle.fill" : "tray.and.arrow.down.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(maxWidth: .infinity, minHeight: 52)
                                        .background(addedToLibrary ? Color.green.opacity(0.9) : Theme.accent,
                                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .foregroundStyle(.white)
                                }
                                .disabled(addedToLibrary)
                                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: addedToLibrary)
                            }

                            ShareLink(item: tendiesURL) {
                                Label("Share .tendies", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                    }

                    steps
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Done")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Close") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 14) {
            step(1, "Save the file", "Send the .tendies to Files or straight to the Nugget app.")
            step(2, "Open Nugget", "Choose Wallpaper → Import and select your .tendies.")
            step(3, "Apply", "Apply — the wallpaper appears in the PosterBoard gallery on the Lock Screen.")
            Text("The file is a standard PosterBoard poster (Core Animation layers). It works through customization tools; no jailbreak required.")
                .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                .padding(.top, 4)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).panelCard()
    }

    private func step(_ n: Int, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)").font(.system(size: 14, weight: .bold))
                .frame(width: 26, height: 26)
                .background(Theme.accent, in: Circle()).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.loc).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text(body.loc).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
