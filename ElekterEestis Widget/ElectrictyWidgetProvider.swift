import Foundation
import WidgetKit

struct ElectricityWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ElectricityWidgetEntry {
        let data = ElectricityWidgetData(prices: [], referenceDate: Date())
        return ElectricityWidgetEntry(date: Date(), data: data)
    }

    func getSnapshot(in context: Context, completion: @escaping (ElectricityWidgetEntry) -> Void) {
        let prices = WidgetPriceLoader.loadNextHoursPrices()
        let data = ElectricityWidgetData(prices: prices, referenceDate: Date())
        completion(ElectricityWidgetEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ElectricityWidgetEntry>) -> Void) {
        let prices = WidgetPriceLoader.loadNextHoursPrices()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Europe/Tallinn")!
        let now = Date()
        // Round down to nearest 15 min so "current" marker stays accurate when widget is displayed
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let minute = (comps.minute ?? 0) / 15 * 15
        let anchor = calendar.date(from: DateComponents(year: comps.year, month: comps.month, day: comps.day, hour: comps.hour, minute: minute)) ?? now
        var entries: [ElectricityWidgetEntry] = []
        for offset in 0..<8 {
            guard let slot = calendar.date(byAdding: .minute, value: offset * 15, to: anchor) else { break }
            let data = ElectricityWidgetData(prices: prices, referenceDate: slot)
            entries.append(ElectricityWidgetEntry(date: slot, data: data))
        }
        let nextUpdate = calendar.date(byAdding: .minute, value: 15, to: now) ?? now
        completion(Timeline(entries: entries, policy: .after(nextUpdate)))
    }
}
