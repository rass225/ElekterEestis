import SwiftUI
import Charts
import Foundation

private let tallinnTimeZone = TimeZone(identifier: SharedConstants.tallinnTimeZoneId)!
private let dateHourFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH"
    f.timeZone = tallinnTimeZone
    return f
}()
private var tallinnCalendar: Calendar {
    var cal = Calendar.current
    cal.timeZone = tallinnTimeZone
    return cal
}
private let staleThresholdSeconds: TimeInterval = 3 * 60 * 60
private let absoluteDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm"
    f.timeZone = tallinnTimeZone
    return f
}()

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

    /// Keep a handle so we can cancel/replace an in-flight fetch when user refreshes again.
    @State private var fetchTask: Task<Void, Never>?

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
        }

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

    private var isStale: Bool {
        guard let last = dataStore.lastUpdate else { return true }
        return Date().timeIntervalSince(last) > staleThresholdSeconds
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView()
                } else if let error = errorMessage {
                    if dataStore.prices.isEmpty {
                        errorView(error)
                    } else {
                        listView()
                    }
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
            // Pull-to-refresh runs inside a SwiftUI-managed task, which can be cancelled;
            // our fetch handles cancellation without showing an error.
            .refreshable {
                startFetch(replacingInFlight: true)
                // Wait for the current task to finish so the refresh control ends correctly.
                await fetchTask?.value
            }
            // Use .task instead of .onAppear + spawning a Task to avoid overlapping fetches.
            .task {
                if dataStore.prices.isEmpty || isStale {
                    startFetch(replacingInFlight: false)
                    await fetchTask?.value
                }
            }
        }
    }
}

private extension ContentView {
    func startFetch(replacingInFlight: Bool) {
        if replacingInFlight {
            fetchTask?.cancel()
        }
        fetchTask = Task {
            await fetchPricesAsync()
        }
    }

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
                startFetch(replacingInFlight: true)
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
            Button("Lae hinnad") {
                startFetch(replacingInFlight: true)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
    }

    @ViewBuilder
    func listView() -> some View {
        List {
            if let error = errorMessage {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Uuendamine ebaõnnestus. Kuvan viimased salvestatud hinnad.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if isStale {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundColor(.orange)
                        Text("Andmed võivad olla aegunud.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                let data = chartData
                if data.points.isEmpty {
                    Text("Selles vahemikus hindu pole")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(height: 256)
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
                        Text(absoluteDateFormatter.string(from: lastUpdate))
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
    }

    func fetchPricesAsync() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let prices = try await ElectricityPriceService.shared.fetchPrices()
            try Task.checkCancellation()

            await MainActor.run {
                dataStore.savePrices(prices)
                isLoading = false
                print("Fetch done")
            }
        } catch is CancellationError {
            await MainActor.run {
                isLoading = false
            }
        } catch let urlError as URLError where urlError.code == .cancelled {
            // Some APIs surface cancellation this way.
            await MainActor.run {
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
