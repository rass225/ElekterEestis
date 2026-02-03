import XCTest
@testable import ElekterEestis

final class ElectricityPriceServiceTests: XCTestCase {
    func testNextThreeHoursReturnsTwelveSlots() {
        let now = Date()
        let calendar = Calendar.current
        let base = calendar.date(byAdding: .minute, value: -30, to: now) ?? now
        let prices = (0..<32).map { index in
            let dt = calendar.date(byAdding: .minute, value: index * 15, to: base) ?? now
            let dateString = ElectricityPriceServiceTests.format(dt)
            return ElectricityPrice(date: dateString, price: Double(index))
        }

        let service = ElectricityPriceService.shared
        let next = service.getNextThreeHoursPrices(from: prices)

        XCTAssertEqual(next.count, 12)
        XCTAssertTrue(next.allSatisfy { $0.dateTime != nil })
    }

    private static func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: SharedConstants.tallinnTimeZoneId)
        return formatter.string(from: date)
    }
}
