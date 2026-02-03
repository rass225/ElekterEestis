import SwiftUI
import Combine

/// Observable store for price display style preference (app group, shared with widgets).
final class PriceDisplayPreference: ObservableObject {
    static let shared = PriceDisplayPreference()

    private static let appGroupIdentifier = SharedConstants.appGroupIdentifier
    private static let preferenceKey = SharedConstants.appDisplayStyleKey

    @Published var displayStyle: PriceDisplayStyle {
        didSet {
            UserDefaults(suiteName: Self.appGroupIdentifier)?
                .set(displayStyle.rawValue, forKey: Self.preferenceKey)
        }
    }

    private init() {
        let defaults = UserDefaults(suiteName: Self.appGroupIdentifier)
        if let raw = defaults?.string(forKey: Self.preferenceKey),
           let style = PriceDisplayStyle(rawValue: raw) {
            displayStyle = style
        } else {
            displayStyle = .euroPerKwh
        }
    }
}
