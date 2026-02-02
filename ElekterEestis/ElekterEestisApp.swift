import SwiftUI

@main
struct ElekterEestisApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dataStore = PriceDataStore.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Scheduler.scheduleDailyRefresh()
            }
        }
    }
}
