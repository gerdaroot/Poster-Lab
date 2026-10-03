

import SwiftUI
import UniformTypeIdentifiers

struct TendiesView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showFilePicker = false
    @State private var selectedDetailItem: TendieItem? = nil
    @State private var isNeoSpringing = false

    private var selectedCount: Int {
        vm.tendieItems.filter { $0.isSelected }.count
    }

    private var selectedAll: Bool {
        !vm.tendieItems.isEmpty && vm.tendieItems.allSatisfy { $0.isSelected }
    }

    var body: some View {
        NavigationStack {
            Form {

                if let err = vm.errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.red)
                            Spacer()
                            Button {
                                vm.errorMessage = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showFilePicker = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.badge.plus")
                            Text(vm.tendieItems.isEmpty ? "Choose .tendies from Files…" : "Import More Wallpapers…")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .foregroundStyle(Theme.accent)
                        .background(Theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                } footer: {
                    if vm.posterBoardContainer.isEmpty {
                        Text("PosterBoard container will be auto-detected automatically on flash.")
                    } else {
                        Text("Target: PosterBoard container detected ✅")
                    }
                }

                Section {
                    Toggle(isOn: $vm.resetPBProtections) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Force PosterBoard Cache Refresh")
                                .font(.subheadline.weight(.medium))
                            Text("Resets file protections so iOS re-indexes wallpapers immediately")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if !vm.tendieItems.isEmpty {
                    Section {
                        HStack {
                            Text("\(vm.tendieItems.count) Wallpapers Imported")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(selectedAll ? "Deselect All" : "Select All") {
                                let target = !selectedAll
                                for i in 0..<vm.tendieItems.count {
                                    vm.tendieItems[i].isSelected = target
                                }
                            }
                            .font(.caption)
                        }

                        ForEach($vm.tendieItems) { $item in
                            TendieRowView(item: $item) {
                                selectedDetailItem = item
                            } onDelete: {
                                vm.deleteTendie(item: item)
                            }
                        }
                    } header: {
                        Text("Wallpapers Gallery")
                    }
                } else {
                    Section {
                        VStack(spacing: 10) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No .tendies wallpapers loaded yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Tap 'Choose .tendies from Files' or copy wallpapers into On My iPhone › PosterLab.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                }

                Section {
                    VStack(spacing: 12) {
                        if case .running = vm.tendiesFlashPhase {
                            HStack(spacing: 10) {
                                ProgressView()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Flashing Wallpapers…").font(.subheadline.bold())
                                    ProgressView(value: vm.tendiesFlashProgress)
                                }
                            }
                            .padding(.vertical, 4)
                        } else {
                            Button {
                                Task {
                                    await vm.flashSelectedTendies()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "sparkles")
                                    Text("Flash \(selectedCount) Wallpaper\(selectedCount == 1 ? "" : "s")")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .foregroundStyle(.white)
                                .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: Theme.accent.opacity(0.35), radius: 10, y: 4)
                            }
                            .buttonStyle(.plain)
                            .disabled(selectedCount == 0)
                            .opacity(selectedCount == 0 ? 0.5 : 1)
                        }

                        Button {
                            vm.isNeoSpringing = true
                            isNeoSpringing = true
                            RespringHelper.triggerNeoSpring()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "bolt.fill")
                                Text("Respring (NeoSpring)")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .foregroundStyle(.red)
                            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.red.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
                } footer: {
                    Text("Flashing will automatically trigger NeoSpring to respring the device and apply your new wallpapers.")
                }

                if !vm.tendiesFlashLog.isEmpty {
                    Section {
                        CompactLogView(
                            title: "Flash Log (\(vm.tendiesFlashLog.count) lines)",
                            lines: vm.tendiesFlashLog,
                            onClear: { vm.tendiesFlashLog.removeAll() }
                        )
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }
            .navigationTitle("Wallpapers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilePicker = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                TendiesDocumentPickerView { urls in
                    Task {
                        await vm.importTendieFiles(urls: urls)
                    }
                }
            }
            .sheet(item: $selectedDetailItem) { item in
                TendieDetailSheet(item: item)
            }
            .onAppear {
                vm.isNeoSpringing = false
                isNeoSpringing = false
                vm.showSuccessAlert = false
                vm.successAlertMessage = ""
                vm.scanDocumentsForTendies()
            }
            .task {
                if vm.posterBoardContainer.isEmpty {
                    await vm.autoDetectPosterBoardContainer(silent: true)
                }
            }
            .overlay {
                if isNeoSpringing || vm.isNeoSpringing {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        NeoSpringView()
                            .brightness(-1.0)
                            .ignoresSafeArea()
                    }
                }
            }
        }
    }
}

struct TendieRowView: View {
    @Binding var item: TendieItem
    let onInspect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $item.isSelected)
                .labelsHidden()

            if let imgData = item.previewImageData, let uiImg = UIImage(data: imgData) {
                Image(uiImage: uiImg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 60)
                    .cornerRadius(6)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(width: 44, height: 60)
                    .overlay {
                        Image(systemName: item.posterType.systemIcon)
                            .foregroundColor(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.posterType.rawValue)
                        .font(.caption2.bold())
                        .foregroundColor(item.posterType.badgeColor)

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(item.descriptorCount) item\(item.descriptorCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                onInspect()
            } label: {
                Image(systemName: "info.circle")
                    .foregroundColor(Theme.accent)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

struct TendieDetailSheet: View {
    let item: TendieItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let imgData = item.previewImageData, let uiImg = UIImage(data: imgData) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .cornerRadius(12)
                            .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                            .listRowBackground(Color.clear)
                    }
                }

                Section("Information") {
                    detailRow(title: "Name", value: item.name)
                    detailRow(title: "File Name", value: item.fileName)
                    detailRow(title: "Type", value: item.posterType.rawValue)
                    detailRow(title: "Descriptors", value: "\(item.descriptorCount)")
                    detailRow(title: "Target Extension", value: item.posterType.extensionBundleId)
                    detailRow(title: "Format", value: item.isContainer ? "App Container" : "Descriptor Archive")
                    if item.unsafeContainer {
                        detailRow(title: "Warning", value: "Contains SQLite database")
                    }
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct TendiesDocumentPickerView: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        var contentTypes: [UTType] = []
        if let customType = UTType("com.posterlab.tendies") {
            contentTypes.append(customType)
        }
        if let extType = UTType(filenameExtension: "tendies") {
            contentTypes.append(extType)
        }
        contentTypes.append(contentsOf: [.archive, .zip, .data, .item])

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: TendiesDocumentPickerView

        init(_ parent: TendiesDocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard !urls.isEmpty else { return }
            parent.onPick(urls)
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
