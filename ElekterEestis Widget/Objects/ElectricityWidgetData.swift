import Foundation

// MARK: - Hub types

/// One point per hour (average of 15-min prices in that hour) for charts and lists.
struct HourlyPricePoint: Identifiable {
    let id: Date
    let price: Double
}

enum PriceDisplayStyle {
    case euroPerKwh   // "%.2f €/kWh"
    case centsPerKwh  // "%.0f cents/kWh"
}

// MARK: - Centralized widget data hub

/// Single source of truth for all derived electricity widget data.
/// Build once per timeline entry; views read from here only.
struct ElectricityWidgetData {
    /// First 15-min price at or after reference date (e.g. for small widget).
    let currentPrice: ElectricityPrice?

    /// Full hourly series for the chart (includes past hours).
    let hourlyPrices: [HourlyPricePoint]

    /// Hourly point for the current hour (for "Hetkel" / now).
    let currentHourlyPoint: HourlyPricePoint?

    /// Start of current hour in Tallinn (used for filtering).
    private let startOfCurrentHour: Date

    /// Number of price slots after current (for "+N more").
    let upcomingSlotCount: Int

    /// Raw 15-min prices (for charts with all data points).
    let prices: [ElectricityPrice]

    private let referenceDate: Date

    init(prices: [ElectricityPrice], referenceDate: Date = Date()) {
        self.prices = prices
        self.referenceDate = referenceDate
        let calendar = Self.tallinnCalendar
        let startOfCurrent = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: referenceDate)) ?? referenceDate

        // Current 15-min price: first at or after reference
        self.currentPrice = prices.first { price in
            guard let dt = price.dateTime else { return false }
            return dt >= referenceDate
        }

        // Hourly aggregation (all hours in range)
        var groups: [Date: [Double]] = [:]
        for p in prices {
            guard let dt = p.dateTime else { continue }
            let hourStart = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: dt)) ?? dt
            groups[hourStart, default: []].append(p.price)
        }
        let sortedHourly = groups.map { HourlyPricePoint(id: $0.key, price: $0.value.reduce(0, +) / Double($0.value.count)) }
            .sorted { $0.id < $1.id }

        self.hourlyPrices = sortedHourly
        self.currentHourlyPoint = sortedHourly.first { $0.id == startOfCurrent }
            ?? sortedHourly.min(by: { abs($0.id.timeIntervalSince(referenceDate)) < abs($1.id.timeIntervalSince(referenceDate)) })
        self.startOfCurrentHour = startOfCurrent
        self.upcomingSlotCount = prices.filter { price in
            guard let dt = price.dateTime else { return false }
            return dt > referenceDate
        }.count
    }

    /// Hourly points from current hour onwards, capped at maxHours (for lock screen / rectangular).
    func hourlyFromNow(maxHours: Int) -> [HourlyPricePoint] {
        hourlyPrices
            .filter { $0.id >= startOfCurrentHour }
            .prefix(maxHours)
            .map { $0 }
    }

    /// Hourly points around now: hoursBefore + current + hoursAfter (e.g. 1 + 1 + 4 = 6 for rectangular chart).
    func hourlyAroundNow(hoursBefore: Int = 1, hoursAfter: Int = 4) -> [HourlyPricePoint] {
        let calendar = Self.tallinnCalendar
        let startHour = calendar.date(byAdding: .hour, value: -hoursBefore, to: startOfCurrentHour) ?? startOfCurrentHour
        let endHour = calendar.date(byAdding: .hour, value: hoursAfter, to: startOfCurrentHour) ?? startOfCurrentHour
        return hourlyPrices
            .filter { $0.id >= startHour && $0.id <= endHour }
            .prefix(hoursBefore + 1 + hoursAfter)
            .map { $0 }
    }
    
    /// All 15-min data points for charts. x = minutes from chart start. hourLabels derived from actual points at hour boundaries.
    func chartPointsWithAllData(hoursBefore: Int = 3, hoursAfter: Int = 10) -> ChartPointsResult {
        let calendar = Self.tallinnCalendar
        let startHour = calendar.date(byAdding: .hour, value: -hoursBefore, to: startOfCurrentHour)!
        let endHour = calendar.date(byAdding: .hour, value: hoursAfter, to: startOfCurrentHour)!

        let inRange = prices
            .compactMap { p -> (date: Date, price: Double)? in
                guard let dt = p.dateTime else { return nil }
                return dt >= startHour && dt <= endHour ? (dt, p.price) : nil
            }
            .sorted { $0.date < $1.date }

        let points = inRange.enumerated().map { index, item in
            let minutesFromStart = item.date.timeIntervalSince(startHour) / 60.0
            return ChartPointWithMinutes(id: "\(index)", xMinutes: minutesFromStart, date: item.date, price: item.price)
        }

        let currentPoint = points.min(by: { abs($0.date.timeIntervalSince(referenceDate)) < abs($1.date.timeIntervalSince(referenceDate)) })

        // Hour labels from actual points at hour boundaries (XX:00 only)
        let hourLabels: [(x: Double, label: String)] = points
            .filter { calendar.component(.minute, from: $0.date) == 0 }
            .map { (x: $0.xMinutes, label: Self.formatTimeShort($0.date)) }

        return ChartPointsResult(points: points, currentPoint: currentPoint, startHour: startHour, hourLabels: hourLabels)
    }

    /// Shorter range for lock screen rectangular.
    func chartPointsAroundNow(hoursBefore: Int = 1, hoursAfter: Int = 8) -> ChartPointsResult {
        chartPointsWithAllData(hoursBefore: hoursBefore, hoursAfter: hoursAfter)
    }

    // MARK: - Formatting (single place, fixes HH:MM → HH:mm)

    private static let tallinnTimeZone = TimeZone(identifier: "Europe/Tallinn")!

    private static var tallinnCalendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = tallinnTimeZone
        return cal
    }

    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = tallinnTimeZone
        return formatter.string(from: date)
    }
    
    static func formatTimeShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        formatter.timeZone = tallinnTimeZone
        return formatter.string(from: date)
    }

    static func formatPrice(_ price: Double, style: PriceDisplayStyle) -> String {
        switch style {
        case .euroPerKwh:
            return String(format: "%.2f €/kWh", price / 100.0)
        case .centsPerKwh:
            return String(format: "%.0f s/kWh", price)
        }
    }

    /// Value part only (e.g. "0.21" or "21").
    static func formatPriceValue(_ price: Double, style: PriceDisplayStyle) -> String {
        switch style {
        case .euroPerKwh: return String(format: "%.2f", price / 100.0)
        case .centsPerKwh: return String(format: "%.0f", price)
        }
    }

    /// Unit/type part only (e.g. "€/kWh" or "s/kWh").
    static func formatPriceUnit(_ style: PriceDisplayStyle) -> String {
        style == .euroPerKwh ? "€/kWh" : "s/kWh"
    }

    // MARK: - Preferences
    
    private static let appGroupIdentifier = "group.tauts.ElekterEestis"
    private static let preferenceKeyPrefix = "widgetPriceDisplayStyle_"
    
    /// Get the price display style preference for a widget family
    static func getDisplayStyle(for widgetFamily: String, defaultStyle: PriceDisplayStyle = .euroPerKwh) -> PriceDisplayStyle {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let rawValue = defaults.string(forKey: preferenceKeyPrefix + widgetFamily),
              let style = PriceDisplayStyle(rawValue: rawValue) else {
            return defaultStyle
        }
        return style
    }
    
    /// Set the price display style preference for a widget family
    static func setDisplayStyle(_ style: PriceDisplayStyle, for widgetFamily: String) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        defaults.set(style.rawValue, forKey: preferenceKeyPrefix + widgetFamily)
    }
}

extension PriceDisplayStyle {
    var rawValue: String {
        switch self {
        case .euroPerKwh: return "euroPerKwh"
        case .centsPerKwh: return "centiPerKwh"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "euroPerKwh": self = .euroPerKwh
        case "centiPerKwh": self = .centsPerKwh
        default: return nil
        }
    }
}

struct ChartHourPoint: Identifiable {
    let id: Int
    let date: Date
    let price: Double
}

/// One 15-min price point for charts. xMinutes = position on x-axis (minutes from chart start).
struct ChartPointWithMinutes: Identifiable {
    let id: String
    let xMinutes: Double
    let date: Date
    let price: Double
}

/// Chart data with all 15-min points and hourly axis labels.
struct ChartPointsResult {
    let points: [ChartPointWithMinutes]
    let currentPoint: ChartPointWithMinutes?
    let startHour: Date
    let hourLabels: [(x: Double, label: String)]
}
