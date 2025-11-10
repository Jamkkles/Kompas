import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}

    let db = Firestore.firestore()

    func currentUID() throws -> String {
        if let uid = Auth.auth().currentUser?.uid {
            return uid
        }
        throw NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"])
    }

    func userGroupsCollection() throws -> CollectionReference {
        let uid = try currentUID()
        return db.collection("users").document(uid).collection("groups")
    }
}
