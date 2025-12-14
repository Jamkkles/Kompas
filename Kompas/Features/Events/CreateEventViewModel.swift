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

    init(session: SessionStore, initialCoordinate: CLLocationCoordinate2D? = nil) {
        self.session = session
        if let coord = initialCoordinate {
            self.eventCoordinate = coord
            self.camera = .region(
                MKCoordinateRegion(center: coord,
                                   span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            )
        }
    }

    @MainActor
    func saveEvent(date: Date, icon: EventIcon, photoBase64: String?) async {
        if let c = eventCoordinate {
            print("   • coord: \(c.latitude), \(c.longitude)")
        }

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
            // A rough estimate of byte size: Base64 string is about 1.33 times larger than original data
            eventData["photoBase64"] = photoBase64
        }

        do {
            try await db.collection("events").addDocument(data: eventData)
        } catch {
            print("Error al guardar el evento en Firestore: \(error.localizedDescription)")
        }
    }
}
