import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class GroupRepository: ObservableObject {
    @Published var groups: [UserGroup] = []
    @Published var lastError: String?      // <- útil para depurar en UI opcionalmente
    private var listener: ListenerRegistration?

    func startListening() {
        stopListening()
        do {
            let uid = try FirestoreService.shared.currentUID()

            // 🔑 Query universal: trae TODOS los grupos (de cualquier dueño) donde yo soy miembro.
            // Importante: SIN order(by:) para no requerir índice compuesto.
            listener = FirestoreService.shared.db
                .collectionGroup("groups")
                .whereField("memberIds", arrayContains: uid)
                .addSnapshotListener { [weak self] snapshot, err in
                    if let err = err {
                        print("❌ Listener groups error:", err.localizedDescription)
                        self?.lastError = err.localizedDescription
                        self?.groups = []
                        return
                    }
                    guard let docs = snapshot?.documents else {
                        self?.groups = []
                        return
                    }
                    var result = docs.compactMap { UserGroup.from(document: $0) }
                    // Ordena en memoria (por nombre asc). Cambia a createdAt si prefieres.
                    result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    self?.groups = result
                    print("✅ Groups loaded (\(result.count)) para uid:", uid)
                }

        } catch {
            print("❌ No se pudo iniciar listener:", error.localizedDescription)
            self.lastError = error.localizedDescription
            self.groups = []
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // --- resto igual ---

    func createGroup(name: String) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "GroupRepository", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "El nombre no puede estar vacío"])
        }

        let colRef = try FirestoreService.shared.userGroupsCollection()
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

    func renameGroup(_ group: UserGroup, to newName: String) async throws {
        let docRef = FirestoreService.shared.db.document(group.docPath)
        try await docRef.updateData(["name": newName.trimmingCharacters(in: .whitespacesAndNewlines)])
    }

    func deleteGroup(_ group: UserGroup) async throws {
        let docRef = FirestoreService.shared.db.document(group.docPath)
        try await docRef.delete()
    }

    func createInvite(for group: UserGroup, validForHours: Int = 48) async throws -> String {
        guard let groupId = group.id else {
            throw NSError(domain: "GroupRepository", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Grupo sin ID"])
        }
        let ownerId = group.ownerId
        let code = randomCode(7)
        let invites = FirestoreService.shared.invitesCollection()

        let groupPath = group.docPath
        let now = Date()
        let expires = Calendar.current.date(byAdding: .hour, value: validForHours, to: now) ?? now

        let data: [String: Any] = [
            "ownerId": ownerId,
            "groupId": groupId,
            "groupPath": groupPath,
            "createdAt": Timestamp(date: now),
            "expiresAt": Timestamp(date: expires),
            "active": true,
            "singleUse": false
        ]

        try await invites.document(code).setData(data, merge: false)
        return code
    }

    func joinByCode(_ code: String) async throws {
        let trimmed = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "GroupRepository", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Código vacío"])
        }

        let uid = try FirestoreService.shared.currentUID()
        let inviteRef = FirestoreService.shared.invitesCollection().document(trimmed)
        let snap = try await inviteRef.getDocument()
        guard let data = snap.data() else {
            throw NSError(domain: "GroupRepository", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Invitación no encontrada"])
        }

        guard (data["active"] as? Bool) == true else {
            throw NSError(domain: "GroupRepository", code: 410,
                          userInfo: [NSLocalizedDescriptionKey: "Invitación desactivada"])
        }
        if let expiresTs = data["expiresAt"] as? Timestamp, expiresTs.dateValue() < Date() {
            throw NSError(domain: "GroupRepository", code: 410,
                          userInfo: [NSLocalizedDescriptionKey: "Invitación expirada"])
        }
        guard let groupPath = data["groupPath"] as? String else {
            throw NSError(domain: "GroupRepository", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "Invitación inválida"])
        }

        let groupRef = FirestoreService.shared.db.document(groupPath)
        try await groupRef.updateData(["memberIds": FieldValue.arrayUnion([uid])])

        if (data["singleUse"] as? Bool) == true {
            try await inviteRef.updateData(["active": false])
        }
    }

    private func randomCode(_ n: Int = 7) -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<n).map { _ in chars.randomElement()! })
    }
}
