import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

func logLineColor(_ line: String) -> Color {
    if line.contains("✅") || line.contains("🎉") { return .green }
    if line.contains("❌") { return .red }
    if line.contains("⚠️") { return .orange }
    return .secondary
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PairingGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onImportTapped: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Where to find your pairing file")
                            .font(.title2.bold())
                        Text("PosterLab can import pairing files exported by SideStore, Idevice_pair, iLoader, or your computer.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "app.badge.checkmark.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.accent)
                            Text("SideStore")
                                .font(.headline.bold())
                            Spacer()
                            Text("Recommended")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Theme.accent.opacity(0.12))
                                .foregroundStyle(Theme.accent)
                                .clipShape(Capsule())
                        }

                        Text("SideStore automatically creates a pairing file during setup. You can pick it directly in the Files app:")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Path in Files app:")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text("On My iPhone › SideStore › ALTPairingFile.mobiledevicepairing")
                                .font(.caption.monospaced())
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(uiColor: .systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "shippingbox.fill")
                                .font(.title3)
                                .foregroundStyle(.purple)
                            Text("LiveContainer (SideStore inside)")
                                .font(.headline.bold())
                        }

                        Text("If you run SideStore inside LiveContainer, the pairing file is stored inside LiveContainer's app storage:")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Path in Files app:")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text("On My iPhone › LiveContainer › SideStore › Documents › ALTPairingFile.mobiledevicepairing")
                                .font(.caption.monospaced())
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(uiColor: .systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.title3)
                                .foregroundStyle(.orange)
                            Text("iLoader / Jitterbug / AltStore")
                                .font(.headline.bold())
                        }

                        Text("• In iLoader: Settings › Export Pairing File › save to Files.\n• In Jitterbug: Export your <UDID>.mobiledevicepairing.\n• On PC/Mac: Run jitterbugpair or export from SideServer / AltServer, then AirDrop to your iPhone.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                            Text("Manual Drop in Files App")
                                .font(.headline.bold())
                        }

                        Text("You can also copy any .mobiledevicepairing or .plist file directly into:")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text("Files app › On My iPhone › PosterLab")
                            .font(.caption.monospaced())
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text("It will immediately appear under 'Discovered in Documents' in PosterLab.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button {
                        dismiss()
                        onImportTapped()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("Import Pairing File Now")
                            Spacer()
                        }
                        .font(.headline)
                        .frame(height: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .padding()
            }
            .navigationTitle("Pairing Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.bold()
                }
            }
        }
    }
}

struct CompactLogView: View {
    let title: String
    let lines: [String]
    var onClear: (() -> Void)? = nil
    @State private var copied: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if let onClear = onClear, !lines.isEmpty {
                    Button(action: onClear) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .padding(.trailing, 6)
                }
                Button {
                    UIPasteboard.general.string = lines.joined(separator: "\n")
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        var t2 = Transaction()
                        t2.disablesAnimations = true
                        withTransaction(t2) {
                            copied = false
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .bold))
                        Text(copied ? "Copied" : "Copy")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(copied ? .green : Theme.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(Capsule())
                }
                .buttonStyle(.borderless)
                .transaction { $0.animation = nil }
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { idx, line in
                            Text(line)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(logLineColor(line))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(idx)
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 180)
                .background(Color(uiColor: .tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 0.5)
                )
                .onChange(of: lines.count) { _, _ in
                    if !lines.isEmpty {
                        proxy.scrollTo(lines.count - 1, anchor: .bottom)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let onPick: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView

        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            let shouldStop = url.startAccessingSecurityScopedResource()
            defer {
                if shouldStop { url.stopAccessingSecurityScopedResource() }
            }
            parent.onPick(url)
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch vm.selectedTab {
                case .pairing: PairingTab()
                case .create: GalleryView().preferredColorScheme(.dark)
                case .walletCards: WalletCardsTab()
                case .passcodeThemes: PasscodeThemeTab()
                case .wallpapers: TendiesView()
                case .credits: CreditsTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            PosterTabBar(selected: $vm.selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .alert("Notice", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .alert("Done", isPresented: $vm.showSuccessAlert) {
            Button("OK") {}
        } message: {
            Text(vm.successAlertMessage)
        }
        .sheet(isPresented: $vm.showShareSheet) {
            if let url = vm.exportedThemeURL {
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            vm.showSuccessAlert = false
            vm.successAlertMessage = ""
        }
    }
}

struct PosterTabBar: View {
    @Binding var selected: AppTab
    @Namespace private var tabNS

    private struct Item: Identifiable {
        let id: AppTab
        let title: String
        let icon: String
    }

    private let items: [Item] = [
        .init(id: .pairing,        title: "Pairing",  icon: "antenna.radiowaves.left.and.right"),
        .init(id: .create,         title: "Create",   icon: "wand.and.stars"),
        .init(id: .walletCards,    title: "Wallet",   icon: "creditcard.fill"),
        .init(id: .passcodeThemes, title: "Passcode", icon: "lock.circle.fill"),
        .init(id: .wallpapers,     title: "Flash",    icon: "photo.stack.fill"),
        .init(id: .credits,        title: "Credits",  icon: "info.circle"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selected = item.id
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.icon)
                            .font(.system(size: 17, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                        Text(item.title)
                            .font(.system(size: 9, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selected == item.id ? Theme.accent : .white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .background {
                        if selected == item.id {
                            Capsule()
                                .fill(Theme.accent.opacity(0.12))
                                .matchedGeometryEffect(id: "tabPill", in: tabNS)
                                .padding(.horizontal, 4)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay {
                    Capsule()
                        .strokeBorder(Theme.glassStroke, lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct PairingTab: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showDeleteConfirm = false
    @State private var showFilePicker = false
    @State private var showPairingGuide = false

    private var isIOS27OrNewer: Bool {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27
    }

    var body: some View {
        NavigationStack {
            Form {

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 10) {
                            if let img = UIImage(named: "AppIcon") {
                                Image(uiImage: img)
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PosterLab")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                Text("Wallpapers · Wallet Skins · Passcode Themes")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("v1.1.1")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.clear)

                Section("Active Pairing") {
                    HStack(spacing: 10) {
                        if vm.hasPairingFile {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Paired & Ready")
                                    .font(.subheadline.bold())
                                Text("\(vm.pairingFileName) (\(vm.pairingFileSizeString))")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Not Paired")
                                    .font(.subheadline.bold())
                                Text(isIOS27OrNewer
                                     ? "Pair on this iPhone below or import a pairing file."
                                     : "Import a pairing file from SideStore, iLoader, or PC below.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if vm.hasPairingFile {
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    if vm.hasPairingFile {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "trash.fill")
                                Text("Delete Pairing File")
                                Spacer()
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.red)
                        }
                    }
                }
                .confirmationDialog(
                    "Delete pairing session?",
                    isPresented: $showDeleteConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Delete Pairing", role: .destructive) { vm.deletePairingFile() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("The active pairing credentials will be removed so you can re-pair or import another file.")
                }

                Section("Network") {
                    VPNStatusRow(vm: vm)
                }

                Section("Pairing File") {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            showFilePicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .foregroundStyle(Theme.accent)
                                Text("Import Pairing File…")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }

                        Button {
                            showPairingGuide = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "questionmark.circle")
                                Text("Where to find SideStore / LiveContainer pairing file?")
                            }
                            .font(.footnote)
                            .foregroundStyle(Theme.accent)
                        }
                        .buttonStyle(.plain)

                        Text("Supports .mobiledevicepairing, .plist, or .mobilepair exported from SideStore, iLoader, AltStore, Jitterbug, or Mac/PC.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !vm.documentsPlistFiles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Discovered in Documents:")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            ForEach(vm.documentsPlistFiles, id: \.self) { filename in
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundStyle(Theme.accent)
                                    Text(filename)
                                        .font(.caption.monospaced())
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button("Use") {
                                        vm.selectPairingFile(filename: filename)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if isIOS27OrNewer {
                    Section("Pair on This iPhone") {
                        if vm.pairingPhase == .pairing {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    ProgressView().scaleEffect(0.85)
                                    Text(vm.pairingStatus.isEmpty ? "Starting local pairing host…" : vm.pairingStatus)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                if let pin = vm.pairingPIN {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("ENTER THIS PIN ON THIS IPHONE:")
                                            .font(.caption2.bold().uppercaseSmallCaps())
                                            .foregroundStyle(.secondary)

                                        HStack(alignment: .center, spacing: 0) {
                                            Text(pin)
                                                .font(.system(size: 40, weight: .black, design: .monospaced))
                                                .foregroundStyle(.orange)
                                            Spacer()
                                            Button {
                                                UIPasteboard.general.string = pin
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            } label: {
                                                Label("Copy", systemImage: "doc.on.doc")
                                                    .font(.caption.bold())
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(.orange)
                                        }

                                        Text("Settings › Privacy & Security › Developer Mode › Pair with PosterLab")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(.primary)

                                        Button {
                                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                                UIApplication.shared.open(url)
                                            }
                                        } label: {
                                            Label("Open Settings App Now", systemImage: "arrow.up.forward.app")
                                                .bold()
                                                .frame(maxWidth: .infinity, alignment: .center)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.orange)
                                    }
                                    .padding(14)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }

                                Button(role: .cancel) {
                                    vm.cancelPairing()
                                } label: {
                                    HStack(spacing: 8) {
                                        Spacer()
                                        Image(systemName: "xmark")
                                        Text("Cancel Pairing")
                                        Spacer()
                                    }
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        } else {
                            VStack(spacing: 12) {
                                if !vm.pairingStatus.isEmpty && vm.pairingStatus != "idle" {
                                    Text(vm.pairingStatus)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(
                                            vm.pairingStatus.contains("✅") ? .green :
                                            vm.pairingStatus.contains("❌") || vm.pairingStatus.contains("failed") ? .red :
                                            .secondary
                                        )
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }

                                Button {
                                    vm.startPairing()
                                } label: {
                                    HStack(spacing: 8) {
                                        Spacer()
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                            .font(.body.weight(.semibold))
                                        Text(vm.hasPairingFile ? "Re-Pair This iPhone" : "Pair This iPhone")
                                            .font(.headline)
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .listRowInsets(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
                        }
                    }
                }

                if !vm.log.isEmpty {
                    Section {
                        CompactLogView(
                            title: "Activity Log (\(vm.log.count) lines)",
                            lines: vm.log,
                            onClear: { vm.log.removeAll() }
                        )
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }
            .navigationTitle("PosterLab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPickerView(allowedContentTypes: [
                    UTType(filenameExtension: "mobiledevicepairing") ?? .data,
                    UTType(filenameExtension: "plist") ?? .propertyList,
                    UTType(filenameExtension: "mobilepair") ?? .data,
                    .propertyList,
                    .data,
                    .item
                ]) { url in
                    _ = vm.importPairingFile(from: url, originalName: url.lastPathComponent)
                }
            }
            .sheet(isPresented: $showPairingGuide) {
                PairingGuideSheet {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showFilePicker = true
                    }
                }
            }
            .onAppear {
                vm.refreshNetworkStatus()
                vm.refreshPairingFile()
            }
            .refreshable {
                vm.refreshNetworkStatus()
                vm.refreshPairingFile()
            }
        }
    }
}

struct VPNStatusRow: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: vm.vpnUp
                      ? "checkmark.shield.fill"
                      : "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(vm.vpnUp ? .green : .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.vpnUp ? "Loopback VPN Active" : "Loopback VPN Not Detected")
                        .font(.subheadline.bold())
                    Text(vm.vpnUp
                         ? "RSD tunnel ready — PosterLab can talk to the device."
                         : "Connect LocalDevVPN before running flashes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !vm.vpnUp {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Setup LocalDevVPN:")
                        .font(.caption.bold())
                    ForEach([
                        "1. Open LocalDevVPN app and tap Connect.",
                        "2. Return to PosterLab — status indicator turns green."
                    ], id: \.self) { step in
                        Text(step)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Link("Launch LocalDevVPN",
                         destination: URL(string: "localdevvpn://")!)
                        .font(.caption.bold())
                }
                .padding(10)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack(spacing: 8) {
                Text("Device IP:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("10.7.0.1", text: $vm.deviceIP)
                    .font(.caption.monospaced())
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .frame(width: 120)
                Spacer()
                Button {
                    vm.refreshNetworkStatus()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            if !vm.networkDetail.isEmpty {
                Text(vm.networkDetail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct WalletCardView: View {
    let card: CardItem
    let cardIndex: Int
    let onToggleSelected: (Bool) -> Void
    let onPickImage: () -> Void
    let onClearImage: () -> Void
    let onDelete: () -> Void
    let onAddLogo: () -> Void
    var onSaveSkin: (() -> Void)? = nil

    @State private var copied = false

    var body: some View {
        VStack(spacing: 12) {

            GeometryReader { geo in
                let width = geo.size.width
                let height = width / 1.586

                ZStack {
                    if let img = card.uiImage {

                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: width, height: height)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            LinearGradient(
                                colors: [.white.opacity(0.18), .clear, .black.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            HStack(spacing: 8) {
                                if let onSaveSkin {
                                    Button(action: onSaveSkin) {
                                        Image(systemName: "tray.and.arrow.down.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(Color.black.opacity(0.55)))
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button(action: onAddLogo) {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Circle().fill(Color.black.opacity(0.55)))
                                }
                                .buttonStyle(.plain)

                                Button(action: onClearImage) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Circle().fill(Color.black.opacity(0.55)))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                        }
                    } else {

                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(uiColor: .secondarySystemBackground),
                                            Color(uiColor: .tertiarySystemBackground)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    Color.secondary.opacity(0.25),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                )

                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: "wave.3.right")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.secondary.opacity(0.6))
                                    Spacer()
                                    Image(systemName: "creditcard")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.secondary.opacity(0.5))
                                }
                                .padding(14)
                                Spacer()
                            }

                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Theme.accent)

                                Text("Assign Card Skin")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)

                                Text("Tap to choose photo")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                .contentShape(Rectangle())
                .onTapGesture { onPickImage() }
            }
            .aspectRatio(1.586, contentMode: .fit)

            HStack(spacing: 8) {
                Toggle("", isOn: Binding(
                    get: { card.isSelected },
                    set: { onToggleSelected($0) }
                ))
                .labelsHidden()

                Text("Card #\(cardIndex + 1)")
                    .font(.system(size: 13, weight: .semibold))

                HStack(spacing: 4) {
                    Text(card.id.prefix(8) + "…" + card.id.suffix(6))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Button {
                        UIPasteboard.general.string = card.id
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                    } label: {
                        Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundStyle(copied ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(uiColor: .systemFill))
                .clipShape(Capsule())

                Spacer()

                if card.uiImage != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 14))
                }

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(card.isSelected ? Theme.accent.opacity(0.35) : Color.clear, lineWidth: 1.5)
        )
    }
}

struct WalletCardsTab: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var newHashText = ""
    @State private var showAddSheet = false
    enum ActiveCardPicker: Identifiable {
        case singleCard(String)
        case bulkAll
        var id: String {
            switch self {
            case .singleCard(let id): return id
            case .bulkAll: return "bulk_all"
            }
        }
    }
    @State private var activePicker: ActiveCardPicker? = nil
    @State private var showSourceDialog: Bool = false
    @State private var isPhotosPickerPresented: Bool = false
    @State private var isDocumentPickerPresented: Bool = false
    private struct CropRequest: Identifiable {
        let id = UUID()
        let image: UIImage
        let target: ActiveCardPicker
    }
    @State private var pendingCrop: CropRequest?
    @State private var cropRequest: CropRequest?
    @State private var photoLoadFailed = false
    @State private var pendingLoadError = false
    @State private var cropAccepted = false
    @State private var logoOverlayCardId: String? = nil
    @State private var showSaveSkinDialog = false
    @State private var saveSkinName = ""
    @State private var saveSkinImage: UIImage? = nil
    @State private var showSkinLibrary = false
    @State private var skinApplyTarget: String? = nil
    @State private var renamingSkin: SavedCardSkin? = nil
    @State private var renameSkinText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    scannerBanner

                    if !vm.savedCardSkins.isEmpty || !vm.cards.isEmpty {
                        skinLibraryBanner
                    }

                    if vm.cards.isEmpty {
                        walletEmptyState
                            .padding(.top, 40)
                    } else {
                        cardsList
                    }
                }
                .padding(.vertical)
                .transaction { $0.animation = nil }
            }
            .transaction { $0.animation = nil }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Wallet Cards (\(vm.cards.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        vm.toggleCardScanning()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: vm.isScanningCards ? "stop.circle.fill" : "wave.3.left.circle")
                            Text(vm.isScanningCards ? "Stop Scan" : "Scan Cards")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(vm.isScanningCards ? .red : Theme.accent)
                    }
                    .transaction { $0.animation = nil }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showAddSheet = true
                        } label: {
                            Label("Add Card Manually", systemImage: "plus")
                        }
                        if !vm.cards.isEmpty {
                            Button {
                                activePicker = .bulkAll
                                showSourceDialog = true
                            } label: {
                                Label("Set Skin for All Cards...", systemImage: "photo.on.rectangle.angled")
                            }

                            Divider()

                            Button {
                                vm.selectAllCards(true)
                            } label: {
                                Label("Select All", systemImage: "checkmark.circle")
                            }

                            Button {
                                vm.selectAllCards(false)
                            } label: {
                                Label("Deselect All", systemImage: "circle")
                            }

                            Divider()

                            Button(role: .destructive) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                    vm.clearAllCards()
                                }
                            } label: {
                                Label("Clear All Cards", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    flashButton
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddCardSheet(hashText: $newHashText) {
                    vm.addCardHash(newHashText)
                    newHashText = ""
                    showAddSheet = false
                }
            }
            .confirmationDialog("Choose Image Source", isPresented: $showSourceDialog, titleVisibility: .visible) {
                Button {
                    isPhotosPickerPresented = true
                } label: {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }
                Button {
                    isDocumentPickerPresented = true
                } label: {
                    Label("Choose from Files…", systemImage: "folder")
                }
                Button("Cancel", role: .cancel) {
                    activePicker = nil
                }
            }
            .sheet(isPresented: $isPhotosPickerPresented, onDismiss: { activePicker = nil }) {
                if let target = activePicker {
                    CardPhotoPicker { image in
                        assignImage(image, to: target)
                    }
                }
            }
            .sheet(isPresented: $isDocumentPickerPresented, onDismiss: presentPendingCrop) {
                DocumentPickerView(allowedContentTypes: [
                    .image, .png, .jpeg, .heic,
                    UTType(filenameExtension: "webp") ?? .image,
                    UTType(filenameExtension: "tiff") ?? .image
                ]) { url in
                    guard let picker = activePicker else { return }
                    if let data = try? Data(contentsOf: url),
                       let image = ImageEngine.safeImageFromData(data, maxDimension: 2560) {
                        pendingCrop = CropRequest(image: image, target: picker)
                    } else {
                        pendingLoadError = true
                    }
                    activePicker = nil
                }
            }
            .sheet(item: $cropRequest, onDismiss: {
                if !cropAccepted { isDocumentPickerPresented = true }
            }) { request in
                CardPhotoCropView(image: request.image) { croppedImage in
                    cropAccepted = true
                    assignImage(croppedImage, to: request.target)
                    activePicker = nil
                }
            }
            .alert("Couldn't Load Photo", isPresented: $photoLoadFailed) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Choose another image or try downloading the photo to your iPhone first.")
            }
            .sheet(isPresented: Binding(
                get: { logoOverlayCardId != nil },
                set: { if !$0 { logoOverlayCardId = nil } }
            )) {
                if let cardId = logoOverlayCardId,
                   let card = vm.cards.first(where: { $0.id == cardId }),
                   let img = card.uiImage {
                    CardLogoOverlayView(cardImage: img) { composited in
                        vm.setCardImage(for: cardId, image: composited)
                        logoOverlayCardId = nil
                    }
                }
            }
            .alert("Save to Skin Library", isPresented: $showSaveSkinDialog) {
                TextField("Skin name", text: $saveSkinName)
                Button("Save") {
                    if let img = saveSkinImage {
                        vm.saveCardSkinToLibrary(image: img, name: saveSkinName)
                        saveSkinName = ""
                        saveSkinImage = nil
                    }
                }
                Button("Cancel", role: .cancel) { saveSkinName = ""; saveSkinImage = nil }
            } message: {
                Text("Give this card skin a name so you can reuse it later.")
            }
            .sheet(isPresented: $showSkinLibrary) {
                CardSkinLibrarySheet(
                    applyTarget: skinApplyTarget,
                    onApplyToCard: { skin, cardId in
                        vm.applyCardSkinToCard(skin, cardId: cardId)
                        showSkinLibrary = false
                    },
                    onApplyToAll: { skin in
                        vm.applyCardSkinToAllCards(skin)
                        showSkinLibrary = false
                    }
                )
            }
            .alert("Rename skin", isPresented: Binding(
                get: { renamingSkin != nil },
                set: { if !$0 { renamingSkin = nil } }
            )) {
                TextField("New name", text: $renameSkinText)
                Button("Save") {
                    if let s = renamingSkin { vm.renameSavedCardSkin(s, to: renameSkinText) }
                    renamingSkin = nil; renameSkinText = ""
                }
                Button("Cancel", role: .cancel) { renamingSkin = nil; renameSkinText = "" }
            }
        }
    }

    private func assignImage(_ image: UIImage, to target: ActiveCardPicker) {
        switch target {
        case .singleCard(let cardId):
            vm.setCardImage(for: cardId, image: image)
        case .bulkAll:
            vm.setSkinForAllCards(image: image)
        }
    }

    private func presentPendingCrop() {
        guard !isPhotosPickerPresented, !isDocumentPickerPresented else { return }
        if let request = pendingCrop {
            pendingCrop = nil
            cropAccepted = false
            activePicker = request.target
            cropRequest = request
        } else if pendingLoadError {
            pendingLoadError = false
            photoLoadFailed = true
        }
    }

    @ViewBuilder
    private var scannerBanner: some View {
        if vm.isScanningCards || !vm.scanStatusText.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if vm.isScanningCards {
                        ProgressView().scaleEffect(0.85)
                        Text("Live Scanner Active")
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.accent)
                    } else {
                        Image(systemName: "wave.3.left.circle")
                            .foregroundStyle(.secondary)
                        Text("Scanner Status")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if vm.isScanningCards {
                        Button("Stop") {
                            vm.stopCardScanning()
                        }
                        .font(.caption.bold())
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.small)
                    }
                }
                Text(vm.scanStatusText)
                    .font(.caption)
                    .foregroundStyle(vm.scanStatusText.contains("stopped") || vm.scanStatusText.contains("error") ? .orange : .secondary)
            }
            .padding(14)
            .background(vm.isScanningCards ? Theme.accent.opacity(0.12) : Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
            .transaction { $0.animation = nil }
        }
    }

    @ViewBuilder
    private var skinLibraryBanner: some View {
        if !vm.savedCardSkins.isEmpty {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundStyle(Theme.accent)
                    Text("Skin Library")
                        .font(.subheadline.bold())
                    Text("· \(vm.savedCardSkins.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("View All") {
                        skinApplyTarget = nil
                        showSkinLibrary = true
                    }
                    .font(.caption.bold())
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.savedCardSkins) { skin in
                            Button {
                                skinApplyTarget = nil
                                showSkinLibrary = true
                            } label: {
                                VStack(spacing: 4) {
                                    if let preview = skin.previewImage {
                                        Image(uiImage: preview)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 63)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color(uiColor: .tertiarySystemBackground))
                                            .frame(width: 100, height: 63)
                                            .overlay(Image(systemName: "creditcard").foregroundStyle(.secondary))
                                    }
                                    Text(skin.name)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .frame(width: 100)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var cardsList: some View {
        VStack(spacing: 16) {
            ForEach(vm.cards, id: \.id) { card in
                let cardIndex = vm.cards.firstIndex(where: { $0.id == card.id }) ?? 0
                WalletCardView(
                    card: card,
                    cardIndex: cardIndex,
                    onToggleSelected: { isSelected in
                        vm.setCardSelected(id: card.id, selected: isSelected)
                    },
                    onPickImage: {
                        activePicker = .singleCard(card.id)
                        showSourceDialog = true
                    },
                    onClearImage: { vm.clearCardImage(for: card.id) },
                    onDelete: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        vm.deleteCard(id: card.id)
                    },
                    onAddLogo: {
                        logoOverlayCardId = card.id
                    },
                    onSaveSkin: card.uiImage != nil ? {
                        saveSkinImage = card.uiImage
                        showSaveSkinDialog = true
                    } : nil
                )
                .id(card.id)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.85).combined(with: .opacity)
                ))
            }

            if !vm.cardFlashLog.isEmpty {
                CompactLogView(
                    title: "Flash Log (\(vm.cardFlashLog.count) lines)",
                    lines: vm.cardFlashLog,
                    onClear: { vm.cardFlashLog.removeAll() }
                )
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var flashButton: some View {
        Button {
            vm.flashCards()
        } label: {
            HStack(spacing: 6) {
                if case .running = vm.cardFlashPhase {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.75)
                    Text("Flashing…")
                        .font(.system(size: 13, weight: .semibold))
                } else if case .done(let ok) = vm.cardFlashPhase, !ok {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Retry")
                        .font(.system(size: 13, weight: .semibold))
                } else {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Flash")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .padding(.horizontal, 4)
            .frame(minHeight: 28)
        }
        .buttonStyle(.borderedProminent)
        .tint({
            if case .done(let ok) = vm.cardFlashPhase, !ok {
                return Color.orange
            }
            return Theme.accent
        }())
        .disabled(!vm.canFlashCards || vm.cardFlashPhase == .running)
        .animation(.easeInOut(duration: 0.2), value: vm.cardFlashPhase)
    }

    private var walletEmptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent.opacity(0.7))

            VStack(spacing: 6) {
                Text("No Cards Yet")
                    .font(.headline)
                Text("Scan your Apple Pay cards or add hashes manually.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    vm.toggleCardScanning()
                } label: {
                    HStack(spacing: 6) {
                        Spacer()
                        Image(systemName: vm.isScanningCards ? "stop.circle.fill" : "wave.3.left.circle")
                        Text(vm.isScanningCards ? "Stop" : "Scan")
                        Spacer()
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(vm.isScanningCards ? .red : Theme.accent)
                .transaction { $0.animation = nil }

                Button {
                    showAddSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Spacer()
                        Image(systemName: "plus")
                        Text("Add Hash")
                        Spacer()
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.bordered)
                .transaction { $0.animation = nil }
            }
            .padding(.horizontal, 24)
            .transaction { $0.animation = nil }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .transaction { $0.animation = nil }
    }
}

struct AddCardSheet: View {
    @Binding var hashText: String
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Hash") {
                    TextField("Paste card hash (e.g. M6nDwZrkYbFl…)", text: $hashText, axis: .vertical)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .lineLimit(4...8)
                }
                Section {
                    Text("You can add multiple hashes at once — separate them with spaces, commas, or newlines.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { onAdd() }
                        .disabled(hashText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .bold()
                }
            }
        }
    }
}

struct CardSkinLibrarySheet: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let applyTarget: String?
    let onApplyToCard: (SavedCardSkin, String) -> Void
    let onApplyToAll: (SavedCardSkin) -> Void

    @State private var renamingSkin: SavedCardSkin? = nil
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            Group {
                if vm.savedCardSkins.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No saved skins yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Set a skin on any card, then tap the save button to add it here.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 16) {
                            ForEach(vm.savedCardSkins) { skin in
                                skinCard(skin)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Skin Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Rename skin", isPresented: Binding(
                get: { renamingSkin != nil },
                set: { if !$0 { renamingSkin = nil } }
            )) {
                TextField("New name", text: $renameText)
                Button("Save") {
                    if let s = renamingSkin { vm.renameSavedCardSkin(s, to: renameText) }
                    renamingSkin = nil; renameText = ""
                }
                Button("Cancel", role: .cancel) { renamingSkin = nil; renameText = "" }
            }
        }
    }

    private func skinCard(_ skin: SavedCardSkin) -> some View {
        VStack(spacing: 6) {
            if let preview = skin.previewImage {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemBackground))
                    .frame(height: 100)
                    .overlay(Image(systemName: "creditcard").font(.title2).foregroundStyle(.secondary))
            }

            Text(skin.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)

            Text(skin.dateCreated.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)

            HStack(spacing: 6) {
                if let cardId = applyTarget {
                    Button("Apply") {
                        onApplyToCard(skin, cardId)
                    }
                    .font(.caption.bold())
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else if !vm.cards.isEmpty {
                    Button("Apply to All") {
                        onApplyToAll(skin)
                    }
                    .font(.caption.bold())
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                Menu {
                    Button {
                        renameText = skin.name
                        renamingSkin = skin
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        vm.deleteSavedCardSkin(skin)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

struct PasscodeThemeTab: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var renamingThemeFromApply: SavedPasscodeTheme? = nil
    @State private var renameTextFromApply = ""

    var body: some View {
        NavigationStack {
            Form {

                Section {
                    Picker("Mode", selection: $vm.passcodeMode) {
                        ForEach(CreatorMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if vm.passcodeMode == .applyTheme {
                    ApplyThemeSection()
                    applyModeLibrary
                } else {
                    ThemeCreatorSection()
                }

                if !vm.passthmFlashLog.isEmpty {
                    Section {
                        CompactLogView(
                            title: "Flash Log (\(vm.passthmFlashLog.count) lines)",
                            lines: vm.passthmFlashLog,
                            onClear: { vm.passthmFlashLog.removeAll() }
                        )
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }
            .navigationTitle("Passcode Theme")
            .toolbar {
            }
            .onAppear { vm.scanDocumentsDirectory() }
            .alert("Rename theme", isPresented: Binding(
                get: { renamingThemeFromApply != nil },
                set: { if !$0 { renamingThemeFromApply = nil } }
            )) {
                TextField("New name", text: $renameTextFromApply)
                Button("Save") {
                    if let t = renamingThemeFromApply { vm.renameSavedPasscodeTheme(t, to: renameTextFromApply) }
                    renamingThemeFromApply = nil; renameTextFromApply = ""
                }
                Button("Cancel", role: .cancel) { renamingThemeFromApply = nil; renameTextFromApply = "" }
            }
        }
    }

    @ViewBuilder
    private var applyModeLibrary: some View {
        if !vm.savedPasscodeThemes.isEmpty {
            Section(header: Text("Library · \(vm.savedPasscodeThemes.count)")) {
                ForEach(vm.savedPasscodeThemes) { theme in
                    SavedPasscodeThemeRow(
                        theme: theme,
                        onFlash: {
                            vm.loadPassthm(url: theme.fileURL)
                            vm.flashPassthm()
                        },
                        onEdit: {
                            vm.loadSavedPasscodeThemeIntoCreator(theme)
                            vm.passcodeMode = .themeCreator
                        },
                        onExport: { vm.exportSavedPasscodeTheme(theme) },
                        onRename: {
                            renameTextFromApply = theme.name
                            renamingThemeFromApply = theme
                        },
                        onDelete: { vm.deleteSavedPasscodeTheme(theme) }
                    )
                }
            }
        }
    }
}

struct ApplyThemeSection: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showDocumentPicker = false

    var body: some View {

        if !vm.documentsThemes.isEmpty {
            Section("Themes in App Folder (On My iPhone › PosterLab)") {
                ForEach(vm.documentsThemes, id: \.self) { file in
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .foregroundStyle(.pink)
                        Text(file)
                            .font(.system(size: 13, design: .monospaced))
                        Spacer()
                        Button("Load") {
                            vm.loadPassthmFromDocuments(filename: file)
                        }
                        .font(.caption.bold())
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
        }

        Section("Browse Files") {
            HStack {
                Button {
                    showDocumentPicker = true
                } label: {
                    Label(vm.loadedTheme == nil ? "Choose .passthm from Files…" : "Change .passthm…",
                          systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                if vm.loadedTheme != nil {
                    Button {
                        vm.clearLoadedTheme()
                    } label: {
                        Text("Clear")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView(allowedContentTypes: [
                    UTType(filenameExtension: "passthm") ?? .archive,
                    UTType.zip,
                    UTType.archive
                ]) { url in
                    vm.loadPassthm(url: url)
                }
            }
        }

        if let theme = vm.loadedTheme {
            Section("Interactive Lock Screen Preview") {
                KeypadPreviewView(keys: theme.keysPreview)
                    .listRowInsets(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                    .listRowBackground(Color.clear)
            }

            Section("Theme Information") {
                LabeledContent("Files in theme", value: "\(theme.fileCount)")
                LabeledContent("Digits styled", value: "\(theme.keysPreview.count) keys")

                Button {
                    vm.adoptThemeIntoCreator()
                } label: {
                    Label("Edit in Theme Creator", systemImage: "pencil")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.bordered)
            }

            PasscodeTargetSection()

            Section {
                VStack(spacing: 12) {
                    flashButton

                    Button(role: .destructive) {
                        vm.clearLoadedTheme()
                    } label: {
                        HStack(spacing: 8) {
                            Spacer()
                            Image(systemName: "trash")
                            Text("Remove / Unload Theme")
                            Spacer()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
            }
        }
    }

    @ViewBuilder
    private var flashButton: some View {
        if case .running = vm.passthmFlashPhase {
            HStack(spacing: 10) {
                ProgressView()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flashing Theme…").font(.subheadline.bold())
                    ProgressView(value: vm.passthmFlashProgress)
                }
            }
            .padding(.vertical, 4)
        } else if case .done(let ok) = vm.passthmFlashPhase, !ok {
            Button {
                vm.flashPassthm()
            } label: {
                HStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                    Text("Retry Flash Theme")
                    Spacer()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(!vm.canFlashPassthm)
        } else {
            Button {
                vm.flashPassthm()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                    Text("Flash Theme to iPhone")
                }
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundStyle(.white)
                .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Theme.accent.opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!vm.canFlashPassthm)
            .opacity(vm.canFlashPassthm ? 1 : 0.5)
        }
    }
}

struct PasscodeTargetSection: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.badge.clock")
                        .foregroundColor(Theme.accent)
                        .font(.headline)
                    Text("Flash & Language Target")
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("System Caches")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Picker("System Caches", selection: $vm.targetTelephonyVersion) {
                        Text("TelephonyUI-10 (iOS 18+)").tag("TelephonyUI-10")
                        Text("TelephonyUI-9 (iOS 16–17)").tag("TelephonyUI-9")
                        Text("TelephonyUI-8 (iOS 14–15)").tag("TelephonyUI-8")
                        Text("Universal (All)").tag("all")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("System Language")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Picker("System Language", selection: $vm.passcodeLanguageTarget) {
                        ForEach(PasscodeLanguageTarget.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Font Weight / Style")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Picker("Font Weight / Style", selection: $vm.passcodeBoldTarget) {
                        ForEach(PasscodeBoldTarget.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: vm.passcodeLanguageTarget == .all && vm.passcodeBoldTarget == .both ? "globe" : "bolt.fill")
                        .font(.caption)
                        .foregroundColor(vm.passcodeLanguageTarget == .all && vm.passcodeBoldTarget == .both ? .secondary : .orange)
                        .padding(.top, 1)

                    if vm.passcodeLanguageTarget == .all && vm.passcodeBoldTarget == .both {
                        Text("Universal mode flashes ~600 files for all languages & Bold text. Selecting a specific language (e.g. Ukrainian) speeds up flashing dramatically.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Fast mode selected: only targets \(vm.passcodeLanguageTarget.rawValue) with \(vm.passcodeBoldTarget.rawValue).")
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct ThemeCreatorSection: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedDigitForPicker: String? = nil
    @State private var showKeySourceDialog: Bool = false
    @State private var isKeyPhotosPickerPresented: Bool = false
    @State private var isKeyDocumentPickerPresented: Bool = false
    @State private var selectedKey: [PhotosPickerItem] = []

    @State private var showPosterSourceDialog: Bool = false
    @State private var isPosterPhotosPickerPresented: Bool = false
    @State private var isPosterDocumentPickerPresented: Bool = false
    @State private var selectedPoster: [PhotosPickerItem] = []

    var body: some View {
        Section("Slice Mode") {
            Picker("", selection: $vm.sliceMode) {
                ForEach(SliceMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
        }

        if vm.sliceMode == .posterSlice {
            posterSliceSection
        } else {
            individualKeysSection
        }

        Section("Interactive Lock Screen Preview") {
            KeypadPreviewView(keys: vm.effectiveKeys)
                .listRowInsets(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                .listRowBackground(Color.clear)
        }

        PasscodeTargetSection()

        Section {
            VStack(spacing: 12) {
                flashButton

                if !vm.effectiveKeys.isEmpty {
                    Button {
                        showSaveNameDialog = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "tray.and.arrow.down.fill")
                            Text("Save to Library")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .foregroundStyle(Theme.accent)
                        .background(Theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button {
                        _ = vm.exportPassthm()
                    } label: {
                        HStack(spacing: 8) {
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                            Text("Export .passthm...")
                            Spacer()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        vm.clearAllCreator()
                    } label: {
                        HStack(spacing: 8) {
                            Spacer()
                            Image(systemName: "trash")
                            Text("Clear All")
                            Spacer()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
        }

        savedThemesGallery
            .alert("Save to Library", isPresented: $showSaveNameDialog) {
                TextField("Theme name", text: $saveThemeName)
                Button("Save") {
                    let saved = vm.savePasscodeThemeToLibrary(name: saveThemeName)
                    if saved != nil {
                        saveThemeName = ""
                        showSaveToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { showSaveToast = false }
                    }
                }
                Button("Cancel", role: .cancel) { saveThemeName = "" }
            } message: {
                Text("Pick a name for this passcode theme — it'll show up in your library.")
            }
            .alert("Rename theme", isPresented: Binding(
                get: { renamingTheme != nil },
                set: { if !$0 { renamingTheme = nil } }
            )) {
                TextField("New name", text: $renameText)
                Button("Save") {
                    if let t = renamingTheme { vm.renameSavedPasscodeTheme(t, to: renameText) }
                    renamingTheme = nil; renameText = ""
                }
                Button("Cancel", role: .cancel) { renamingTheme = nil; renameText = "" }
            }
    }

    @State private var showSaveNameDialog = false
    @State private var saveThemeName = ""
    @State private var showSaveToast = false
    @State private var renamingTheme: SavedPasscodeTheme? = nil
    @State private var renameText = ""

    @ViewBuilder
    private var savedThemesGallery: some View {
        if !vm.savedPasscodeThemes.isEmpty {
            Section(header: Text("Saved Themes · \(vm.savedPasscodeThemes.count)"),
                    footer: savedThemesFooter) {
                ForEach(vm.savedPasscodeThemes) { theme in
                    SavedPasscodeThemeRow(
                        theme: theme,
                        onFlash: {
                            vm.loadPassthm(url: theme.fileURL)
                            vm.flashPassthm()
                        },
                        onEdit: {
                            vm.loadSavedPasscodeThemeIntoCreator(theme)
                        },
                        onExport: { vm.exportSavedPasscodeTheme(theme) },
                        onRename: {
                            renameText = theme.name
                            renamingTheme = theme
                        },
                        onDelete: { vm.deleteSavedPasscodeTheme(theme) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var savedThemesFooter: some View {
        if showSaveToast {
            Text("Added to Library ✓")
                .font(.caption.bold())
                .foregroundStyle(Theme.accent)
        } else {
            EmptyView()
        }
    }

    private var posterSliceSection: some View {
        Group {
            Section("Poster Image") {
                Button {
                    showPosterSourceDialog = true
                } label: {
                    Label(vm.posterImage == nil ? "Select Photo for Keypad…" : "Change Photo…",
                          systemImage: "photo")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .confirmationDialog("Choose Poster Image Source", isPresented: $showPosterSourceDialog, titleVisibility: .visible) {
                Button {
                    isPosterPhotosPickerPresented = true
                } label: {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }
                Button {
                    isPosterDocumentPickerPresented = true
                } label: {
                    Label("Choose from Files…", systemImage: "folder")
                }
                Button("Cancel", role: .cancel) {}
            }
            .photosPicker(
                isPresented: $isPosterPhotosPickerPresented,
                selection: $selectedPoster,
                maxSelectionCount: 1,
                matching: .images
            )
            .onChange(of: selectedPoster) { _, items in
                guard let item = items.first else { return }
                Task {
                    if let image = await item.loadUIImage(maxDimension: 2560) {
                        await MainActor.run { vm.setPosterImage(image) }
                    }
                    await MainActor.run { selectedPoster = [] }
                }
            }
            .sheet(isPresented: $isPosterDocumentPickerPresented) {
                DocumentPickerView(allowedContentTypes: [
                    .image, .png, .jpeg, .heic,
                    UTType(filenameExtension: "webp") ?? .image,
                    UTType(filenameExtension: "tiff") ?? .image
                ]) { url in
                    if let data = try? Data(contentsOf: url),
                       let image = ImageEngine.safeImageFromData(data, maxDimension: 2560) {
                        vm.setPosterImage(image)
                    }
                }
            }

            if vm.posterImage != nil {
                Section("Slicing Style") {
                    VStack(alignment: .leading, spacing: 6) {
                        Picker("", selection: $vm.maskToCircles) {
                            Text("Seamless Poster").tag(false)
                            Text("Circle Buttons").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: vm.maskToCircles) { _, _ in
                            vm.updatePosterSlicing()
                        }

                        Text(vm.maskToCircles ? "Artwork is clipped into individual circular button icons." : "Seamless artwork spans across dialer keys without circular cuts.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)
                }

                Section("Image Scaling") {
                    Picker("", selection: $vm.posterFillMode) {
                        ForEach(PosterFillMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: vm.posterFillMode) { _, _ in
                        vm.updatePosterSlicing()
                    }

                    Text(vm.posterFillMode == .stretch ? "Image is stretched to fill the keypad grid, ignoring aspect ratio." : "Image covers the grid while keeping its original proportions.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Zoom & Framing")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Reset Position") {
                                withAnimation(.spring()) {
                                    vm.resetPosterPosition()
                                }
                            }
                            .font(.caption2)
                            .buttonStyle(.borderless)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "minus.magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.caption)

                            Slider(value: $vm.posterZoom, in: 0.5...3.0, step: 0.05)
                                .onChange(of: vm.posterZoom) { _, _ in
                                    vm.updatePosterSlicing()
                                }

                            Image(systemName: "plus.magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.caption)

                            Text(String(format: "%.1fx", vm.posterZoom))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .frame(width: 38, alignment: .trailing)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "hand.draw")
                                .foregroundColor(.secondary)
                                .font(.caption2)
                            Text("Drag anywhere on the dialer preview to reposition")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var individualKeysSection: some View {
        Section("Individual Keys") {
            Text("Tap a button row to assign a custom image.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(KeypadLayout.allButtons) { btn in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .secondarySystemBackground))
                            .frame(width: 44, height: 44)
                        if let img = vm.customKeys[btn.digit] {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } else {
                            Text(btn.digit)
                                .font(.title3.bold())
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Key \(btn.digit)")
                            .font(.subheadline.weight(.medium))
                        if !btn.letters.isEmpty {
                            Text(btn.letters)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if vm.customKeys[btn.digit] != nil {
                        Button(role: .destructive) {
                            vm.clearIndividualKey(digit: btn.digit)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.accent)
                            .font(.title3)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedDigitForPicker = btn.digit
                    showKeySourceDialog = true
                }
            }
        }
        .confirmationDialog("Choose Key \(selectedDigitForPicker ?? "") Image Source", isPresented: $showKeySourceDialog, titleVisibility: .visible) {
            Button {
                isKeyPhotosPickerPresented = true
            } label: {
                Label("Photo Library", systemImage: "photo.on.rectangle")
            }
            Button {
                isKeyDocumentPickerPresented = true
            } label: {
                Label("Choose from Files…", systemImage: "folder")
            }
            Button("Cancel", role: .cancel) {
                selectedDigitForPicker = nil
            }
        }
        .photosPicker(
            isPresented: $isKeyPhotosPickerPresented,
            selection: $selectedKey,
            maxSelectionCount: 1,
            matching: .images
        )
        .onChange(of: selectedKey) { _, items in
            guard let item = items.first,
                  let digit = selectedDigitForPicker else {
                if items.isEmpty { selectedDigitForPicker = nil }
                return
            }
            let currentDigit = digit
            Task {
                if let image = await item.loadUIImage(maxDimension: 1024) {
                    await MainActor.run { vm.setIndividualKey(digit: currentDigit, image: image) }
                }
                await MainActor.run {
                    selectedKey = []
                    selectedDigitForPicker = nil
                }
            }
        }
        .sheet(isPresented: $isKeyDocumentPickerPresented) {
            DocumentPickerView(allowedContentTypes: [
                .image, .png, .jpeg, .heic,
                UTType(filenameExtension: "webp") ?? .image,
                UTType(filenameExtension: "tiff") ?? .image
            ]) { url in
                guard let digit = selectedDigitForPicker else { return }
                if let data = try? Data(contentsOf: url),
                   let image = ImageEngine.safeImageFromData(data, maxDimension: 1024) {
                    vm.setIndividualKey(digit: digit, image: image)
                }
                selectedDigitForPicker = nil
            }
        }
    }

    @ViewBuilder
    private var flashButton: some View {
        if case .running = vm.passthmFlashPhase {
            HStack(spacing: 10) {
                ProgressView()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flashing Theme…").font(.subheadline.bold())
                    ProgressView(value: vm.passthmFlashProgress)
                }
            }
            .padding(.vertical, 4)
        } else if case .done(let ok) = vm.passthmFlashPhase, !ok {
            Button {
                vm.flashPassthm()
            } label: {
                HStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                    Text("Retry Flash Theme")
                    Spacer()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(!vm.canFlashPassthm)
        } else {
            Button {
                vm.flashPassthm()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                    Text("Flash Theme to iPhone")
                }
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundStyle(.white)
                .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Theme.accent.opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!vm.canFlashPassthm)
            .opacity(vm.canFlashPassthm ? 1 : 0.5)
        }
    }
}

struct SavedPasscodeThemeRow: View {
    let theme: SavedPasscodeTheme
    let onFlash: () -> Void
    let onEdit: () -> Void
    let onExport: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .short; f.timeStyle = .short; return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let img = theme.previewImage {
                    Image(uiImage: img)
                        .resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 54, height: 72)
            .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(theme.name).font(.subheadline.bold())
                Text("\(theme.keyDigits.count) keys · \(theme.language.uppercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Self.dateFmt.string(from: theme.dateCreated))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Menu {
                Button { onFlash() } label: { Label("Flash Now", systemImage: "bolt.fill") }
                Button { onEdit() } label: { Label("Load into Editor", systemImage: "square.and.pencil") }
                Button { onExport() } label: { Label("Share .passthm", systemImage: "square.and.arrow.up") }
                Button { onRename() } label: { Label("Rename", systemImage: "pencil") }
                Divider()
                Button(role: .destructive) { showDeleteConfirm = true } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
            }
        }
        .confirmationDialog("Delete \"\(theme.name)\"?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct KeypadPreviewView: View {
    @EnvironmentObject var vm: AppViewModel
    let keys: [String: UIImage]

    @State private var dragOffsetStart: CGPoint = .zero
    @State private var isDragging: Bool = false

    private func scaledPosterDimensions(for poster: UIImage, gridW: CGFloat, gridH: CGFloat) -> (width: CGFloat, height: CGFloat) {
        let imgW = poster.size.width
        let imgH = poster.size.height
        guard imgW > 0, imgH > 0 else { return (gridW, gridH) }

        if vm.posterFillMode == .stretch {
            return (width: gridW * vm.posterZoom, height: gridH * vm.posterZoom)
        }

        let imgAspect = imgW / imgH
        let gridAspect = gridW / gridH

        if imgAspect > gridAspect {
            let h = gridH * vm.posterZoom
            return (width: h * imgAspect, height: h)
        } else {
            let w = gridW * vm.posterZoom
            return (width: w, height: w / imgAspect)
        }
    }

    var body: some View {
        let scale: CGFloat = 0.68
        let btnD: CGFloat = KeypadLayout.buttonDiameter * scale
        let colW: CGFloat = KeypadLayout.colWidth * scale
        let rowH: CGFloat = KeypadLayout.rowHeight * scale
        let gridW: CGFloat = KeypadLayout.gridWidth * scale
        let gridH: CGFloat = KeypadLayout.gridHeight * scale

        let isSeamlessPoster = (vm.passcodeMode == .themeCreator && vm.sliceMode == .posterSlice && !vm.maskToCircles && vm.posterImage != nil)

        ZStack {

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.07, green: 0.07, blue: 0.09))

            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.clear, Color.black.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 12) {

                ZStack {

                    if isSeamlessPoster, let poster = vm.posterImage {
                        let dims = scaledPosterDimensions(for: poster, gridW: gridW, gridH: gridH)
                        Image(uiImage: poster)
                            .resizable()
                            .frame(width: dims.width, height: dims.height)
                            .position(
                                x: gridW / 2.0 + (vm.posterOffset.x * scale),
                                y: gridH / 2.0 + (vm.posterOffset.y * scale)
                            )
                    }

                    ForEach(KeypadLayout.allButtons) { btn in
                        let cx = CGFloat(btn.col) * colW + colW / 2
                        let cy = CGFloat(btn.row) * rowH + rowH / 2

                        keypadButton(btn: btn, btnD: btnD, scale: scale, isSeamlessPoster: isSeamlessPoster)
                            .position(x: cx, y: cy)
                    }
                }
                .frame(width: gridW, height: gridH)
                .clipped()
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if vm.passcodeMode == .themeCreator && vm.sliceMode == .posterSlice && vm.posterImage != nil {
                                if !isDragging {
                                    isDragging = true
                                    dragOffsetStart = vm.posterOffset
                                }
                                vm.posterOffset = CGPoint(
                                    x: dragOffsetStart.x + value.translation.width / scale,
                                    y: dragOffsetStart.y + value.translation.height / scale
                                )
                                vm.updatePosterSlicing()
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            dragOffsetStart = vm.posterOffset
                        }
                )

                if vm.passcodeMode == .themeCreator && vm.sliceMode == .posterSlice && vm.posterImage != nil {
                    HStack(spacing: 5) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 10))
                        Text("Drag preview to reposition")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                }
            }
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: (vm.passcodeMode == .themeCreator && vm.sliceMode == .posterSlice && vm.posterImage != nil) ? 320 : 295)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func keypadButton(btn: KeypadButtonGeometry, btnD: CGFloat, scale: CGFloat, isSeamlessPoster: Bool) -> some View {
        ZStack {
            if isSeamlessPoster {

                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: btnD, height: btnD)

                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.0)
                    .frame(width: btnD, height: btnD)

                VStack(spacing: 0) {
                    Text(btn.digit)
                        .font(.system(size: 26 * scale, weight: .light))
                        .foregroundStyle(.white.opacity(0.95))
                    if !btn.letters.isEmpty {
                        Text(btn.letters)
                            .font(.system(size: 8.5 * scale, weight: .semibold))
                            .tracking(0.8 * scale)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            } else if let img = keys[btn.digit] {

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: btnD, height: btnD)

                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: btnD, height: btnD)
                    .clipShape(Circle())

                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                    .frame(width: btnD, height: btnD)
            } else {

                Circle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: btnD, height: btnD)

                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                    .frame(width: btnD, height: btnD)

                VStack(spacing: 0) {
                    Text(btn.digit)
                        .font(.system(size: 26 * scale, weight: .light))
                        .foregroundStyle(.white)
                    if !btn.letters.isEmpty {
                        Text(btn.letters)
                            .font(.system(size: 8.5 * scale, weight: .semibold))
                            .tracking(0.8 * scale)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
        }
        .frame(width: btnD, height: btnD)
    }
}

struct CreditsTab: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header

                    VStack(alignment: .leading, spacing: 14) {
                        developerCard

                        technologyAcks
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            if let img = UIImage(named: "AppIcon") {
                Image(uiImage: img)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
            } else {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accentGradient)
            }

            VStack(spacing: 4) {
                Text("PosterLab")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("Wallpaper studio, wallet skins & passcode themes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.top, 16)
    }

    private var developerCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.accent.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay {
                    Text("G")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("@gerdaroot")
                    .font(.subheadline.bold())
                Text("Developer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Link(destination: URL(string: "https://github.com/gerdaroot")!) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                    Text("GitHub")
                }
                .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(Theme.accent)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var technologyAcks: some View {
        VStack(alignment: .leading, spacing: 12) {
            ackRow(
                icon: "shippingbox.fill",
                iconColor: Theme.accent,
                title: "AirCard-iOS",
                subtitle: "Wallet skins, passcode themes, pairing & .tendies flasher by @mak5er",
                link: ("github.com/Mak5er/AirCard-iOS",
                       URL(string: "https://github.com/Mak5er/AirCard-iOS")!)
            )

            Divider()

            ackRow(
                icon: "bolt.shield.fill",
                iconColor: .orange,
                title: "airlift",
                subtitle: "AirTraffic / ATAirlock sync sandbox escape by @0xjohnnydev",
                link: ("github.com/0xjohnnydev/airlift",
                       URL(string: "https://github.com/0xjohnnydev/airlift")!)
            )

            Divider()

            ackRow(
                icon: "bolt.fill",
                iconColor: .yellow,
                title: "NeoSpring",
                subtitle: "WebKit GPU-process respring — applies wallpapers without a reboot",
                link: ("github.com/rooootdev/neospring",
                       URL(string: "https://github.com/rooootdev/neospring")!)
            )

            Divider()

            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
                VStack(alignment: .leading, spacing: 2) {
                    Text(".passthm format")
                        .font(.subheadline.bold())
                    Text("Passcode-theme standard from the Cowabunga / Nugget ecosystem")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func ackRow(icon: String, iconColor: Color, title: String, subtitle: String,
                        link: (label: String, url: URL)) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link(destination: link.url) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                        Text(link.label)
                    }
                    .font(.caption2.monospaced().bold())
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 2)
                }
            }
        }
    }
}
