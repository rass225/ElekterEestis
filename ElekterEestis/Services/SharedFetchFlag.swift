import Foundation

enum SharedFetchFlag {
    private static let suite = UserDefaults(suiteName: "group.tauts.ElekterEestis")!
    private static let key = "lastSuccessfulFetch"

    static func fetchedToday(now: Date = Date()) -> Bool {
        guard let last = suite.object(forKey: key) as? Date else { return false }
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Europe/Tallinn") ?? .current
        return cal.isDate(last, inSameDayAs: now)
    }

    static func markFetchedNow() {
        suite.set(Date(), forKey: key)
    }
}
