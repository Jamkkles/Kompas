import Foundation
import CoreLocation

// 1. Declaramos la clase como un ObservableObject para que las vistas de SwiftUI puedan reaccionar a sus cambios.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // 2. Creamos la instancia del administrador de CoreLocation.
    private let locationManager = CLLocationManager()
    
    // 3. Esta variable @Published notificará a todas las vistas cuando la ubicación cambie.
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest // Máxima precisión
        self.locationManager.requestWhenInUseAuthorization() // Pide permiso
        self.locationManager.startUpdatingLocation() // Empieza a rastrear
    }

    // 4. Esta función se llama cada vez que el GPS obtiene una nueva ubicación.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Actualizamos nuestra variable @Published con la última ubicación.
        if let location = locations.first?.coordinate {
            DispatchQueue.main.async {
                self.userLocation = location
            }
        }
    }

    // Opcional: Manejo de errores
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener la ubicación: \(error.localizedDescription)")
    }
}
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        // Dos coordenadas son "iguales" si su latitud Y longitud son iguales.
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
