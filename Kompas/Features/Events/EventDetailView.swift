import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: EventsViewModel
    @State var event: EventItem
    @State private var showRoute = false

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
                Button("Ir a evento") {
                    showRoute = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
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