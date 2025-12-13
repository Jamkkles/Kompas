import SwiftUI
import FirebaseFirestore


class EventsViewModel: ObservableObject {
    @Published var upcomingEvents = [EventItem]()

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
}
