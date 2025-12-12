import Foundation
import FirebaseFirestore

struct UserGroup: Identifiable, Equatable {
    var id: String?
    var name: String
    var createdAt: Date
    var ownerId: String
    var memberIds: [String]
    /// Ruta completa del doc en Firestore: "users/{ownerId}/groups/{groupId}"
    var docPath: String

    init(id: String? = nil,
         name: String,
         createdAt: Date = Date(),
         ownerId: String,
         memberIds: [String] = [],
         docPath: String) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.ownerId = ownerId
        self.memberIds = memberIds
        self.docPath = docPath
    }
}

extension UserGroup {
    static func from(document: QueryDocumentSnapshot) -> UserGroup? {
        let data = document.data()
        guard let name = data["name"] as? String,
              let ownerId = data["ownerId"] as? String else { return nil }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let members   = data["memberIds"] as? [String] ?? []

        return UserGroup(
            id: document.documentID,
            name: name,
            createdAt: createdAt,
            ownerId: ownerId,
            memberIds: members,
            docPath: document.reference.path   // <- clave para updates
        )
    }
}

// transición opcional mientras migras otros archivos
typealias Group = UserGroup
