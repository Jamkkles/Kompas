import UserNotifications
import CoreLocation
import UIKit  

final class NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("❌ Error solicitando permisos: \(error)")
            return false
        }
    }
    
    func notifyArrivalAtDestination(memberName: String, destination: String) {
        let content = UNMutableNotificationContent()
        content.title = "¡\(memberName) llegó!"
        content.body = "\(memberName) ha llegado a \(destination)"
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error enviando notificación: \(error)")
            }
        }
    }
    
    func notifyDeparture(memberName: String, origin: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(memberName) se va"
        content.body = "\(memberName) está saliendo de \(origin)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error enviando notificación: \(error)")
            }
        }
    }
    
    func notifySOSActivation(memberName: String) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ EMERGENCIA"
        content.body = "\(memberName) ha activado el SOS"
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "SOS-\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error enviando notificación SOS: \(error)")
            }
        }
    }
}