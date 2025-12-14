import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: EventsViewModel
    @EnvironmentObject var locationManager: LocationManager // Usar el environment object
    @State var event: EventItem
    @State private var showRoute = false
    
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
                    if let eventId = event.id, viewModel.eventRoutes[eventId] != nil {
                        Button("Cancelar ruta") {
                            withAnimation {
                                viewModel.clearRoute(for: eventId)
                            }
                            
                            // Notificar al mapa que se canceló la ruta
                            NotificationCenter.default.post(
                                name: NSNotification.Name("CancelEventRoute"),
                                object: eventId
                            )
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
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
        .sheet(isPresented: $showRoute) {
            EventRouteView(event: event)
        }
    }
}