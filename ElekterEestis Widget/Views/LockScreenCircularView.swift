import SwiftUI
import WidgetKit

struct LockScreenCircularView: View {
    let entry: ElectricityWidgetEntry
    
    private var displayStyle: PriceDisplayStyle {
        ElectricityWidgetData.getDisplayStyle(for: "accessoryCircular", defaultStyle: .euroPerKwh)
    }

    var body: some View {
        if let point = entry.data.hourlyFromNow(maxHours: 1).first {
            VStack(spacing: 0) {
                if displayStyle == .euroPerKwh {
                    Text(String(format: "%.2f", point.price / 100.0))
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                    Text("€/kWh")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.red)
                } else {
                    Text(String(format: "%.0f", point.price))
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                    Text("s/kWh")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.green)
                }
            }
        } else {
            Text("—")
                .font(.caption)
        }
    }
}
