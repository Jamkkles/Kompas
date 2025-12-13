import SwiftUI
import MapKit

struct EventRouteView: View {
    let event: EventItem
    @State private var route: MKRoute?
    @State private var region: MKCoordinateRegion = .init(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: [event]) { event in
                    MapMarker(coordinate: CLLocationCoordinate2D(latitude: event.location.latitude, longitude: event.location.longitude), tint: .blue)
                }
                .overlay(routeOverlay)

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

    private var routeOverlay: some View {
        SwiftUI.Group {
            if let route = route {
                MapPolyline(route: route)
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
                self.region = MKCoordinateRegion(
                    center: route.polyline.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }
}