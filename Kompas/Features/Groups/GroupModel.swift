import Foundation
import FirebaseFirestore

struct Group: Identifiable, Equatable {
    var id: String?
    var name: String
    var createdAt: Date
    var ownerId: String
    var memberIds: [String]

    init(id: String? = nil,
         name: String,
         createdAt: Date = Date(),
         ownerId: String,
         memberIds: [String] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.ownerId = ownerId
        self.memberIds = memberIds
    }
}

extension Group {
    /// Construcción segura desde un QueryDocumentSnapshot sin FirebaseFirestoreSwift
    static func from(document: QueryDocumentSnapshot) -> Group? {
        let data = document.data()

        guard let name = data["name"] as? String,
              let ownerId = data["ownerId"] as? String else {
            return nil
        }

        // createdAt puede llegar como Timestamp (o estar ausente si la escritura es reciente)
        let createdAt: Date
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else if let date = data["createdAt"] as? Date {
            createdAt = date
        } else {
            // fallback si aún no llega el serverTimestamp
            createdAt = Date()
        }

        let memberIds = data["memberIds"] as? [String] ?? []

        return Group(
            id: document.documentID,
            name: name,
            createdAt: createdAt,
            ownerId: ownerId,
            memberIds: memberIds
        )
    }
}
