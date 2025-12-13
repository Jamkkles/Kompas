import SwiftUI
import MapKit
import Combine

struct CreateEventView: View {
    @StateObject private var viewModel: CreateEventViewModel
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    // Estado del mapa
    @State private var hasCenteredMap = false

    init(session: SessionStore) {
        _viewModel = StateObject(wrappedValue: CreateEventViewModel(session: session))
    }

    var body: some View {
        NavigationView {
            ZStack {
                mapView

                VStack(spacing: 16) {
                    Spacer()

                    VStack(spacing: 12) {
                        TextField("Nombre del evento", text: $viewModel.eventName)
                            .textFieldStyle(.roundedBorder)

                        TextField("Participantes (separados por coma)", text: $viewModel.eventParticipants)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            viewModel.saveEvent()
                            dismiss()
                        } label: {
                            Label("Guardar evento", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Brand.tint)
                        .disabled(viewModel.eventName.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.eventCoordinate == nil)
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
                viewModel.eventCoordinate = coord
                viewModel.camera = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                )
            }
        }
    }

    private var mapView: some View {
        MapReader { reader in
            Map(position: $viewModel.camera) {
                if let coord = viewModel.eventCoordinate {
                    Marker("Evento", coordinate: coord)
                }
            }
            .onTapGesture { screenCoord in
                viewModel.eventCoordinate = reader.convert(screenCoord, from: .local)
            }
            .mapControls {
                MapCompass()
                MapUserLocationButton()
                MapPitchToggle()
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

#Preview {
    CreateEventView(session: SessionStore.shared)
        .environmentObject(LocationManager())
        .environmentObject(SessionStore.shared)
}
