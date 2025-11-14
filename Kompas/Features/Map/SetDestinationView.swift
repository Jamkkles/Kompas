import SwiftUI
import MapKit
import Combine

struct SetDestinationView: View {
    @EnvironmentObject var locationManager: LocationManager

    @State private var camera: MapCameraPosition = .automatic
    @State private var destination: CLLocationCoordinate2D?

    var body: some View {
        ZStack {
            // Mapa principal
            Map(position: $camera) {
                if let d = destination {
                    Marker("Destino", coordinate: d)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .ignoresSafeArea()

            // Botón inferior para usar ubicación actual
            VStack {
                Spacer()
                Button {
                    if let c = locationManager.userLocation {
                        destination = c
                        camera = .region(.init(center: c,
                                               span: .init(latitudeDelta: 0.03,
                                                           longitudeDelta: 0.03)))
                    }
                } label: {
                    Label("Usar mi ubicación", systemImage: "location.fill")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.ultraThinMaterial))
                }
                .padding(.bottom, 20)
            }
        }
        // ✅ Observa el publisher del LocationManager y reacciona a cambios reales
        .onReceive(
            locationManager.$userLocation
                .compactMap { $0 } // solo valores no-nil
                .removeDuplicates(by: { a, b in
                    a.latitude == b.latitude && a.longitude == b.longitude
                })
        ) { coord in
            if destination == nil {
                camera = .region(.init(center: coord,
                                       span: .init(latitudeDelta: 0.06,
                                                   longitudeDelta: 0.06)))
            }
        }
    }
}
