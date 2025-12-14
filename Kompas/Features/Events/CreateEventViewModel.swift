import SwiftUI
import MapKit
import Combine
import FirebaseFirestore

class CreateEventViewModel: ObservableObject {
    @Published var eventName: String = ""
    @Published var eventParticipants: String = ""
    @Published var eventCoordinate: CLLocationCoordinate2D?
    @Published var camera: MapCameraPosition = .automatic

    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
    }

    @MainActor
    func saveEvent(date: Date, icon: EventIcon, photoBase64: String?) async {
        print("💾 Guardando evento: \(eventName)")
        if let c = eventCoordinate {
            print("   • coord: \(c.latitude), \(c.longitude)")
        }
        print("   • participantes: \(eventParticipants)")

        guard let eventCoordinate = eventCoordinate else {
            print("Error: No se ha seleccionado una ubicación para el evento.")
            return
        }

        guard let currentUserID = session.user?.id else {
            print("Error: El usuario no está autenticado.")
            return
        }

        let db = Firestore.firestore()
        
        var eventData: [String: Any] = [
            "name": eventName,
            "participants": eventParticipants.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            "location": GeoPoint(latitude: eventCoordinate.latitude, longitude: eventCoordinate.longitude),
            "createdBy": currentUserID,
            "createdAt": Timestamp(date: Date()),
            "date": Timestamp(date: date),
            "icon": icon.rawValue,
            "isHidden": false // Inicializar como visible por defecto
        ]
        
        if let photoBase64 = photoBase64 {
            print("📷 Photo Base64 string length: \(photoBase64.count) characters")
            // A rough estimate of byte size: Base64 string is about 1.33 times larger than original data
            print("📷 Estimated Photo Data Size: \((Double(photoBase64.count) * 0.75) / 1024 / 1024) MB")
            eventData["photoBase64"] = photoBase64
        } else {
            print("📷 No photoBase64 provided or conversion failed.")
        }

        do {
            try await db.collection("events").addDocument(data: eventData)
            print("¡Evento guardado exitosamente en Firestore!")
        } catch {
            print("Error al guardar el evento en Firestore: \(error.localizedDescription)")
        }
    }
}
