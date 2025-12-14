import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var name: String
    @State private var inputImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var originalName: String 

    init(user: User) {
        _name = State(initialValue: user.name)
        _originalName = State(initialValue: user.name)
    }

    private var hasChanges: Bool {
        name != originalName || inputImage != nil
    }

    var body: some View {
        Form {
            Section(header: Text("Foto de Perfil")) {
                VStack(alignment: .center, spacing: 12) {
                    // Vista previa de foto
                    if let inputImage = inputImage {
                        Image(uiImage: inputImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Brand.tint, lineWidth: 2))
                            .shadow(radius: 4)
                    } else if let photoURL = session.user?.photoURL {
                        AsyncImage(url: photoURL) { image in
                            image.resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Brand.tint, lineWidth: 2))
                        .shadow(radius: 4)
                    } else {
                        Circle()
                            .fill(Brand.tint.opacity(0.15))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text(session.user?.name.prefix(1).uppercased() ?? "A")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(Brand.tint)
                            )
                            .overlay(Circle().stroke(Brand.tint, lineWidth: 2))
                    }

                    Button {
                        showingImagePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.fill")
                            Text("Galería")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Brand.tint, in: Capsule())
                    }
                    .disabled(true)
                    .opacity(0.5)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
            }

            Section(header: Text("Nombre")) {
                TextField("Tu nombre completo", text: $name)
                    .textInputAutocapitalization(.words)
            }

            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Editar Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if hasChanges {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await saveProfile() }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage, sourceType: .photoLibrary)
        }
    }

    @MainActor
    private func saveProfile() async {
        guard let user = session.user else { return }
        isSaving = true
        errorMessage = nil
        
        defer { isSaving = false }

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
            originalName = name 
            if photoBase64 != nil {
                if let updatedUser = try? await FirebaseAuthRepository.shared.me() {
                    session.user = updatedUser
                }
            }
            dismiss()
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }

    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

#Preview {
    NavigationView {
        EditProfileView(user: User(id: "test", email: "test@test.com", name: "Test User", photoURL: nil))
            .environmentObject(SessionStore.shared)
    }
}