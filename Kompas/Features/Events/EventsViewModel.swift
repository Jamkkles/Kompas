import SwiftUI
import FirebaseFirestore
import MapKit

final class EventsViewModel: ObservableObject {
    @Published var upcomingEvents = [EventItem]()
    @Published var eventRoutes: [String: MKRoute] = [:] // Nuevas rutas por evento ID
    @Published var errorMessage: String?
    @Published var showErrorAlert = false

    private var db = Firestore.firestore()

    func fetchEvents() {
        db.collection("events")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }

                self.upcomingEvents = documents.compactMap { queryDocumentSnapshot -> EventItem? in
                    return try? queryDocumentSnapshot.data(as: EventItem.self)
                }
            }
    }

    func updateEvent(_ event: EventItem, newName: String) {
        if let eventID = event.id {
            let eventRef = db.collection("events").document(eventID)
            eventRef.updateData(["name": newName]) { [weak self] error in
                if let error = error {
                    print("Error updating event: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorAlert = true
                } else {
                    print("Event successfully updated")
                    if let index = self?.upcomingEvents.firstIndex(where: { $0.id == event.id }) {
                        self?.upcomingEvents[index].name = newName
                    }
                }
            }
        }
    }

    func deleteEvent(_ event: EventItem) {
        if let eventID = event.id {
            db.collection("events").document(eventID).delete() { [weak self] error in
                if let error = error {
                    print("Error removing document: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorAlert = true
                } else {
                    print("Document successfully removed!")
                    self?.upcomingEvents.removeAll(where: { $0.id == event.id })
                }
            }
        }
    }

    // Nueva función para calcular rutas
    func calculateRoute(for event: EventItem, from userLocation: CLLocationCoordinate2D) {
        guard let eventId = event.id else { 
            print("❌ Evento sin ID")
            return 
        }
        
        print("🗺️ Calculando ruta para evento: \(event.name)")
        print("   • Desde: \(userLocation)")
        print("   • Hacia: \(event.location)")
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(
                latitude: event.location.latitude,
                longitude: event.location.longitude
            )
        ))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error calculando ruta: \(error.localizedDescription)")
                    return
                }
                
                if let route = response?.routes.first {
                    print("✅ Ruta calculada exitosamente")
                    print("   • Distancia: \(route.distance/1000) km")
                    print("   • Tiempo: \(route.expectedTravelTime/60) min")
                    self?.eventRoutes[eventId] = route
                } else {
                    print("❌ No se pudo calcular la ruta")
                }
            }
        }
    }
    
    func clearRoutes() {
        eventRoutes.removeAll()
    }
}
