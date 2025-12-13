import SwiftUI
import FirebaseFirestore


final class EventsViewModel: ObservableObject {
    @Published var upcomingEvents = [EventItem]()
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
}
