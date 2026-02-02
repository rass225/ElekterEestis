import SwiftUI
import Charts

private let tallinnTimeZone = TimeZone(identifier: "Europe/Tallinn")!
private var dateHourFormatter: DateFormatter {
    let f = DateFormatter()
    f.dateFormat = "HH"
    f.timeZone = tallinnTimeZone
    return f
}
private var tallinnCalendar: Calendar {
    var cal = Calendar.current
    cal.timeZone = tallinnTimeZone
    return cal
}

private struct AppChartPoint: Identifiable {
    let id: String
    let xMinutes: Double
    let date: Date
    let price: Double
}

struct ContentView: View {
    @StateObject private var dataStore = PriceDataStore.shared
    @StateObject private var displayPreference = PriceDisplayPreference.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var chartPrices: [ElectricityPrice] {
        let now = Date()
        let start = now.addingTimeInterval(-1 * 60 * 60)
        let end = now.addingTimeInterval(10 * 60 * 60)
        return dataStore.prices.filter { price in
            guard let dt = price.dateTime else { return false }
            return dt >= start && dt <= end
        }
    }
    
    /// All 15-min chart data. xMinutes = position from chart start. currentPoint = closest to now.
    private var chartData: (points: [AppChartPoint], currentPoint: AppChartPoint?, hourLabels: [(x: Double, label: String)]) {
        let calendar = tallinnCalendar
        let now = Date()
        let startOfCurrent = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: now)) ?? now
        let startHour = calendar.date(byAdding: .hour, value: -1, to: startOfCurrent) ?? startOfCurrent
        let endHour = calendar.date(byAdding: .hour, value: 10, to: startOfCurrent) ?? startOfCurrent

        let inRange = chartPrices.compactMap { p -> (date: Date, price: Double)? in
            guard let dt = p.dateTime else { return nil }
            return dt >= startHour && dt <= endHour ? (dt, p.price) : nil
        }.sorted { $0.date < $1.date }

        let points = inRange.enumerated().map { index, item in
            let xMinutes = item.date.timeIntervalSince(startHour) / 60.0
            return AppChartPoint(id: "\(index)", xMinutes: xMinutes, date: item.date, price: item.price)
        }

        let currentPoint = points.min(by: { abs($0.date.timeIntervalSince(now)) < abs($1.date.timeIntervalSince(now)) })

        // Hour labels from actual points at hour boundaries (XX:00 only)
        let hourLabels: [(x: Double, label: String)] = points
            .filter { calendar.component(.minute, from: $0.date) == 0 }
            .map { (x: $0.xMinutes, label: dateHourFormatter.string(from: $0.date)) }

        return (points, currentPoint, hourLabels)
    }
    
    private var upcomingPrices: [ElectricityPrice] {
        let now = Date()
        return dataStore.prices.filter { price in
            guard let dt = price.dateTime else { return false }
            return dt >= now
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView()
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    if dataStore.prices.isEmpty {
                        emptyView()
                    } else {
                        listView()
                    }
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .title, content: {
                    Text("Elektri hinnad")
                        .font(.title2)
                })
                ToolbarItem(placement: .topBarTrailing) {
                    Menu(content: {
                        Picker("", selection: $displayPreference.displayStyle) {
                            ForEach(PriceDisplayStyle.allCases, id: \.self) { style in
                                Text(style.label)
                                    .tag(style)
                            }
                        }
                    }, label: {
                        Text(displayPreference.displayStyle.label)
                    })
                }
            }
            .refreshable {
                await fetchPricesAsync()
            }
            .onAppear {
                if dataStore.prices.isEmpty {
                    fetchPrices()
                }
            }
        }
    }
}

private extension ContentView {
    @ViewBuilder
    func loadingView() -> some View {
        ProgressView("Hindu laetakse...")
    }
    
    @ViewBuilder
    func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(error)
                .foregroundColor(.secondary)
            Button("Proovi uuesti") {
                fetchPrices()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    @ViewBuilder
    func emptyView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.slash")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Hinnad pole saadaval")
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    @ViewBuilder
    func listView() -> some View {
        List {
            Section {
                let data = chartData
                if data.points.isEmpty {
                    Text("Selles vahemikus hindu pole")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(height: 400)
                        .frame(maxWidth: .infinity)
                } else {
                    let style = displayPreference.displayStyle
                    Chart {
                        ForEach(data.points) { point in
                            LineMark(
                                x: .value("Min", point.xMinutes),
                                y: .value(style.label, style.chartValue(point.price))
                            )
                            .foregroundStyle(.cyan)
                            .interpolationMethod(.catmullRom)
                            AreaMark(
                                x: .value("Min", point.xMinutes),
                                y: .value(style.label, style.chartValue(point.price))
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
                        if let nowPoint = data.currentPoint {
                            PointMark(
                                x: .value("Min", nowPoint.xMinutes),
                                y: .value(style.label, style.chartValue(nowPoint.price))
                            )
                            .foregroundStyle(.white)
                            .symbolSize(50)
                        }
                    }
                    .chartXScale(domain: (data.points.first?.xMinutes ?? 0) ... (data.points.last?.xMinutes ?? 0))
                    .chartXAxis {
                        AxisMarks(values: data.hourLabels.map(\.x)) { value in
                            if let x = value.as(Double.self),
                               let label = data.hourLabels.first(where: { abs($0.x - x) < 0.1 })?.label {
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
                                    Text(style == .euroPerKwh ? String(format: "%.1f", p) : String(format: "%.0f", p))
                                }
                            }
                        }
                    }
                    .frame(height: 256)
                    .padding(.top)
                }
            }
            
            Section {
                ForEach(upcomingPrices) { price in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(price.formattedTime)
                                .font(.headline)
                            if let dateTime = price.dateTime {
                                Text(dateTime, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text(displayPreference.displayStyle.formatPrice(price.price))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if let lastUpdate = dataStore.lastUpdate {
                Section {
                    HStack {
                        Text("Viimati uuendatud")
                        Spacer()
                        Text(lastUpdate, style: .relative)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
    }
}

private extension ContentView {
    func fetchPrices() {
        Task {
            await fetchPricesAsync()
        }
    }
    
    func fetchPricesAsync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let prices = try await ElectricityPriceService.shared.fetchPrices()
            await MainActor.run {
                dataStore.savePrices(prices)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Hindade laadimine ebaõnnestus: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
