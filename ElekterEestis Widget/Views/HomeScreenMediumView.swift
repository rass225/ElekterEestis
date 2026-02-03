import SwiftUI
import WidgetKit
import Charts

struct HomeScreenMediumView: View {
    let entry: ElectricityWidgetEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var appearance
    
    private var displayStyle: PriceDisplayStyle {
        ElectricityWidgetData.getDisplayStyle(for: "systemMedium", defaultStyle: .euroPerKwh)
    }
    
    private func chartPrice(_ price: Double) -> Double {
        displayStyle == .euroPerKwh ? price / 100.0 : price
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.caption)
                Text("Elekter Eestis")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()

                if let current = entry.data.currentPrice {
                    Text(displayStyle.formatPrice(current.price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            let result = entry.data.chartPointsWithAllData(hoursBefore: 3, hoursAfter: 10)
            if result.points.isEmpty {
                Text("Hindu pole")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else {
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
                .chartXAxis {
                    AxisMarks(values: result.hourLabels.map(\.x)) { value in
                        if let x = value.as(Double.self),
                           let label = result.hourLabels.first(where: { abs($0.x - x) < 0.1 })?.label {
                            AxisValueLabel {
                                Text(label)
                                    .offset(x: -8)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let p = value.as(Double.self) {
                                if displayStyle == .euroPerKwh {
                                    Text(String(format: "%.1f", p))
                                } else {
                                    Text("\(Int(p))")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
