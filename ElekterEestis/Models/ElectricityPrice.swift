import Foundation

struct ElectricityPrice: Codable, Identifiable {
    let date: String
    let price: Double

    private static let parseFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: SharedConstants.tallinnTimeZoneId)
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: SharedConstants.tallinnTimeZoneId)
        return formatter
    }()
    
    var id: String {
        date
    }
    
    enum CodingKeys: String, CodingKey {
        case date, price
    }
    
    var dateTime: Date? {
        Self.parseFormatter.date(from: date)
    }
    
    var formattedTime: String {
        guard let dateTime = dateTime else { return date }
        return Self.timeFormatter.string(from: dateTime)
    }
    
    var formattedPrice: String {
        String(format: "%.2f", price)
    }
}
