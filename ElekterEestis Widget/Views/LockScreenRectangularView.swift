import SwiftUI
import Charts

struct LockScreenRectangularView: View {
    let entry: ElectricityWidgetEntry

    private var displayStyle: PriceDisplayStyle {
        ElectricityWidgetData.getDisplayStyle(for: "accessoryRectangular", defaultStyle: .euroPerKwh)
    }

    private func chartPrice(_ price: Double) -> Double {
        displayStyle == .euroPerKwh ? price / 100.0 : price
    }

    var body: some View {
        let result = entry.data.chartPointsWithAllData(hoursBefore: 0, hoursAfter: 6)
        HStack(alignment: .center, spacing: 6) {
            if let current = entry.data.currentPrice {
                VStack(alignment: .center, spacing: 0) {
                    Text(ElectricityWidgetData.formatPriceValue(current.price, style: displayStyle))
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                    Text(ElectricityWidgetData.formatPriceUnit(displayStyle))
                        .font(.system(size: 9))
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
            }
            if result.points.isEmpty {
                Text("Hindu pole")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(result.points) { point in
                        LineMark(
                            x: .value("Min", point.xMinutes),
                            y: .value(displayStyle == .euroPerKwh ? "€/kWh" : "s/kWh",
                                      chartPrice(point.price))
                        )
                        .foregroundStyle(.cyan)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Min", point.xMinutes),
                            y: .value(displayStyle == .euroPerKwh ? "€/kWh" : "s/kWh",
                                      chartPrice(point.price))
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan.opacity(0.4), .cyan.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }

                    if let nowPoint = result.currentPoint {
                        PointMark(
                            x: .value("Min", nowPoint.xMinutes),
                            y: .value(displayStyle == .euroPerKwh ? "€/kWh" : "s/kWh",
                                      chartPrice(nowPoint.price))
                        )
                        .foregroundStyle(.white)
                        .symbolSize(30)
                    }
                }
                .chartXScale(domain: (result.points.first?.xMinutes ?? 0) ... (result.points.last?.xMinutes ?? 0))
                .chartXAxis {
                    AxisMarks(values: result.hourLabels.map(\.x)) { value in
                        if let x = value.as(Double.self),
                           let label = result.hourLabels.first(where: { abs($0.x - x) < 0.1 })?.label {
                            AxisValueLabel {
                                Text(label)
                                    .font(.system(size: 8))
                                    .lineLimit(1)
                                    .offset(x: -8)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel {
                            if let p = value.as(Double.self) {
                                if displayStyle == .euroPerKwh {
                                    Text(String(format: "%.1f", p))
                                        .font(.system(size: 8))
                                } else {
                                    Text("\(Int(p))")
                                        .font(.system(size: 8))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
        .padding(.leading, 7)
        .padding(.trailing, 0.5)
        .background(.ultraThickMaterial, in: .rect(cornerRadius: 20, style: .continuous))
    }
}
