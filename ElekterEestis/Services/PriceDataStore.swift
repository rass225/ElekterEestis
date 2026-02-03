//
//  PriceDataStore.swift
//  ElekterEestis
//
//  Created by Rasmus Tauts on 31.01.2026.
//

import SwiftUI
import Combine
import WidgetKit

class PriceDataStore: ObservableObject {
    static let shared = PriceDataStore()
    
    private let appGroupIdentifier = SharedConstants.appGroupIdentifier
    private let pricesKey = SharedConstants.pricesKey
    private let lastUpdateKey = SharedConstants.lastUpdateKey
    
    @Published var prices: [ElectricityPrice] = []
    @Published var nextThreeHours: [ElectricityPrice] = []
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    private init() {
        loadPrices()
    }
    
    func savePrices(_ prices: [ElectricityPrice]) {
        self.prices = prices
        self.nextThreeHours = ElectricityPriceService.shared.getNextThreeHoursPrices(from: prices)
        
        // Save to UserDefaults for widget access
        if let encoded = try? JSONEncoder().encode(prices) {
            userDefaults?.set(encoded, forKey: pricesKey)
            userDefaults?.set(Date(), forKey: lastUpdateKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func loadPrices() {
        guard let data = userDefaults?.data(forKey: pricesKey),
              let prices = try? JSONDecoder().decode([ElectricityPrice].self, from: data) else {
            return
        }
        
        self.prices = prices
        self.nextThreeHours = ElectricityPriceService.shared.getNextThreeHoursPrices(from: prices)
    }
    
    var lastUpdate: Date? {
        userDefaults?.object(forKey: lastUpdateKey) as? Date
    }
}
