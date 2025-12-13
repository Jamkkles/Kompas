import SwiftUI

struct EventImageSheet: View {
    let photoBase64: String?
    @Environment(\.dismiss) var dismiss

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
