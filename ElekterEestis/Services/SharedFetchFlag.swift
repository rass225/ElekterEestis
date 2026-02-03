import Foundation

enum SharedFetchFlag {
    private static let suite = UserDefaults(suiteName: SharedConstants.appGroupIdentifier)!
    private static let key = SharedConstants.lastSuccessfulFetchKey
    private static let statusKey = SharedConstants.lastRefreshStatusKey
    private static let errorKey = SharedConstants.lastRefreshErrorKey

    static func fetchedToday(now: Date = Date()) -> Bool {
        guard let last = suite.object(forKey: key) as? Date else { return false }
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: SharedConstants.tallinnTimeZoneId) ?? .current
        return cal.isDate(last, inSameDayAs: now)
    }

    static var lastFetchDate: Date? {
        suite.object(forKey: key) as? Date
    }

    static func markFetchedNow() {
        suite.set(Date(), forKey: key)
    }

    static func markRefreshStatus(success: Bool, errorDescription: String? = nil) {
        suite.set(success ? "success" : "failure", forKey: statusKey)
        if let errorDescription {
            suite.set(errorDescription, forKey: errorKey)
        } else {
            suite.removeObject(forKey: errorKey)
        }
    }
}
