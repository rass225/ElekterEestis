import SwiftUI
import Combine

/// Price display style: euros (€/kWh) or cents (s/kWh).
/// Matches widget configuration; prices from API are in cents.
enum PriceDisplayStyle: String, CaseIterable {
    case euroPerKwh
    case centsPerKwh

    var label: String {
        switch self {
        case .euroPerKwh: return "€/kWh"
        case .centsPerKwh: return "s/kWh"
        }
    }

    func formatPrice(_ price: Double) -> String {
        switch self {
        case .euroPerKwh: return String(format: "%.2f €/kWh", price / 100.0)
        case .centsPerKwh: return String(format: "%.0f s/kWh", price)
        }
    }

    func chartValue(_ price: Double) -> Double {
        switch self {
        case .euroPerKwh: return price / 100.0
        case .centsPerKwh: return price
        }
    }
}

/// Observable store for price display style preference (app group, shared with widgets).
final class PriceDisplayPreference: ObservableObject {
    static let shared = PriceDisplayPreference()

    private static let appGroupIdentifier = "group.tauts.ElekterEestis"
    private static let preferenceKey = "widgetPriceDisplayStyle_app"

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
