import SwiftUI
import Charts

struct HomeScreenSmallView: View {
    @Environment(\.colorScheme) var appearance
    let entry: ElectricityWidgetEntry
    
    private var displayStyle: PriceDisplayStyle {
        ElectricityWidgetData.getDisplayStyle(for: "systemSmall", defaultStyle: .euroPerKwh)
    }
    
    private func chartPrice(_ price: Double) -> Double {
        displayStyle == .euroPerKwh ? price / 100.0 : price
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.caption)
                Text("Elekter Eestis")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let current = entry.data.currentPrice {
                Text(ElectricityWidgetData.formatPrice(current.price, style: displayStyle))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.bottom, 8)
                
                let result = entry.data.chartPointsWithAllData(hoursBefore: 3, hoursAfter: 10)
                if !result.points.isEmpty {
                    Chart {
                        ForEach(result.points) { point in
                            LineMark(
                                x: .value("Min", point.xMinutes),
                                y: .value(displayStyle == .euroPerKwh ? "€/kWh" : "s/kWh", chartPrice(point.price))
                            )
                            .foregroundStyle(.cyan)
                            .interpolationMethod(.catmullRom)
                            AreaMark(
                                x: .value("Min", point.xMinutes),
                                y: .value(displayStyle == .euroPerKwh ? "€/kWh" : "s/kWh", chartPrice(point.price))
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.5), .cyan.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }
                        if let nowPoint = result.currentPoint {
                            PointMark(
                                x: .value("Min", nowPoint.xMinutes),
                                y: .value(displayStyle == .euroPerKwh ? "€/kWh" : "s/kWh", chartPrice(nowPoint.price))
                            )
                            .foregroundStyle(appearance == .light ? .black : .white)
                            .symbolSize(50)
                        }
                    }
                    .chartXScale(domain: (result.points.first?.xMinutes ?? 0) ... (result.points.last?.xMinutes ?? 0))
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                }
            } else {
                Text("Hindu pole")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
}
