import Foundation

enum WidgetPriceLoader {
    private static let appGroupIdentifier = "group.tauts.ElekterEestis"
    private static let pricesKey = "electricityPrices"

    /// Loads prices for home screen widgets: 3h before now, up to 10h onwards.
    /// If less than 10h of future data is available, returns whatever exists.
    static func loadNextHoursPrices(hoursBefore: Int = 3, hoursAfter: Int = 10, pointsPerHour: Int = 4) -> [ElectricityPrice] {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: pricesKey),
              let all = try? JSONDecoder().decode([ElectricityPrice].self, from: data) else {
            return []
        }

        let now = Date()
        let startDate = now.addingTimeInterval(TimeInterval(-hoursBefore) * 60 * 60)
        let endDate = now.addingTimeInterval(TimeInterval(hoursAfter) * 60 * 60)
        let maxCount = (hoursBefore + hoursAfter) * pointsPerHour

        return all
            .filter { price in
                guard let dt = price.dateTime else { return false }
                return dt >= startDate && dt <= endDate
            }
            .sorted { ($0.dateTime ?? .distantFuture) < ($1.dateTime ?? .distantFuture) }
            .prefix(maxCount)
            .map { $0 }
    }
}
