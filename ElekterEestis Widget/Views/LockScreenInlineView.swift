import SwiftUI

struct LockScreenInlineView: View {
    let entry: ElectricityWidgetEntry
    
    private var displayStyle: PriceDisplayStyle {
        ElectricityWidgetData.getDisplayStyle(for: "accessoryInline", defaultStyle: .euroPerKwh)
    }

    var body: some View {
        if let first = entry.data.hourlyFromNow(maxHours: 1).first {
            Text("\(ElectricityWidgetData.formatTime(first.id)) \(displayStyle.formatPrice(first.price))")
        } else {
            Text("Hindu pole")
        }
    }
}
