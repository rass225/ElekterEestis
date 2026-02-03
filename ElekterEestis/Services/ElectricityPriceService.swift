import Foundation

protocol ElectricityPriceServing {
    func fetchPrices() async throws -> [ElectricityPrice]
    func getNextThreeHoursPrices(from prices: [ElectricityPrice]) -> [ElectricityPrice]
}

final class ElectricityPriceService: ElectricityPriceServing {
    static let shared = ElectricityPriceService()

    private let apiURL = "https://elektrihind.ee/api/stock_price_daily.php"
    private let maxAttempts = 3
    private let initialBackoffSeconds: Double = 0.5

    private init() {}

    func fetchPrices() async throws -> [ElectricityPrice] {
        guard let url = URL(string: apiURL) else {
            throw URLError(.badURL)
        }

        let data = try await fetchDataWithRetry(from: url)
        let prices = try JSONDecoder().decode([ElectricityPrice].self, from: data)

        // Sort by date to ensure chronological order
        let valid = prices.compactMap { price -> ElectricityPrice? in
            price.dateTime == nil ? nil : price
        }

        if valid.isEmpty {
            throw ServiceError.noValidDates
        }

        return valid.sorted { price1, price2 in
            (price1.dateTime ?? .distantFuture) < (price2.dateTime ?? .distantFuture)
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

// MARK: - Networking helpers

private extension ElectricityPriceService {
    enum ServiceError: Error {
        case badStatus(code: Int)
        case noValidDates
    }

    func fetchDataWithRetry(from url: URL) async throws -> Data {
        var attempt = 0
        var backoff = initialBackoffSeconds

        while true {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse {
                    let code = http.statusCode
                    if (200...299).contains(code) == false {
                        if isRetriableStatus(code), attempt < maxAttempts - 1 {
                            try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                            attempt += 1
                            backoff *= 2
                            continue
                        }
                        throw ServiceError.badStatus(code: code)
                    }
                }
                return data
            } catch {
                if isRetriableError(error), attempt < maxAttempts - 1 {
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    attempt += 1
                    backoff *= 2
                    continue
                }
                throw error
            }
        }
    }

    func isRetriableStatus(_ code: Int) -> Bool {
        return code == 429 || (500...599).contains(code)
    }

    func isRetriableError(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut,
             .networkConnectionLost,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}
