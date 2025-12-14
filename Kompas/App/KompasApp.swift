import SwiftUI
import FirebaseCore
import UserNotifications

@main
struct KompasApp: App {
    @StateObject private var session = SessionStore.shared
    @StateObject private var locationManager = LocationManager()

    init() {
        FirebaseApp.configure()
        // { changed code } Asignar delegate para manejar notificaciones
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .environmentObject(locationManager)
        }
    }
}

// { changed code } Nuevo delegate para manejar notificaciones
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Mostrar notificaciones incluso cuando la app está en primer plano
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Manejar taps en notificaciones
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
