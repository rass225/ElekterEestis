import Foundation

struct ElectricityPrice: Codable, Identifiable {
    let date: String
    let price: Double
    
    var id: String {
        date
    }
    
    enum CodingKeys: String, CodingKey {
        case date, price
    }
    
    var dateTime: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "Europe/Tallinn")
        return formatter.date(from: date)
    }
    
    var formattedTime: String {
        guard let dateTime = dateTime else { return date }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: dateTime)
    }
    
    var formattedPrice: String {
        String(format: "%.2f", price)
    }
}
