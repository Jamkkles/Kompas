import Foundation
import FirebaseFirestore

@MainActor
final class GroupRepository: ObservableObject {
    @Published var groups: [Group] = []
    private var listener: ListenerRegistration?

    func startListening() {
        do {
            let colRef = try FirestoreService.shared.userGroupsCollection()
            listener = colRef
                .order(by: "createdAt", descending: false)
                .addSnapshotListener { [weak self] snapshot, err in
                    if let err = err {
                        print("Error al escuchar groups:", err)
                        return
                    }
                    guard let docs = snapshot?.documents else {
                        self?.groups = []
                        return
                    }
                    self?.groups = docs.compactMap { Group.from(document: $0) }
                }
        } catch {
            print("No se pudo iniciar listener:", error)
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func createGroup(name: String) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "GroupRepository", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "El nombre no puede estar vacío"])
        }

        let colRef = try FirestoreService.shared.userGroupsCollection()

        // Límite de 5 (en cliente)
        let snapshot = try await colRef.getDocuments()
        if snapshot.documents.count >= 5 {
            throw NSError(domain: "GroupRepository", code: 403,
                          userInfo: [NSLocalizedDescriptionKey: "Límite de 5 grupos alcanzado"])
        }

        let ownerId = try FirestoreService.shared.currentUID()
        let data: [String: Any] = [
            "name": trimmed,
            "ownerId": ownerId,
            "memberIds": [ownerId],
            "createdAt": FieldValue.serverTimestamp()
        ]

        _ = try await colRef.addDocument(data: data)
    }

    func renameGroup(_ group: Group, to newName: String) async throws {
        guard let id = group.id else { return }
        let docRef = try FirestoreService.shared.userGroupsCollection().document(id)
        try await docRef.updateData([
            "name": newName.trimmingCharacters(in: .whitespacesAndNewlines)
        ])
    }

    func deleteGroup(_ group: Group) async throws {
        guard let id = group.id else { return }
        let docRef = try FirestoreService.shared.userGroupsCollection().document(id)
        try await docRef.delete()
    }

    func addMember(_ group: Group, memberId: String) async throws {
        guard let id = group.id else { return }
        let docRef = try FirestoreService.shared.userGroupsCollection().document(id)
        try await docRef.updateData([
            "memberIds": FieldValue.arrayUnion([memberId])
        ])
    }

    func removeMember(_ group: Group, memberId: String) async throws {
        guard let id = group.id else { return }
        let docRef = try FirestoreService.shared.userGroupsCollection().document(id)
        try await docRef.updateData([
            "memberIds": FieldValue.arrayRemove([memberId])
        ])
    }
}
