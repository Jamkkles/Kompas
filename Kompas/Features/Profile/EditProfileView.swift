import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var inputImage: UIImage?
    @State private var showingImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary

    init(user: User) {
        _name = State(initialValue: user.name)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Foto de Perfil")) {
                    VStack {
                        if let inputImage = inputImage {
                            Image(uiImage: inputImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.gray, lineWidth: 2))
                                .shadow(radius: 4)
                        } else if let photoURL = session.user?.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.gray, lineWidth: 2))
                                    .shadow(radius: 4)
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(Text("A").font(.largeTitle))
                        }

                        Button("Cambiar Foto") {
                            showingImagePicker = true
                        }
                        .padding(.top, 8)
                    }
                }

                Section(header: Text("Nombre")) {
                    TextField("Nombre", text: $name)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await saveProfile()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage, sourceType: imagePickerSourceType)
            }
        }
    }

    private func saveProfile() async {
        guard let user = session.user else { return }
        var photoBase64: String? = nil

        if let inputImage = inputImage {
            let resizedImage = resizeImage(image: inputImage, targetSize: CGSize(width: 300, height: 300))
            if let imageData = resizedImage.jpegData(compressionQuality: 0.8) {
                photoBase64 = imageData.base64EncodedString()
            }
        }

        do {
            try await FirebaseAuthRepository.shared.updateProfile(name: name, photoBase64: photoBase64)
            session.user?.name = name
            if let photoURL = photoBase64 {
                session.user?.photoURL = URL(string: photoURL)
            }
            dismiss()
        } catch {
            print("Error al guardar el perfil: \(error.localizedDescription)")
        }
    }

    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = CGSize(width: size.width * widthRatio, height: size.height * heightRatio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}