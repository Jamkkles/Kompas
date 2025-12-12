import SwiftUI
import MapKit
import Combine

struct CreateEventView: View {
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    // Datos del evento
    @State private var eventName: String = ""
    @State private var eventParticipants: String = ""
    @State private var eventCoordinate: CLLocationCoordinate2D?

    // Estado del mapa
    @State private var camera: MapCameraPosition = .automatic
    @State private var hasCenteredMap = false

    var body: some View {
        NavigationView {
            ZStack {
                mapView

                VStack(spacing: 16) {
                    Spacer()

                    VStack(spacing: 12) {
                        TextField("Nombre del evento", text: $eventName)
                            .textFieldStyle(.roundedBorder)

                        TextField("Participantes (separados por coma)", text: $eventParticipants)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            saveEvent()
                            dismiss()
                        } label: {
                            Label("Guardar evento", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Brand.tint)
                        .disabled(eventName.trimmingCharacters(in: .whitespaces).isEmpty || eventCoordinate == nil)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .padding()
                }
            }
            .navigationTitle("Nuevo evento")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(
            locationManager.$userLocation
                .compactMap { $0 }
                .removeDuplicates(by: { a, b in
                    a.latitude == b.latitude && a.longitude == b.longitude })
        ) { coord in
            // Centramos solo una vez al obtener la ubicación
            if !hasCenteredMap {
                hasCenteredMap = true
                eventCoordinate = coord
                camera = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                )
            }
        }
    }

    private var mapView: some View {
        Map(position: $camera) {
            if let coord = eventCoordinate {
                Marker("Evento", coordinate: coord)
            }
        }
        .mapControls {
            MapCompass()
            MapUserLocationButton()
            MapPitchToggle()
        }
        .ignoresSafeArea(edges: .top)
    }

    private func saveEvent() {
        print("💾 Guardando evento: \(eventName)")
        if let c = eventCoordinate {
            print("   • coord: \(c.latitude), \(c.longitude)")
        }
        print("   • participantes: \(eventParticipants)")
        // Aquí después conectas con Firestore si quieres
    }
}

#Preview {
    CreateEventView()
        .environmentObject(LocationManager())
}
