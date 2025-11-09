import SwiftUI
import FirebaseCore

@main
struct KompasApp: App {
    @StateObject private var session = SessionStore.shared
    @StateObject private var locationManager = LocationManager()

    init() {
        FirebaseApp.configure()   // <- requerido
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .environmentObject(locationManager)
        }
    }
}
