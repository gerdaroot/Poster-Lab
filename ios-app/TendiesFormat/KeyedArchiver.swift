import Foundation

final class KeyedArchive {
    private var objects: [Any] = ["$null"]

    @discardableResult
    func add(_ object: Any) -> [String: Int] {
        objects.append(object)
        return ["CF$UID": objects.count - 1]
    }

    var null: [String: Int] { ["CF$UID": 0] }

    func addClass(_ names: [String]) -> [String: Int] {
        add(["$classname": names[0], "$classes": names])
    }

    func data(root: [String: Int]) throws -> Data {
        let plist: [String: Any] = [
            "$version": 100000,
            "$archiver": "NSKeyedArchiver",
            "$top": ["root": root],
            "$objects": objects,
        ]
        return try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    }
}

enum PosterPlists {

    static func titleStyleConfiguration(_ clock: ClockStyle) throws -> Data {
        let a = KeyedArchive()
        let fontConfigClass = a.addClass([
            "PRPosterSystemTimeFontConfiguration",
            "PRPosterTimeFontConfiguration", "NSObject",
        ])
        let rootClass = a.addClass(["PRPosterTitleStyleConfiguration", "NSObject"])
        let fontId = a.add(clock.font.rawValue)
        let group = a.add("PREditingLook")

        let fontConfig = a.add([
            "$class": fontConfigClass,
            "timeFontIdentifier": fontId,
        ])

        let numbering: [String: Int] = clock.numbering == .arabic
            ? a.null : a.add(clock.numbering.rawValue)

        let luminance = clock.tintColor == nil ? 0 : 1

        let root = a.add([
            "$class": rootClass,
            "alternateDateEnabled": false,
            "contentsLuminence": luminance,
            "groupName": group,
            "timeFontConfiguration": fontConfig,
            "timeNumberingSystem": numbering,
            "titleColor": a.null,
            "userConfigured": clock.font == .soft ? false : true,
        ])
        return try a.data(root: root)
    }

    static func providerInfo(date: Date = Date()) throws -> Data {
        let a = KeyedArchive()
        let dateClass = a.addClass(["NSDate", "NSObject"])
        let dictClass = a.addClass(["NSMutableDictionary", "NSDictionary", "NSObject"])
        let key = a.add("kConfigurationLastUseDateKey")
        let dateObj = a.add([
            "$class": dateClass,
            "NS.time": date.timeIntervalSinceReferenceDate,
        ])
        let root = a.add([
            "$class": dictClass,
            "NS.keys": [key],
            "NS.objects": [dateObj],
        ])
        return try a.data(root: root)
    }

    static func otherMetadata(displayName: String) throws -> Data {
        let a = KeyedArchive()
        let cls = a.addClass(["PRPosterMetadata", "NSObject"])
        let nameKey = a.add(displayName)
        let root = a.add([
            "$class": cls,
            "displayNameLocalizationKey": nameKey,
        ])
        return try a.data(root: root)
    }

    static func emptyDictArchive() throws -> Data {
        let a = KeyedArchive()
        let dictClass = a.addClass(["NSDictionary", "NSObject"])
        let root = a.add([
            "$class": dictClass,
            "NS.keys": [] as [Any],
            "NS.objects": [] as [Any],
        ])
        return try a.data(root: root)
    }

    static func userInfo(wallpaperFileName: String, identifier: String) throws -> Data {
        let dict: [String: Any] = [
            "posterEnvironmentOverrides": Data("{}".utf8),
            "wallpaperRepresentingFileName": wallpaperFileName,
            "wallpaperRepresentingIdentifier": identifier,
        ]
        return try PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0)
    }
}
