import Foundation

extension String {

    var loc: String { String(localized: String.LocalizationValue(self)) }
}
