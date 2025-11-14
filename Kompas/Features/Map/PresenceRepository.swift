import Foundation
import FirebaseFirestore
import CoreLocation
import UIKit

// MARK: - Modelo que usa el mapa y la lista
struct MemberPresence: Identifiable, Equatable {
    let id: String                 // uid del miembro
    let displayName: String
    let photoURL: URL?
    let coordinate: CLLocationCoordinate2D?
    let locationText: String
    let lastUpdate: Date?
    let batteryPercent: Int?

    static func == (lhs: MemberPresence, rhs: MemberPresence) -> Bool {
        lhs.id == rhs.id &&
        lhs.displayName == rhs.displayName &&
        lhs.photoURL == rhs.photoURL &&
        lhs.locationText == rhs.locationText &&
        lhs.batteryPercent == rhs.batteryPercent &&
        lhs.coordinate?.latitude == rhs.coordinate?.latitude &&
        lhs.coordinate?.longitude == rhs.coordinate?.longitude &&
        lhs.lastUpdate == rhs.lastUpdate
    }
}

@MainActor
final class PresenceRepository: ObservableObject {
    @Published var members: [MemberPresence] = []
    private var listener: ListenerRegistration?

    /// Escucha presencias en: {groupDocPath}/members
    /// Ej: "users/{ownerId}/groups/{groupId}/members"
    func startListening(groupDocPath: String) {
        stopListening()

        let col = Firestore.firestore()
            .document(groupDocPath)
            .collection("members")

        listener = col.addSnapshotListener { [weak self] snap, err in
            guard err == nil, let docs = snap?.documents else {
                self?.members = []
                return
            }

            let items: [MemberPresence] = docs.map { d in
                let data = d.data()

                let name = (data["displayName"] as? String) ?? "—"
                let photo = (data["photoURL"] as? String).flatMap(URL.init(string:))
                let bat   = data["batteryPercent"] as? Int
                let last  = (data["lastUpdate"] as? Timestamp)?.dateValue()
                let lat   = data["lat"] as? CLLocationDegrees
                let lon   = data["lon"] as? CLLocationDegrees
                let loc   = (data["locationText"] as? String) ?? "Última ubicación"

                let coord: CLLocationCoordinate2D? = {
                    if let lat, let lon {
                        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                    return nil
                }()

                return MemberPresence(
                    id: d.documentID,
                    displayName: name,
                    photoURL: photo,
                    coordinate: coord,
                    locationText: loc,
                    lastUpdate: last,
                    batteryPercent: bat
                )
            }

            // Ordenamos por última actualización (más reciente primero)
            self?.members = items.sorted {
                ($0.lastUpdate ?? .distantPast) > ($1.lastUpdate ?? .distantPast)
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    /// Actualiza (o crea) mi documento de presencia dentro del grupo.
    /// Esto es lo que hace que aparezca cada miembro en el mapa y en la lista.
    func updateMyPresence(groupDocPath: String, user: User, coordinate: CLLocationCoordinate2D) {
        let db = Firestore.firestore()
        let membersCol = db.document(groupDocPath).collection("members")
        let doc = membersCol.document(user.id)

        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryPercent: Int? = batteryLevel >= 0 ? Int(batteryLevel * 100) : nil

        var data: [String: Any] = [
            "displayName": user.name,
            "email": user.email,
            "lat": coordinate.latitude,
            "lon": coordinate.longitude,
            "lastUpdate": FieldValue.serverTimestamp()
        ]

        if let url = user.photoURL?.absoluteString {
            data["photoURL"] = url
        }
        if let bat = batteryPercent {
            data["batteryPercent"] = bat
        }

        doc.setData(data, merge: true)
    }
}
