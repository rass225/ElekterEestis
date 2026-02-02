import Foundation
import BackgroundTasks

enum Scheduler {
    static let id = "tauts.ElekterEestis.refresh"

    static func scheduleDailyRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: id)

        let request = BGAppRefreshTaskRequest(identifier: id)

        let now = Date()
        if isAfter15(now: now), SharedFetchFlag.fetchedToday(now: now) == false {
            // "Catch-up mode" until today’s fetch succeeds
            request.earliestBeginDate = now.addingTimeInterval(30 * 60) // 30 min
        } else {
            request.earliestBeginDate = nextDailyRefreshDate(now: now)
        }

        do {
            try BGTaskScheduler.shared.submit(request)
            if let d = request.earliestBeginDate { print("Scheduled refresh for \(d)") }
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    private static func isAfter15(now: Date) -> Bool {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Europe/Tallinn") ?? .current
        let comps = cal.dateComponents([.hour], from: now)
        return (comps.hour ?? 0) >= 15
    }

    static func nextDailyRefreshDate(now: Date = Date()) -> Date {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Europe/Tallinn") ?? .current

        let today1502 = cal.date(bySettingHour: 15, minute: 2, second: 0, of: now)!

        if now < today1502 {
            return today1502
        } else {
            return cal.date(byAdding: .day, value: 1, to: today1502)!
        }
    }
}
