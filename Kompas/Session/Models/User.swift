import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    var name: String
    var photoURL: URL?

    init(id: String, email: String, name: String, photoURL: URL? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.photoURL = photoURL
    }
}
