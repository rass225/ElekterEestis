import XCTest
@testable import ElekterEestis

final class ElectricityPriceTests: XCTestCase {
    func testDateParsingInTallinnTimezone() {
        let price = ElectricityPrice(date: "2026-02-03 15:00", price: 42.0)
        guard let dt = price.dateTime else {
            XCTFail("Expected valid date")
            return
        }
        let calendar = Calendar(identifier: .gregorian)
        let tz = TimeZone(identifier: SharedConstants.tallinnTimeZoneId)!
        var cal = calendar
        cal.timeZone = tz
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: dt)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 2)
        XCTAssertEqual(comps.day, 3)
        XCTAssertEqual(comps.hour, 15)
        XCTAssertEqual(comps.minute, 0)
    }

    func testFormattedTimeUsesHHmm() {
        let price = ElectricityPrice(date: "2026-02-03 07:05", price: 10.0)
        XCTAssertEqual(price.formattedTime, "07:05")
    }
}
