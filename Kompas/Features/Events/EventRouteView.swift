import SwiftUI
import MapKit

struct EventRouteView: View {
    let event: EventItem
    @State private var route: MKRoute?
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        NavigationView {
            ZStack {
                Map(position: $camera) {
                    // Event marker
                    Marker(event.name, coordinate: CLLocationCoordinate2D(
                        latitude: event.location.latitude, 
                        longitude: event.location.longitude
                    ))
                    .tint(.blue)
                    
                    // Route polyline
                    if let route = route {
                        MapPolyline(coordinates: route.polyline.coordinates)
                            .stroke(Brand.tint, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }

                if route == nil {
                    ProgressView("Calculando ruta...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .navigationTitle("Ruta al Evento")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                calculateRoute()
            }
        }
    }

    private func calculateRoute() {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: event.location.latitude, longitude: event.location.longitude)))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Error al calcular la ruta: \(error.localizedDescription)")
                return
            }

            if let route = response?.routes.first {
                self.route = route
                // Update camera to show the route
                self.camera = .region(MKCoordinateRegion(
                    center: route.polyline.coordinate,
                    latitudinalMeters: route.distance * 1.5,
                    longitudinalMeters: route.distance * 1.5
                ))
            }
        }
    }
}