import Foundation

final class ElectricityPriceService {
    static let shared = ElectricityPriceService()

    private let apiURL = "https://elektrihind.ee/api/stock_price_daily.php"

    private init() {}

    func fetchPrices() async throws -> [ElectricityPrice] {
        guard let url = URL(string: apiURL) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let prices = try JSONDecoder().decode([ElectricityPrice].self, from: data)

        // Sort by date to ensure chronological order
        return prices.sorted { price1, price2 in
            guard let date1 = price1.dateTime, let date2 = price2.dateTime else {
                return false
            }
            return date1 < date2
        }
    }

    func getNextThreeHoursPrices(from prices: [ElectricityPrice]) -> [ElectricityPrice] {
        let now = Date()
        let threeHoursFromNow = now.addingTimeInterval(3 * 60 * 60)

        return Array(
            prices
                .filter { price in
                    guard let dateTime = price.dateTime else { return false }
                    return dateTime >= now && dateTime <= threeHoursFromNow
                }
                .prefix(12) // 12 slots = 3 hours (15 min intervals)
        )
    }
}
