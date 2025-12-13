import Foundation

enum EventIcon: String, Codable, CaseIterable {
    case calendar = "calendar"
    case party = "gift.fill"
    case drink = "wineglass.fill"
    
    var symbolName: String {
        return self.rawValue
    }
}
