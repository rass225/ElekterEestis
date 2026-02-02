//
//  ElekterEestisApp.swift
//  ElekterEestis
//
//  Created by Rasmus Tauts on 31.01.2026.
//

import SwiftUI
import BackgroundTasks

@main
struct ElekterEestisApp: App {
    @StateObject private var dataStore = PriceDataStore.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .onAppear {
                    scheduleBackgroundRefresh()
                }
        }
        .backgroundTask(.appRefresh("tauts.ElekterEestis.refresh")) {
            await refreshPrices()
            await scheduleBackgroundRefresh()
        }
    }
    
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "tauts.ElekterEestis.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func refreshPrices() async {
        do {
            let prices = try await ElectricityPriceService.shared.fetchPrices()
            await MainActor.run {
                dataStore.savePrices(prices)
            }
        } catch {
            print("Background refresh failed: \(error)")
        }
    }
}
