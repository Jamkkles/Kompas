import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: EventsViewModel
    @EnvironmentObject var locationManager: LocationManager // Usar el environment object
    @State var event: EventItem
    @State private var showRoute = false
    @State private var hasRoute = false // Nueva variable de estado
    
    // Agregar esta variable para comunicarse con el tab principal
    @Binding var selectedTab: Int
    
    var body: some View {
        Form {
            Section(header: Text("Detalles del Evento")) {
                TextField("Nombre del evento", text: $event.name)
            }

            if let photoBase64 = event.photoBase64,
               let imageData = Data(base64Encoded: photoBase64),
               let uiImage = UIImage(data: imageData) {
                Section(header: Text("Foto del Evento")) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(8)
                }
            }

            Section {
                VStack(spacing: 12) {
                    Button("Ir a evento") {
                        // Usar el LocationManager del environment object
                        if let userLocation = locationManager.userLocation {
                            print("🗺️ Calculando ruta desde: \(userLocation)")
                            print("🎯 Hacia evento: \(event.name) en \(event.location)")
                            
                            // Calcular la ruta para este evento específico
                            viewModel.calculateRoute(for: event, from: userLocation)
                            
                            // Activar el modo de rutas en el mapa principal
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowEventRoute"),
                                object: event.id
                            )
                            
                            print("📡 Notificación enviada para evento: \(event.id ?? "sin ID")")
                            
                            // Cambiar al tab del mapa
                            selectedTab = 0
                            
                            // Cerrar la vista actual
                            dismiss()
                        } else {
                            print("❌ No hay ubicación disponible")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    // Botón para cancelar ruta si existe
                    if hasRoute {
                        Button("Cancelar ruta") {
                            guard let eventId = event.id else { return }
                            withAnimation { viewModel.clearRoute(for: eventId) }
                            NotificationCenter.default.post(
                                name: NSNotification.Name("CancelEventRoute"),
                                object: eventId
                            )
                            syncRouteState()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            }
            
            // Nueva sección para ocultar/mostrar en el mapa
            Section {
                Toggle(isOn: Binding(
                    get: { !(event.isHidden ?? false) },
                    set: { newValue in
                        viewModel.toggleEventVisibility(event)
                        event.isHidden = !newValue
                    }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: event.isHidden ?? false ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(event.isHidden ?? false ? .secondary : Brand.tint)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mostrar en el mapa")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(event.isHidden ?? false ? "El evento está oculto" : "El evento es visible")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(Brand.tint)
            } header: {
                Text("Visibilidad")
            } footer: {
                Text("Los eventos ocultos no se mostrarán en el mapa pero seguirán apareciendo en tu lista de eventos")
            }

            Section {
                Button("Guardar Cambios") {
                    viewModel.updateEvent(event, newName: event.name)
                    dismiss()
                }
            }

            Section {
                Button("Eliminar Evento", role: .destructive) {
                    viewModel.deleteEvent(event)
                    dismiss()
                }
            }
        }
        .navigationTitle("Editar Evento")
        .onAppear { syncRouteState() }
        .onReceive(viewModel.$eventRoutes) { _ in
            syncRouteState()
        }
        .sheet(isPresented: $showRoute) {
            EventRouteView(event: event)
        }
    }

    private func syncRouteState() {
        if let eventId = event.id {
            hasRoute = viewModel.eventRoutes[eventId] != nil
        } else {
            hasRoute = false
        }
    }
}