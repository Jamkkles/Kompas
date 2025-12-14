import SwiftUI
import MapKit

struct EventImageSheet: View {
    let photoBase64: String?
    let event: EventItem?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var eventsVM: EventsViewModel

    var body: some View {
        NavigationView {
            VStack {
                if let photoBase64 = photoBase64,
                   let imageData = Data(base64Encoded: photoBase64),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(8)
                } else {
                    Text("No hay imagen disponible para este evento.")
                        .foregroundColor(.gray)
                }

                // Botón Ir al evento
                if let event = event {
                    VStack(spacing: 12) {
                        // Botón Ver detalles
                        Button {
                            // Cerrar este sheet primero
                            dismiss()
                            
                            // Después de un pequeño delay, navegar al detalle
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ShowEventDetail"),
                                    object: event.id
                                )
                            }
                        } label: {
                            Label("Ver detalles", systemImage: "info.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(Brand.tint)
                        
                        // Botón Ir al evento
                        Button {
                            if let userLoc = locationManager.userLocation {
                                eventsVM.calculateRoute(for: event, from: userLoc)
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ShowEventRoute"),
                                    object: event.id
                                )
                                dismiss()
                            }
                        } label: {
                            Label("Ir al evento", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Brand.tint)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Imagen del Evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
