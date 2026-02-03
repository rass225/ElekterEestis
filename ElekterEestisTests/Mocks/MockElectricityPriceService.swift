import Foundation
@testable import ElekterEestis

final class MockElectricityPriceService: ElectricityPriceServing {
    var prices: [ElectricityPrice] = []
    var error: Error?

    func fetchPrices() async throws -> [ElectricityPrice] {
        if let error {
            throw error
        }
        return prices
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
                .prefix(12)
        )
    }
}
