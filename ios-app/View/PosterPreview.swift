import SwiftUI

struct PosterPreview: View {
    let project: WallpaperProject
    @Environment(\.dismiss) private var dismiss

    @State private var progress: Double = Double(ProcessInfo.processInfo.environment["POSTERLAB_PREVIEW_PROGRESS"] ?? "") ?? 0
    @State private var dragStart: Double?
    @State private var revealT: Double = 1
    @State private var now = Date()

    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Color.black
                wallpaper(size)
                Color.black.opacity(0.30 * progress)
                lockLayer(size).opacity(max(0, 1 - progress * 1.6))
                controls
            }
            .contentShape(Rectangle())
            .gesture(unlockDrag(height: size.height))
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .background(Color.black.ignoresSafeArea())
        .onAppear { playReveal() }
        .onReceive(clockTimer) { now = $0 }
    }

    private func wallpaper(_ size: CGSize) -> some View {
        let aspect = project.device.aspect
        var w = size.width, h = w / aspect
        if h < size.height { h = size.height; w = h * aspect }
        return WallpaperCanvas(project: project, size: CGSize(width: w, height: h),
                               animated: true, stateProgress: progress)
            .frame(width: w, height: h)
            .scaleEffect(1 + 0.06 * progress + revealScale)
            .blur(radius: 10 * progress)
            .offset(revealOffset)
            .opacity(revealOpacity)
            .rotationEffect(.degrees(revealRotation))
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    private func lockLayer(_ size: CGSize) -> some View {
        VStack {
            Spacer().frame(height: size.height * 0.08)
            Image(systemName: "lock.fill").font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
            Text(now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 10)
            Text(now, format: .dateTime.hour().minute())
                .font(clockFont(size: size.width * 0.235))
                .foregroundStyle(clockColor)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
            Spacer()
            HStack(spacing: size.width * 0.5) {
                circleButton("flashlight.off.fill")
                circleButton("camera.fill")
            }
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3).frame(width: 120, height: 5)
            }
            .foregroundStyle(.white.opacity(0.85))
            .padding(.bottom, 10)
            Text("swipe up").font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private func circleButton(_ icon: String) -> some View {
        Image(systemName: icon).font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(.ultraThinMaterial, in: Circle())
    }

    private var controls: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.headline).foregroundStyle(.white)
                        .frame(width: 40, height: 40).background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
                Button { playReveal() } label: {
                    Label("Reveal", systemImage: "play.fill").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white).padding(.horizontal, 14).padding(.vertical, 9)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(.horizontal, 16).padding(.top, 60)
            Spacer()
        }
    }

    private func unlockDrag(height: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { v in
                if dragStart == nil { dragStart = progress }
                let delta = -v.translation.height / (height * 0.6)
                progress = min(max((dragStart ?? 0) + delta, 0), 1)
            }
            .onEnded { v in
                dragStart = nil
                let target = (progress > 0.4 || v.predictedEndTranslation.height < -200) ? 1.0 : 0.0
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { progress = target }
            }
    }

    private func playReveal() {
        guard project.reveal.anim != .none else { revealT = 1; return }
        revealT = 0
        withAnimation(.easeOut(duration: project.reveal.duration)) { revealT = 1 }
    }

    private var revealOffset: CGSize {
        let d = 1 - revealT
        switch project.reveal.anim {
        case .slideUp: return CGSize(width: 0, height: 140 * d)
        case .slideDown: return CGSize(width: 0, height: -140 * d)
        default: return .zero
        }
    }
    private var revealScale: Double {
        project.reveal.anim == .zoomIn ? -0.12 * (1 - revealT) : 0
    }
    private var revealRotation: Double {
        project.reveal.anim == .spinIn ? -25 * (1 - revealT) : 0
    }
    private var revealOpacity: Double {
        switch project.reveal.anim {
        case .fadeIn, .spinIn, .zoomIn: return 0.2 + 0.8 * revealT
        default: return 1
        }
    }

    private func clockFont(size: CGFloat) -> Font {
        switch project.clock.font {
        case .serif: return .system(size: size, weight: .bold, design: .serif)
        case .mono: return .system(size: size, weight: .bold, design: .monospaced)
        case .rounded, .soft, .chubby: return .system(size: size, weight: .heavy, design: .rounded)
        case .system: return .system(size: size, weight: .bold)
        }
    }
    private var clockColor: Color {
        if let t = project.clock.tintColor { return t.color }
        return .white
    }
}
