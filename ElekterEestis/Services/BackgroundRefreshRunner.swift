import Foundation
import BackgroundTasks
import WidgetKit

enum BackgroundRefreshRunner {
    static func run(task: BGAppRefreshTask) async {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        do {
            let prices = try await ElectricityPriceService.shared.fetchPrices()
            await MainActor.run {
                PriceDataStore.shared.savePrices(prices)
            }

            SharedFetchFlag.markFetchedNow()

            task.setTaskCompleted(success: true)
        } catch {
            task.setTaskCompleted(success: false)
        }

        // Always re-schedule
        Scheduler.scheduleDailyRefresh()
    }
}
