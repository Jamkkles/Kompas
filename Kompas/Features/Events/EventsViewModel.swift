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
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorAlert = true
                } else {
                    if let index = self?.upcomingEvents.firstIndex(where: { $0.id == event.id }) {
                        self?.upcomingEvents[index].name = newName
                    }
                }
            }
        }
    }
    
    // Nueva función para ocultar/mostrar evento
    func toggleEventVisibility(_ event: EventItem) {
        guard let eventID = event.id else { return }
        
        let newHiddenState = !(event.isHidden ?? false)
        let eventRef = db.collection("events").document(eventID)
        
        eventRef.updateData(["isHidden": newHiddenState]) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.showErrorAlert = true
            } else {
                if let index = self?.upcomingEvents.firstIndex(where: { $0.id == event.id }) {
                    self?.upcomingEvents[index].isHidden = newHiddenState
                }
            }
        }
    }

    func setEventVisibility(_ event: EventItem, hidden: Bool) {
        guard let eventID = event.id else { return }
        let eventRef = db.collection("events").document(eventID)
        eventRef.updateData(["isHidden": hidden]) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.showErrorAlert = true
            } else {
                if let idx = self?.upcomingEvents.firstIndex(where: { $0.id == event.id }) {
                    self?.upcomingEvents[idx].isHidden = hidden
                }
            }
        }
    }

    func deleteEvent(_ event: EventItem) {
        if let eventID = event.id {
            db.collection("events").document(eventID).delete() { [weak self] error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.showErrorAlert = true
                } else {
                    self?.upcomingEvents.removeAll(where: { $0.id == event.id })
                }
            }
        }
    }

    // Nueva función para calcular rutas
    func calculateRoute(for event: EventItem, from userLocation: CLLocationCoordinate2D) {
        guard let eventId = event.id else { 
            return 
        }
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
                    return
                }
                
                if let route = response?.routes.first {
                    self?.eventRoutes[eventId] = route
                } else {
                    print("No se pudo calcular la ruta")
                }
            }
        }
    }
    
    func clearRoutes() {
        eventRoutes.removeAll()
    }
    
    // Nueva función para cancelar una ruta específica
    func clearRoute(for eventId: String) {
        eventRoutes.removeValue(forKey: eventId)
    }
}
