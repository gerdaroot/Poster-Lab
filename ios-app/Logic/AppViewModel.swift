import Foundation
import UIKit
import SwiftUI
import AirliftFFI

@MainActor
final class AppViewModel: ObservableObject {

    static var sharedLogSink: ((String) -> Void)? = nil
    static weak var shared: AppViewModel? = nil

    @Published var pairingStatus: String = ""
    @Published var pairingPIN: String? = nil
    @Published var hasPairingFile: Bool = false
    @Published var pairingFileName: String = ""
    @Published var pairingPhase: PairingPhase = .idle
    @Published var documentsPlistFiles: [String] = []

    enum PairingPhase: Equatable {
        case idle, pairing
    }

    @Published var vpnUp: Bool = false
    @Published var wifiUp: Bool = false
    @Published var networkDetail: String = ""
    @Published var deviceIP: String = "10.7.0.1"

    @Published var selectedTab: AppTab = .pairing

    @Published var cards: [CardItem] = []
    @Published var cardFlashPhase: FlashPhase = .idle
    @Published var cardFlashProgress: Double = 0
    @Published var cardFlashLog: [String] = []

    enum FlashPhase: Equatable {
        case idle, running, done(ok: Bool)
    }

    @Published var passcodeMode: CreatorMode = .applyTheme
    @Published var loadedTheme: PasscodeThemeInfo? = nil
    @Published var documentsThemes: [String] = []
    @Published var sliceMode: SliceMode = .posterSlice

    @Published var posterImage: UIImage? = nil
    @Published var posterZoom: CGFloat = 1.0
    @Published var posterOffset: CGPoint = .zero
    @Published var maskToCircles: Bool = false
    @Published var posterFillMode: PosterFillMode = .fill
    @Published var slicedKeys: [String: UIImage] = [:]

    @Published var customKeys: [String: UIImage] = [:]
    @Published var rawIndividualImages: [String: UIImage] = [:]
    @Published var individualOffsets: [String: CGPoint] = [:]
    @Published var individualZooms: [String: CGFloat] = [:]
    @Published var selectedKeyDigit: String? = nil

    @Published var passthmFlashPhase: FlashPhase = .idle
    @Published var passthmFlashProgress: Double = 0
    @Published var passthmFlashLog: [String] = []

    @Published var savedPasscodeThemes: [SavedPasscodeTheme] = []

    @Published var tendieItems: [TendieItem] = []
    @Published var posterBoardContainer: String = ""
    @Published var isDetectingContainer: Bool = false
    @Published var resetPBProtections: Bool = true
    @Published var tendiesFlashPhase: FlashPhase = .idle
    @Published var tendiesFlashProgress: Double = 0
    @Published var tendiesFlashLog: [String] = []
    @Published var isNeoSpringing: Bool = false

    static var detectedDeviceLanguage: PasscodeLanguageTarget {
        let code = Locale.preferredLanguages.first?.components(separatedBy: "-").first?.lowercased() ?? "en"
        for target in PasscodeLanguageTarget.allCases {
            if target.code == code {
                return target
            }
        }
        return .en
    }

    @Published var targetTelephonyVersion: String = "TelephonyUI-10"
    @Published var passcodeLanguageTarget: PasscodeLanguageTarget = AppViewModel.detectedDeviceLanguage
    @Published var passcodeBoldTarget: PasscodeBoldTarget = .both
    @Published var showSuccessAlert: Bool = false
    @Published var successAlertMessage: String = ""
    @Published var exportedThemeURL: URL? = nil
    @Published var showShareSheet: Bool = false

    @Published var errorMessage: String? = nil
    @Published var log: [String] = []
    @Published var showDeletePairingConfirm: Bool = false

    private let storageKeys = [
        "posterlab.cards",
        "posterlab-ios.cards",
        "airlift.cards",
        "mak5er.savedCards",
        "LumiCards.savedCards",
        "savedCards"
    ]

    init() {
        Self.shared = self
        refreshPairingFile()
        loadSavedCards()
        refreshNetworkStatus()
        scanDocumentsDirectory()
        posterBoardContainer = UserDefaults.standard.string(forKey: "posterlab.posterboard_container") ?? ""
        loadSavedTendies()
        loadSavedPasscodeThemes()

        AppViewModel.sharedLogSink = { [weak self] line in
            self?.log.append(line)
        }
    }

    func scanDocumentsDirectory() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: docs.path) else { return }

        documentsPlistFiles = items.filter { item in
            let lower = item.lowercased()
            let isPairingExt = lower.hasSuffix(".plist") || lower.hasSuffix(".mobiledevicepairing") || lower.hasSuffix(".mobilepair")
            let isCanonical = item == "posterlab_pairing.plist" || item == "airlift_pairing.plist" || item == "Info.plist"
            return isPairingExt && !isCanonical
        }.sorted()

        documentsThemes = items.filter { $0.hasSuffix(".passthm") }.sorted()

        scanDocumentsForTendies()
    }

    func scanDocumentsForTendies() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let tendiesDir = TendiesEngine.tendiesStorageDirectory

        var foundURLs: [URL] = []
        if let rootItems = try? FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil) {
            for u in rootItems where u.pathExtension.lowercased() == "tendies" {
                let target = tendiesDir.appendingPathComponent(u.lastPathComponent)
                if u.path != target.path && !FileManager.default.fileExists(atPath: target.path) {
                    try? FileManager.default.copyItem(at: u, to: target)
                }
                foundURLs.append(target)
            }
        }
        if let storedItems = try? FileManager.default.contentsOfDirectory(at: tendiesDir, includingPropertiesForKeys: nil) {
            for u in storedItems where u.pathExtension.lowercased() == "tendies" {
                if !foundURLs.contains(u) {
                    foundURLs.append(u)
                }
            }
        }

        let newURLs = foundURLs.filter { url in
            !tendieItems.contains(where: { $0.fileName == url.lastPathComponent })
        }

        guard !newURLs.isEmpty else { return }

        Task {
            await self.importTendieFiles(urls: newURLs)
        }
    }

    @discardableResult
    func importPairingFile(from sourceURL: URL, originalName: String? = nil) -> Bool {
        let isSecured = sourceURL.startAccessingSecurityScopedResource()
        defer { if isSecured { sourceURL.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: sourceURL), !data.isEmpty else {
            errorMessage = "Selected pairing file is empty or could not be read."
            return false
        }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let posterlabURL = docs.appendingPathComponent("posterlab_pairing.plist")
        let airliftURL = docs.appendingPathComponent("airlift_pairing.plist")

        do {
            try data.write(to: posterlabURL, options: .atomic)
            try data.write(to: airliftURL, options: .atomic)

            if let orig = originalName, !orig.isEmpty,
               orig != "posterlab_pairing.plist" && orig != "airlift_pairing.plist" {
                let origURL = docs.appendingPathComponent(orig)
                if origURL.path != sourceURL.path {
                    try? data.write(to: origURL, options: .atomic)
                }
            }

            PairingController.customPairingFilePath = posterlabURL.path
            refreshPairingFile()
            let display = originalName ?? sourceURL.lastPathComponent
            pairingStatus = "Pairing file loaded ✅ (\(display))"
            log.append("Imported pairing file: \(display) (\(data.count) bytes)")
            return true
        } catch {
            errorMessage = "Failed to save pairing file: \(error.localizedDescription)"
            return false
        }
    }

    func selectPairingFile(filename: String) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = docs.appendingPathComponent(filename).path
        let canonical = PairingController.syncCanonicalPairingFile(from: path)
        let exists = FileManager.default.fileExists(atPath: canonical) &&
            ((try? FileManager.default.attributesOfItem(atPath: canonical)[.size] as? Int) ?? 0) > 0
        hasPairingFile = exists
        pairingFileName = exists ? (path as NSString).lastPathComponent : ""
        if exists {
            pairingStatus = "Active: \(pairingFileName) ✅"
            log.append("Selected pairing file: \(pairingFileName)")
        }
        scanDocumentsDirectory()
    }

    func refreshPairingFile() {
        let path = PairingController.pairingFilePath()
        let exists = FileManager.default.fileExists(atPath: path) &&
            ((try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int) ?? 0) > 0
        hasPairingFile = exists
        pairingFileName = exists ? (path as NSString).lastPathComponent : ""
        scanDocumentsDirectory()
    }

    var pairingFileSizeString: String {
        let path = PairingController.pairingFilePath()
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64 else { return "0 B" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    func startPairing() {
        pairingPhase = .pairing
        pairingPIN = nil
        pairingStatus = "Starting local host…"
        errorMessage = nil

        let ctrl = PairingController.shared

        Task {
            do {
                let path = try await ctrl.startAndWait()
                await MainActor.run {
                    self.pairingPhase = .idle
                    self.refreshPairingFile()
                    self.pairingStatus = "Paired successfully! ✅"
                    self.log.append("Pairing complete: \(path)")
                }
            } catch is CancellationError {
                self.pairingPhase = .idle
                self.pairingStatus = "Cancelled."
            } catch {
                self.pairingPhase = .idle
                self.pairingStatus = ""
                self.errorMessage = "Pairing failed: \(error.localizedDescription)"
            }
        }

        Task {
            while pairingPhase == .pairing {
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    guard self.pairingPhase == .pairing else { return }
                    self.pairingStatus = ctrl.pairingStatus
                    self.pairingPIN   = ctrl.pairingPIN
                }
            }
        }
    }

    func cancelPairing() {
        PairingController.shared.softCancel()
        pairingPhase = .idle
        pairingStatus = ""
    }

    func deletePairingFile() {
        PairingController.deleteStoredPairingCredentials()
        hasPairingFile = false
        pairingFileName = ""
        pairingStatus = "Pairing file deleted"
        log.append("Deleted active pairing credentials")
        scanDocumentsDirectory()
    }

    func refreshNetworkStatus() {
        let ip = deviceIP
        let (vpn, wifi, detail) = NetworkStatus.summarize(deviceIP: ip)
        vpnUp = vpn
        wifiUp = wifi
        networkDetail = detail
    }

    @Published var isScanningCards: Bool = false
    @Published var scanStatusText: String = ""
    private var stopScanningFlag = false

    nonisolated static let cardRegexes: [NSRegularExpression] = [
        try! NSRegularExpression(pattern: "/(?:Cards|Passes/Cards)/([-A-Za-z0-9_+=]{20,44})(?:\\.pkpass|\\.cache|\\.pkcache|/|\\s|\"|'|\\)|,|$)"),
        try! NSRegularExpression(pattern: "/([-A-Za-z0-9_+=]{20,44})\\.(?:pkpass|cache|pkcache)"),
        try! NSRegularExpression(pattern: "(?<![A-Za-z0-9+/_-])([A-Za-z0-9+/_-]{27}=)(?![A-Za-z0-9+/_-])"),
        try! NSRegularExpression(pattern: #"PDCardFileManager: writing card\s+([A-Za-z0-9+/_-]+={0,2})(?=\s|\)|,|$)"#),
        try! NSRegularExpression(pattern: #"PDPassLibrary: wrote pass\s+([A-Za-z0-9+/_-]+={0,2})(?=\s|\)|,|$)"#),
        try! NSRegularExpression(pattern: #"VerificationCheck\.([A-Za-z0-9+/_-]+={0,2})(?=\s|\)|,|$)"#)
    ]

    func toggleCardScanning() {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            if isScanningCards {
                stopCardScanning()
            } else {
                startCardScanning()
            }
        }
    }

    private static let dummyCardHashes: Set<String> = [
        "OM6NYhwXMZrAw0sRUjR62wmF4ZQ=",
        "M6nDwZrkYbFlsodLgCbvyFZQ1cc=",
        "kJL-D0rr-SZhbj2c8nK-OQ9hCMY=",
        "hwAtAmHKYwsQrJbT5cTNDsaxVME="
    ]

    func startCardScanning() {
        guard !isScanningCards else { return }
        guard hasPairingFile else {
            errorMessage = "Pairing file is required before scanning. Pair this iPhone or select a .plist first."
            return
        }

        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            isScanningCards = true
            scanStatusText = "Open Apple Pay (double-click Side button) and tap your card…"
        }
        log.append("Started live card scanner…")

        let pairingPath = PairingController.pairingFilePath()

        let thread = Thread {
            var outError: UnsafeMutablePointer<CChar>? = nil

            let rc = pairingPath.withCString { pairC in
                al_syslog_stream_start(
                    pairC,
                    { _, line in
                        guard let line = line else { return }
                        let lineStr = String(cString: line)
                        let lower = lineStr.lowercased()

                        if lower.contains("pass") ||
                           lower.contains("card") ||
                           lower.contains("stockholm") ||
                           lower.contains("wallet") ||
                           lower.contains("nanopass") ||
                           lower.contains("verificationcheck") {
                            DispatchQueue.main.async {
                                AppViewModel.shared?.processSyslogLine(lineStr)
                            }
                        }
                    },
                    nil,
                    &outError
                )
            }

            let errStr = outError.flatMap { String(validatingUTF8: $0) }
            if let p = outError { al_string_free(p) }

            DispatchQueue.main.async {
                guard let vm = AppViewModel.shared else { return }
                vm.isScanningCards = false
                if rc != 0 {
                    let msg = errStr ?? "rc=\(rc)"
                    vm.scanStatusText = "Scanner stopped: \(msg)"
                    vm.log.append("❌ Scanner error: \(msg)")
                    vm.errorMessage = "Card scanner error: \(msg)"
                } else {
                    vm.scanStatusText = "Scanning stopped. Total cards: \(vm.cards.count)."
                    vm.log.append("Scanning stopped. Total cards: \(vm.cards.count).")
                }
            }
        }
        thread.name = "PosterLab.SyslogScanner"
        thread.stackSize = 4 * 1024 * 1024
        thread.qualityOfService = .userInitiated
        thread.start()
    }

    func stopCardScanning() {
        al_syslog_stream_stop()
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            isScanningCards = false
            scanStatusText = "Scanning stopped. Total cards: \(cards.count)."
        }
        saveCards()
    }

    func processSyslogLine(_ line: String) {
        let lower = line.lowercased()
        let isWalletSubsystem = lower.contains("passd") ||
                                lower.contains("passbook") ||
                                lower.contains("passkit") ||
                                lower.contains("stockholm") ||
                                lower.contains("nanopassd") ||
                                lower.contains("wallet") ||
                                lower.contains("pdcardfilemanager") ||
                                lower.contains("pdpasslibrary") ||
                                lower.contains("verificationcheck") ||
                                lower.contains("/cards/")

        guard isWalletSubsystem else { return }

        let isWalletContext = lower.contains("card") ||
                              lower.contains("pass") ||
                              lower.contains("payment") ||
                              lower.contains("pkpass") ||
                              lower.contains("uniqueid") ||
                              lower.contains("identifier") ||
                              lower.contains("face") ||
                              lower.contains("cache") ||
                              lower.contains("stockholm") ||
                              lower.contains("pdcardfilemanager") ||
                              lower.contains("pdpasslibrary") ||
                              lower.contains("verificationcheck") ||
                              lower.contains("/cards/")

        guard isWalletContext else { return }

        for regex in Self.cardRegexes {
            let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))
            for m in matches {
                if m.numberOfRanges > 1, let r = Range(m.range(at: 1), in: line) {
                    let candidateRaw = String(line[r])
                    guard let candidate = CardItem.cleanCardId(candidateRaw) else { continue }
                    if Self.dummyCardHashes.contains(candidate) { continue }
                    if !self.cards.contains(where: { $0.id == candidate }) {
                        self.cards.append(CardItem(id: candidate, isSelected: true))
                        self.saveCards()
                        self.scanStatusText = "Found card: \(candidate)"
                        self.log.append("Found card: \(candidate)")
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }
                }
            }
        }
    }

    nonisolated static func cardImagePath(for cardId: String) -> URL {
        let safeId = cardId.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "+", with: "-")
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let cardsDir = docDir.appendingPathComponent("WalletCards", isDirectory: true)
        if !FileManager.default.fileExists(atPath: cardsDir.path) {
            try? FileManager.default.createDirectory(at: cardsDir, withIntermediateDirectories: true)
        }
        return cardsDir.appendingPathComponent("card_\(safeId).png")
    }

    func loadSavedCards() {
        var foundHashes: [String] = []
        for key in storageKeys {
            if let saved = UserDefaults.standard.stringArray(forKey: key), !saved.isEmpty {
                foundHashes = saved
                break
            }
        }
        var unique: [String] = []
        for raw in foundHashes {
            if let clean = CardItem.cleanCardId(raw), !unique.contains(clean) {
                unique.append(clean)
            }
        }
        cards = unique.filter { !Self.dummyCardHashes.contains($0) }.map { id in
            let path = Self.cardImagePath(for: id)
            let data = try? Data(contentsOf: path)

            let img = data.flatMap { ImageEngine.safeImageFromData($0, maxDimension: 512) }
            return CardItem(id: id, customImageData: data, customImage: img)
        }
    }

    func clearAllCards() {
        for card in cards {
            let path = Self.cardImagePath(for: card.id)
            try? FileManager.default.removeItem(at: path)
        }
        cards.removeAll()
        saveCards()
    }

    func saveCards() {
        let hashes = cards.map(\.id)
        UserDefaults.standard.set(hashes, forKey: "posterlab.cards")
        UserDefaults.standard.set(hashes, forKey: "airlift.cards")
        UserDefaults.standard.set(hashes, forKey: "mak5er.savedCards")
    }

    func setSkinForAllCards(image: UIImage) {
        for card in cards where card.isSelected {
            setCardImage(for: card.id, image: image)
        }
    }

    func selectAllCards(_ selected: Bool) {
        guard !cards.isEmpty else { return }
        cards = cards.map {
            var c = $0
            c.isSelected = selected
            return c
        }
    }

    func addCardHash(_ raw: String) {
        let parts = raw.components(separatedBy: CharacterSet(charactersIn: " \n\r\t,;"))
        var added = 0
        for p in parts {
            if let clean = CardItem.cleanCardId(p),
               !cards.contains(where: { $0.id == clean }) {
                cards.append(CardItem(id: clean))
                added += 1
            }
        }
        if added > 0 { saveCards() }
    }

    func setCardSelected(id: String, selected: Bool) {
        if let idx = cards.firstIndex(where: { $0.id == id }) {
            cards[idx].isSelected = selected
        }
    }

    func deleteCard(id: String) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            cards.removeAll { $0.id == id }
        }
        saveCards()
        let path = Self.cardImagePath(for: id)
        try? FileManager.default.removeItem(at: path)
    }

    func clearCardImage(for cardId: String) {
        if let idx = cards.firstIndex(where: { $0.id == cardId }) {
            cards[idx].customImage = nil
            cards[idx].customImageData = nil
        }
        let path = Self.cardImagePath(for: cardId)
        try? FileManager.default.removeItem(at: path)
    }

    func setCardImage(for cardId: String, image: UIImage) {
        guard let idx = cards.firstIndex(where: { $0.id == cardId }) else { return }

        let thumb = ImageEngine.normalizeAndDownsample(image, maxDimension: 512)
        cards[idx].customImage = thumb

        let actualId = cards[idx].id
        let path = Self.cardImagePath(for: actualId)

        Task.detached(priority: .userInitiated) {
            let data = ImageEngine.prepareCardImage(from: image)
            if let data = data {
                try? data.write(to: path)
            }
            await MainActor.run {
                if let i = AppViewModel.shared?.cards.firstIndex(where: { $0.id == actualId }) {
                    AppViewModel.shared?.cards[i].customImageData = data
                }
            }
        }
    }

    var canFlashCards: Bool {
        hasPairingFile &&
        cardFlashPhase != .running &&
        cards.contains { $0.isSelected && ($0.customImage != nil || $0.customImageData != nil) }
    }

    func flashCards() {
        guard canFlashCards else { return }
        let selected = cards.filter { $0.isSelected && ($0.customImage != nil || $0.customImageData != nil) }
        guard !selected.isEmpty else { return }

        cardFlashPhase    = .running
        cardFlashProgress = 0
        cardFlashLog.removeAll()
        errorMessage = nil

        if !vpnUp {
            cardFlashLog.append("⚠️ Notice: Loopback VPN not detected, attempting direct loopback (127.0.0.1)...")
        }

        let pairingPath = PairingController.pairingFilePath()

        Task.detached { [weak self] in
            guard let self = self else { return }
            let total = Double(selected.count)
            var successCount = 0
            for (i, card) in selected.enumerated() {
                let cleanId = CardItem.cleanCardId(card.id) ?? card.id
                let safeCardId = cleanId.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "+", with: "-")

                await MainActor.run {
                    self.cardFlashLog.append("[\(i+1)/\(selected.count)] Flashing card \(cleanId.prefix(12))…")
                    self.cardFlashProgress = Double(i) / total
                }

                let sourceImg: UIImage? = {
                    if let d = card.customImageData, let img = UIImage(data: d) { return img }
                    let p = Self.cardImagePath(for: cleanId)
                    if let d = try? Data(contentsOf: p), let img = UIImage(data: d) { return img }
                    return card.customImage
                }()

                guard let sourceImg = sourceImg else {
                    await MainActor.run { self.cardFlashLog.append("  ⚠️ No image for card \(cleanId.prefix(8))") }
                    continue
                }

                let allSkins = ImageEngine.prepareAllCardSkins(from: sourceImg)
                guard !allSkins.isEmpty else {
                    await MainActor.run { self.cardFlashLog.append("  ⚠️ Failed to generate card skins") }
                    continue
                }

                let stageCardDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("airlift_card_\(safeCardId)_\(UUID().uuidString)")
                try? FileManager.default.createDirectory(at: stageCardDir, withIntermediateDirectories: true)

                for (name, data) in allSkins {
                    try? data.write(to: stageCardDir.appendingPathComponent(name))
                }

                let pkpassTarget = "/var/mobile/Library/Passes/Cards/\(cleanId).pkpass"

                await MainActor.run {
                    self.cardFlashLog.append("  ⚡ Injecting skins into \(cleanId.prefix(10)).pkpass…")
                }

                var writeOk = false
                var errDesc: String? = nil
                await withCheckedContinuation { cont in
                    DispatchQueue.global(qos: .userInitiated).async {
                        var outError: UnsafeMutablePointer<CChar>? = nil
                        let rc = pairingPath.withCString { pairC in
                            stageCardDir.path.withCString { srcC in
                                pkpassTarget.withCString { tgtC in
                                    al_exploit_write_dir(pairC, srcC, tgtC, { _, msg in
                                        guard let msg = msg else { return }
                                        let line = String(cString: msg)
                                        DispatchQueue.main.async { AppViewModel.shared?.cardFlashLog.append("    " + line) }
                                    }, nil, &outError)
                                }
                            }
                        }
                        if let p = outError {
                            errDesc = String(validatingUTF8: p)
                            al_string_free(p)
                        }
                        writeOk = (rc == 0)
                        cont.resume()
                    }
                }

                try? FileManager.default.removeItem(at: stageCardDir)

                if !writeOk {
                    await MainActor.run {
                        self.cardFlashLog.append("  ❌ Failed to write card skins: \(errDesc ?? "exploit error")")
                    }
                    continue
                }

                await MainActor.run {
                    self.cardFlashLog.append("  ✅ Skins applied! Invalidating pass cache…")
                }

                let stageInvDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("airlift_inv_\(UUID().uuidString)")
                try? FileManager.default.createDirectory(at: stageInvDir, withIntermediateDirectories: true)
                for leaf in ["FrontFace", "Preview", "PlaceHolder"] {
                    try? Data("corrupted".utf8).write(to: stageInvDir.appendingPathComponent(leaf))
                }

                for ext in [".cache", ".pkcache"] {
                    let cacheTarget = "/var/mobile/Library/Passes/Cards/\(cleanId)\(ext)"
                    await withCheckedContinuation { cont in
                        DispatchQueue.global(qos: .userInitiated).async {
                            var outError: UnsafeMutablePointer<CChar>? = nil
                            _ = pairingPath.withCString { pairC in
                                stageInvDir.path.withCString { srcC in
                                    cacheTarget.withCString { tgtC in
                                        al_exploit_write_dir(pairC, srcC, tgtC, nil, nil, &outError)
                                    }
                                }
                            }
                            if let p = outError { al_string_free(p) }
                            cont.resume()
                        }
                    }
                }
                try? FileManager.default.removeItem(at: stageInvDir)

                successCount += 1
                await MainActor.run {
                    self.cardFlashLog.append("  ✅ Pass cache invalidated")
                    self.cardFlashProgress = Double(i + 1) / total
                }
            }

            await MainActor.run {
                if successCount > 0 {
                    self.cardFlashPhase = .done(ok: true)
                    self.cardFlashProgress = 1.0
                    self.cardFlashLog.append("🎉 \(successCount)/\(selected.count) card(s) flashed! Force-close Wallet app to see changes.")
                    self.successAlertMessage = "Skins successfully applied to \(successCount) card(s)!\n\nPlease force-close the Wallet app on your iPhone (or reboot) to see your new designs."
                    self.showSuccessAlert = true
                } else {
                    self.cardFlashPhase = .done(ok: false)
                    self.cardFlashLog.append("❌ Card flash failed. Check connection and try again.")
                }
            }
        }
    }

    var effectiveKeys: [String: UIImage] {
        sliceMode == .posterSlice ? slicedKeys : customKeys
    }

    func setPosterImage(_ img: UIImage) {
        posterImage = img
        posterZoom = 1.0
        posterOffset = .zero
        posterFillMode = .fill
        updatePosterSlicing()
    }

    func updatePosterSlicing() {
        guard let img = posterImage else { slicedKeys = [:]; return }
        slicedKeys = ImageEngine.slicePoster(
            image: img,
            zoom: posterZoom,
            offset: posterOffset,
            maskToCircles: maskToCircles,
            fillMode: posterFillMode
        )
    }

    func setIndividualKey(digit: String, image: UIImage) {
        rawIndividualImages[digit] = image
        individualOffsets[digit] = .zero
        individualZooms[digit] = 1.0
        selectedKeyDigit = digit
        updateIndividualKey(digit: digit)
    }

    func updateIndividualKey(digit: String) {
        guard let raw = rawIndividualImages[digit] else { return }
        let offset = individualOffsets[digit] ?? .zero
        let zoom   = individualZooms[digit] ?? 1.0
        if let cropped = ImageEngine.cropToCircle(
            image: raw,
            targetSize: CGSize(width: 225, height: 225),
            circleDiameter: 222.0,
            zoom: zoom,
            offset: offset
        ) {
            customKeys[digit] = cropped
        }
    }

    func clearIndividualKey(digit: String) {
        customKeys.removeValue(forKey: digit)
        rawIndividualImages.removeValue(forKey: digit)
        individualOffsets.removeValue(forKey: digit)
        individualZooms.removeValue(forKey: digit)
        if selectedKeyDigit == digit { selectedKeyDigit = nil }
    }

    func clearAllCreator() {
        posterImage = nil
        posterZoom = 1.0
        posterOffset = .zero
        slicedKeys.removeAll()
        customKeys.removeAll()
        rawIndividualImages.removeAll()
        individualOffsets.removeAll()
        individualZooms.removeAll()
        selectedKeyDigit = nil
    }

    func loadPassthm(url: URL) {
        Task.detached {
            let result = PasscodeThemeReader.inspect(url: url)
            await MainActor.run {
                if let (keys, rawData, count) = result {
                    self.loadedTheme = PasscodeThemeInfo(
                        name: url.deletingPathExtension().lastPathComponent,
                        filePath: url.path,
                        fileCount: count,
                        keysPreview: keys,
                        rawKeyData: rawData
                    )
                } else {
                    self.errorMessage = "Failed to read .passthm — invalid or unsupported format."
                }
            }
        }
    }

    func loadPassthmFromDocuments(filename: String) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(filename)
        loadPassthm(url: url)
    }

    func clearLoadedTheme() {
        loadedTheme = nil
        passthmFlashPhase = .idle
        passthmFlashProgress = 0
        passthmFlashLog.removeAll()
    }

    var canFlashPassthm: Bool {
        guard hasPairingFile && passthmFlashPhase != .running else { return false }
        switch passcodeMode {
        case .applyTheme:
            return loadedTheme != nil && !(loadedTheme?.keysPreview.isEmpty ?? true)
        case .themeCreator:
            return !effectiveKeys.isEmpty
        }
    }

    func flashPassthm() {
        guard canFlashPassthm else { return }

        let isCreator = (passcodeMode == .themeCreator)
        let keys: [String: UIImage]
        let rawKeys: [String: Data]

        if isCreator {
            keys = effectiveKeys
            rawKeys = [:]
        } else if let theme = loadedTheme {
            keys = theme.keysPreview
            rawKeys = theme.rawKeyData
        } else {
            return
        }

        guard !keys.isEmpty else {
            errorMessage = "No key images loaded."
            return
        }

        passthmFlashPhase    = .running
        passthmFlashProgress = 0
        passthmFlashLog.removeAll()
        errorMessage = nil

        if !vpnUp {
            passthmFlashLog.append("⚠️ Notice: Loopback VPN not detected, attempting direct loopback (127.0.0.1)...")
        }

        let pairingPath = PairingController.pairingFilePath()
        let targetVer = targetTelephonyVersion
        let targetLang = passcodeLanguageTarget
        let targetBold = passcodeBoldTarget
        let detected = AppViewModel.detectedDeviceLanguage.code

        Task.detached { [weak self] in
            guard let self = self else { return }

            let stageThemeDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("airlift_passthm_\(UUID().uuidString)")
            try? FileManager.default.createDirectory(at: stageThemeDir, withIntermediateDirectories: true)

            let langs: [String]
            if targetLang == .all {
                langs = KeypadLocales.all
            } else {
                var l = [targetLang.code]
                if targetLang.code != "other" {
                    l.append("other")
                }
                if targetLang.code != detected && detected != "other" && !l.contains(detected) {
                    l.append(detected)
                }
                langs = l
            }
            let boldSuffixes: [String]
            switch targetBold {
            case .both: boldSuffixes = ["", "-bold"]
            case .boldOnly: boldSuffixes = ["-bold"]
            case .regularOnly: boldSuffixes = [""]
            }

            for (digit, image) in keys {
                let imgData: Data
                if let raw = rawKeys[digit] {
                    imgData = raw
                } else if let png = image.pngData() {
                    imgData = png
                } else {
                    continue
                }
                let stdSubtext = KeypadLayout.subtexts[digit] ?? ""

                for lang in langs {
                    for bld in boldSuffixes {
                        if digit == "0" {

                            try? imgData.write(to: stageThemeDir.appendingPathComponent("\(lang)-0---white\(bld).png"))

                            try? imgData.write(to: stageThemeDir.appendingPathComponent("\(lang)-0-+--white\(bld).png"))
                        } else if digit == "1" {

                            try? imgData.write(to: stageThemeDir.appendingPathComponent("\(lang)-1---white\(bld).png"))
                        } else {

                            try? imgData.write(to: stageThemeDir.appendingPathComponent("\(lang)-\(digit)---white\(bld).png"))

                            if !stdSubtext.isEmpty {
                                try? imgData.write(to: stageThemeDir.appendingPathComponent("\(lang)-\(digit)-\(stdSubtext)--white\(bld).png"))
                                let noSpace = stdSubtext.replacingOccurrences(of: " ", with: "")
                                if noSpace != stdSubtext {
                                    try? imgData.write(to: stageThemeDir.appendingPathComponent("\(lang)-\(digit)-\(noSpace)--white\(bld).png"))
                                }
                            }

                            if (lang == "ru" || targetLang == .all), let ruSub = KeypadLocales.cyrillicRU[digit] {
                                try? imgData.write(to: stageThemeDir.appendingPathComponent("\(lang)-\(digit)-\(ruSub)--white\(bld).png"))
                            }
                            if (lang == "uk" || targetLang == .all), let ukSub = KeypadLocales.cyrillicUK[digit] {
                                try? imgData.write(to: stageThemeDir.appendingPathComponent("\(lang)-\(digit)-\(ukSub)--white\(bld).png"))
                            }
                        }
                    }
                }
            }

            try? Data().write(to: stageThemeDir.appendingPathComponent("_big"))

            await MainActor.run {
                self.passthmFlashLog.append("⚡ Staged theme assets (\(targetVer) · \(langs.joined(separator: ", ").uppercased()) · \(targetBold.code)). Injecting into iOS caches…")
                self.passthmFlashProgress = 0.2
            }

            let targetDirs: [String]
            if targetVer == "all" {
                targetDirs = [
                    "/var/mobile/Library/Caches/TelephonyUI-10",
                    "/var/mobile/Library/Caches/TelephonyUI-9",
                    "/var/mobile/Library/Caches/TelephonyUI-8"
                ]
            } else {
                targetDirs = [
                    "/var/mobile/Library/Caches/\(targetVer)"
                ]
            }

            var allOk = true
            var lastErr: String? = nil

            for (idx, targetPath) in targetDirs.enumerated() {
                let targetName = (targetPath as NSString).lastPathComponent
                await MainActor.run {
                    self.passthmFlashLog.append("  Writing to \(targetName)…")
                }

                var stepOk = false
                await withCheckedContinuation { cont in
                    DispatchQueue.global(qos: .userInitiated).async {
                        var outError: UnsafeMutablePointer<CChar>? = nil
                        let rc = pairingPath.withCString { pairC in
                            stageThemeDir.path.withCString { srcC in
                                targetPath.withCString { tgtC in
                                    al_exploit_write_dir(pairC, srcC, tgtC, { _, msg in
                                        guard let msg = msg else { return }
                                        let line = String(cString: msg)
                                        DispatchQueue.main.async { AppViewModel.shared?.passthmFlashLog.append("    " + line) }
                                    }, nil, &outError)
                                }
                            }
                        }
                        if let p = outError {
                            lastErr = String(validatingUTF8: p)
                            al_string_free(p)
                        }
                        stepOk = (rc == 0)
                        cont.resume()
                    }
                }

                if !stepOk {
                    allOk = false
                    await MainActor.run {
                        self.passthmFlashLog.append("  ⚠️ Write to \(targetName) failed: \(lastErr ?? "error")")
                    }
                } else {
                    await MainActor.run {
                        self.passthmFlashLog.append("  ✅ Injected into \(targetName)")
                    }
                }

                await MainActor.run {
                    self.passthmFlashProgress = 0.2 + Double(idx + 1) * 0.25
                }
            }

            try? FileManager.default.removeItem(at: stageThemeDir)

            await MainActor.run {
                if allOk {
                    self.passthmFlashProgress = 1.0
                    self.passthmFlashPhase = .done(ok: true)
                    self.passthmFlashLog.append("🎉 Passcode theme applied! Lock your iPhone to see it.")
                    self.successAlertMessage = "Passcode theme successfully applied!\n\nLock your iPhone (or restart) to see your new passcode keypad."
                    self.showSuccessAlert = true
                } else {
                    self.passthmFlashPhase = .done(ok: false)
                    self.passthmFlashLog.append("❌ One or more theme injections failed.")
                }
            }
        }
    }

    func exportPassthm() -> URL? {
        let keys = effectiveKeys
        guard !keys.isEmpty else {
            errorMessage = "Please configure at least one key before exporting."
            return nil
        }
        do {
            let zipData = try PasscodeThemePackager.buildPassthm(
                keys: keys,
                telephonyVersion: targetTelephonyVersion,
                language: passcodeLanguageTarget,
                bold: passcodeBoldTarget
            )
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("PosterLab_Custom_\(Int(Date().timeIntervalSince1970)).passthm")
            try zipData.write(to: tempURL)
            self.exportedThemeURL = tempURL
            self.showShareSheet = true
            return tempURL
        } catch {
            errorMessage = "Failed to export theme: \(error.localizedDescription)"
            return nil
        }
    }

    func resetPosterPosition() {
        posterZoom = 1.0
        posterOffset = .zero
        posterFillMode = .fill
        updatePosterSlicing()
    }

    func adoptThemeIntoCreator() {
        guard let theme = loadedTheme else { return }
        for (digit, img) in theme.keysPreview {
            customKeys[digit] = img
            rawIndividualImages[digit] = img
            individualOffsets[digit] = .zero
            individualZooms[digit] = 1.0
        }
        selectedKeyDigit = nil
        sliceMode = .individualKeys
        passcodeMode = .themeCreator
    }

    func appendLog(_ line: String) {
        log.append(line)
    }

    func loadSavedTendies() {
        if let data = UserDefaults.standard.data(forKey: "posterlab.saved_tendies"),
           let items = try? JSONDecoder().decode([TendieItem].self, from: data) {
            self.tendieItems = items.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
        }
    }

    func saveTendieItems() {
        if let data = try? JSONEncoder().encode(tendieItems) {
            UserDefaults.standard.set(data, forKey: "posterlab.saved_tendies")
        }
    }

    func loadSavedPasscodeThemes() {
        if let data = UserDefaults.standard.data(forKey: "posterlab.saved_passcode_themes"),
           let items = try? JSONDecoder().decode([SavedPasscodeTheme].self, from: data) {
            self.savedPasscodeThemes = items
                .filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
                .sorted { $0.dateCreated > $1.dateCreated }
        }
    }

    func persistSavedPasscodeThemes() {
        if let data = try? JSONEncoder().encode(savedPasscodeThemes) {
            UserDefaults.standard.set(data, forKey: "posterlab.saved_passcode_themes")
        }
    }

    @discardableResult
    func savePasscodeThemeToLibrary(name: String) -> SavedPasscodeTheme? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "Theme \(savedPasscodeThemes.count + 1)" : trimmed
        let keys = effectiveKeys
        guard !keys.isEmpty else {
            errorMessage = "Add at least one key image before saving to the library."
            return nil
        }
        do {
            let data = try PasscodeThemePackager.buildPassthm(
                keys: keys,
                telephonyVersion: targetTelephonyVersion,
                language: passcodeLanguageTarget,
                bold: passcodeBoldTarget
            )
            let id = UUID()
            let fileName = "\(id.uuidString).passthm"
            let url = SavedPasscodeTheme.storageDirectory.appendingPathComponent(fileName)
            try data.write(to: url)

            let preview = renderPasscodePreview(keys: keys)
            let b64 = preview.flatMap { $0.pngData()?.base64EncodedString() }

            let item = SavedPasscodeTheme(
                id: id,
                name: finalName,
                fileName: fileName,
                dateCreated: Date(),
                language: passcodeLanguageTarget.code,
                bold: String(describing: passcodeBoldTarget),
                keyDigits: Array(keys.keys).sorted(),
                previewPNGBase64: b64
            )
            savedPasscodeThemes.insert(item, at: 0)
            persistSavedPasscodeThemes()
            return item
        } catch {
            errorMessage = "Failed to save theme: \(error.localizedDescription)"
            return nil
        }
    }

    func deleteSavedPasscodeTheme(_ item: SavedPasscodeTheme) {
        try? FileManager.default.removeItem(at: item.fileURL)
        savedPasscodeThemes.removeAll { $0.id == item.id }
        persistSavedPasscodeThemes()
    }

    func renameSavedPasscodeTheme(_ item: SavedPasscodeTheme, to newName: String) {
        guard let idx = savedPasscodeThemes.firstIndex(where: { $0.id == item.id }) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { savedPasscodeThemes[idx].name = trimmed }
        persistSavedPasscodeThemes()
    }

    func loadSavedPasscodeThemeIntoCreator(_ item: SavedPasscodeTheme) {
        loadPassthm(url: item.fileURL)
        adoptThemeIntoCreator()
    }

    func exportSavedPasscodeTheme(_ item: SavedPasscodeTheme) {
        self.exportedThemeURL = item.fileURL
        self.showShareSheet = true
    }

    private func renderPasscodePreview(keys: [String: UIImage], tile: CGFloat = 56, gap: CGFloat = 4) -> UIImage? {
        let cols = 3, rows = 4
        let size = CGSize(width: CGFloat(cols) * tile + CGFloat(cols - 1) * gap,
                          height: CGFloat(rows) * tile + CGFloat(rows - 1) * gap)
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 2; fmt.opaque = false
        return UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            let digitOrder = ["1","2","3","4","5","6","7","8","9","","0",""]
            for (idx, digit) in digitOrder.enumerated() {
                let col = idx % cols, row = idx / cols
                let x = CGFloat(col) * (tile + gap)
                let y = CGFloat(row) * (tile + gap)
                let rect = CGRect(x: x, y: y, width: tile, height: tile)
                let path = UIBezierPath(ovalIn: rect)
                UIColor.white.withAlphaComponent(0.08).setFill()
                path.fill()
                if digit.isEmpty { continue }
                if let img = keys[digit] {
                    path.addClip()
                    img.draw(in: rect)
                }
            }
        }
    }

    func importTendieFiles(urls: [URL]) async {
        guard !urls.isEmpty else { return }
        var importedCount = 0
        var lastImportedName = ""
        for url in urls {
            do {
                let item = try await TendiesEngine.shared.importTendie(from: url)
                await MainActor.run {
                    self.tendieItems.removeAll(where: { $0.fileName == item.fileName })
                    self.tendieItems.append(item)
                    self.saveTendieItems()
                    importedCount += 1
                    lastImportedName = item.name
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to import \(url.lastPathComponent): \(error.localizedDescription)"
                }
            }
        }
    }

    func deleteTendie(item: TendieItem) {
        try? FileManager.default.removeItem(at: item.fileURL)
        tendieItems.removeAll(where: { $0.id == item.id })
        saveTendieItems()
    }

    func autoDetectPosterBoardContainer(silent: Bool = false) async {
        let pairingPath = PairingController.pairingFilePath()
        guard FileManager.default.fileExists(atPath: pairingPath) else {
            if !silent {
                await MainActor.run {
                    self.errorMessage = "No pairing file active. Pair your device first in the Pairing tab."
                }
            }
            return
        }

        await MainActor.run { self.isDetectingContainer = true }
        defer {
            Task { @MainActor in self.isDetectingContainer = false }
        }

        do {
            let container = try await TendiesEngine.shared.detectPosterBoardContainer(pairingPath: pairingPath)
            await MainActor.run {
                self.posterBoardContainer = container
                UserDefaults.standard.set(container, forKey: "posterlab.posterboard_container")
            }
        } catch {
            if !silent {
                await MainActor.run {
                    self.errorMessage = "Auto-detect failed: \(error.localizedDescription)\nEnsure LocalDevVPN is connected and device is unlocked."
                }
            }
        }
    }

    func flashSelectedTendies() async {
        let selected = tendieItems.filter { $0.isSelected }
        guard !selected.isEmpty else {
            errorMessage = "No wallpapers selected to flash."
            return
        }

        let pairingPath = PairingController.pairingFilePath()
        guard FileManager.default.fileExists(atPath: pairingPath) else {
            errorMessage = "No pairing file active. Please pair your device first."
            return
        }

        var container = posterBoardContainer.trimmingCharacters(in: .whitespacesAndNewlines)
        if container.isEmpty {
            do {
                container = try await TendiesEngine.shared.detectPosterBoardContainer(pairingPath: pairingPath)
                self.posterBoardContainer = container
                UserDefaults.standard.set(container, forKey: "posterlab.posterboard_container")
            } catch {
                errorMessage = "PosterBoard container could not be found automatically. Ensure LocalDevVPN is connected and iPhone is unlocked."
                return
            }
        }

        tendiesFlashPhase = .running
        tendiesFlashProgress = 0
        tendiesFlashLog = []

        do {
            try await TendiesEngine.shared.flashTendies(
                items: selected,
                containerPath: container,
                resetProtections: resetPBProtections,
                pairingPath: pairingPath,
                log: { [weak self] line in
                    DispatchQueue.main.async {
                        self?.tendiesFlashLog.append(line)
                    }
                },
                progress: { [weak self] p in
                    DispatchQueue.main.async {
                        self?.tendiesFlashProgress = p
                    }
                }
            )
            tendiesFlashPhase = .done(ok: true)
            tendiesFlashProgress = 1.0
            tendiesFlashLog.append("🎉 Wallpapers applied successfully!")
            tendiesFlashLog.append("⚡ Triggering NeoSpring respring...")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.isNeoSpringing = true
                RespringHelper.triggerNeoSpring()
            }
        } catch {
            tendiesFlashLog.append("❌ Error: \(error.localizedDescription)")
            tendiesFlashPhase = .done(ok: false)
        }
    }

    func respringDevice() {
        tendiesFlashLog.append("⚡ Triggering NeoSpring respring...")
        isNeoSpringing = true
        RespringHelper.triggerNeoSpring()
    }

    func reset() {
        cardFlashPhase = .idle
        cardFlashProgress = 0
        passthmFlashPhase = .idle
        passthmFlashProgress = 0
        tendiesFlashPhase = .idle
        tendiesFlashProgress = 0
        errorMessage = nil
    }
}
