import SwiftUI
import FirebaseFirestore

struct EventItem: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    let participants: [String]
    let location: GeoPoint
    let createdBy: String
    let createdAt: Timestamp

    var color: Color {
        // You can determine the color based on some logic,
        // for example, based on the creator of the event.
        .blue
    }
}
