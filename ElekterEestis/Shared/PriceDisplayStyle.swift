import Foundation

enum PriceDisplayStyle: String, CaseIterable {
    case euroPerKwh = "euroPerKwh"
    case centsPerKwh = "centsPerKwh"

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

    func formatPriceValue(_ price: Double) -> String {
        switch self {
        case .euroPerKwh: return String(format: "%.2f", price / 100.0)
        case .centsPerKwh: return String(format: "%.0f", price)
        }
    }

    var formatPriceUnit: String {
        label
    }
}

extension PriceDisplayStyle {
    init?(rawValue: String) {
        switch rawValue {
        case "euroPerKwh": self = .euroPerKwh
        case "centsPerKwh": self = .centsPerKwh
        case "centiPerKwh": self = .centsPerKwh // legacy widget value
        default: return nil
        }
    }
}
