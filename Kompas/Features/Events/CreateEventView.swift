import SwiftUI
import MapKit
import Combine

struct CreateEventView: View {
    @StateObject private var viewModel: CreateEventViewModel
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    @State private var eventDate = Date()
    @State private var eventTime = Date()
    @State private var selectedIcon: EventIcon = .calendar

    @State private var inputImage: UIImage?
    @State private var showingImagePicker = false

    // Importante: cámara en fullScreenCover para evitar que “aparezca arriba”
    @State private var showingCamera = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary

    @State private var showingSourceDialog = false
    @State private var showMediaError = false
    @State private var mediaErrorMessage = ""

    // Mapa
    @State private var hasCenteredMap = false

    init(session: SessionStore, initialCoordinate: CLLocationCoordinate2D? = nil) {
        let vm = CreateEventViewModel(session: session, initialCoordinate: initialCoordinate)
        _viewModel = StateObject(wrappedValue: vm)
        _hasCenteredMap = State(initialValue: initialCoordinate != nil)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo: mapa full screen
                mapView
                    .ignoresSafeArea()

                // Overlay sutil arriba para legibilidad (estética)
                LinearGradient(
                    colors: [Color.black.opacity(0.25), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                // Card inferior estilo app
                VStack(spacing: 12) {
                    Spacer()

                    VStack(spacing: 12) {
                        // Handle
                        Capsule()
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        VStack(spacing: 10) {
                            field(title: "Nombre del evento") {
                                TextField("Ej: Cumpleaños, Asado, Reunión…", text: $viewModel.eventName)
                                    .textInputAutocapitalization(.words)
                            }

                            field(title: "Participantes") {
                                TextField("Separados por coma", text: $viewModel.eventParticipants)
                                    .textInputAutocapitalization(.never)
                            }

                            HStack(spacing: 12) {
                                DatePicker("Fecha", selection: $eventDate, displayedComponents: .date)
                                DatePicker("Hora", selection: $eventTime, displayedComponents: .hourAndMinute)
                            }
                            .font(.footnote)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))

                            Picker("Icono", selection: $selectedIcon) {
                                ForEach(EventIcon.allCases, id: \.self) { icon in
                                    Image(systemName: icon.symbolName).tag(icon)
                                }
                            }
                            .pickerStyle(.segmented)

                            Button {
                                showingSourceDialog = true
                            } label: {
                                Label(inputImage == nil ? "Agregar foto" : "Cambiar foto", systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Brand.tint)

                            if let inputImage {
                                Image(uiImage: inputImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 140)
                                    .clipped()
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            }

                            Button {
                                Task {
                                    let calendar = Calendar.current
                                    let d = calendar.dateComponents([.year, .month, .day], from: eventDate)
                                    let t = calendar.dateComponents([.hour, .minute], from: eventTime)

                                    var comp = DateComponents()
                                    comp.year = d.year
                                    comp.month = d.month
                                    comp.day = d.day
                                    comp.hour = t.hour
                                    comp.minute = t.minute

                                    var photoBase64: String? = nil
                                    if let inputImage {
                                        let resized = resizeImage(image: inputImage, targetSize: CGSize(width: 1024, height: 1024))
                                        if let data = resized.jpegData(compressionQuality: 0.55) {
                                            photoBase64 = data.base64EncodedString()
                                        }
                                    }

                                    if let combinedDate = calendar.date(from: comp) {
                                        await viewModel.saveEvent(date: combinedDate, icon: selectedIcon, photoBase64: photoBase64)
                                    }
                                    dismiss()
                                }
                            } label: {
                                Label("Guardar evento", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Brand.tint)
                            .disabled(viewModel.eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.eventCoordinate == nil)
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 14)
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
            }
            .navigationTitle("Nuevo evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            // Librería (sheet ok)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage, sourceType: pickerSourceType)
                    .ignoresSafeArea()
            }
            // Cámara (full screen para que NO quede arriba)
            .fullScreenCover(isPresented: $showingCamera) {
                ImagePicker(image: $inputImage, sourceType: .camera)
                    .ignoresSafeArea()
            }
            .confirmationDialog("Seleccionar foto", isPresented: $showingSourceDialog, titleVisibility: .visible) {
                Button("Cámara") { openCamera() }
                Button("Librería de fotos") { openLibrary() }
                Button("Cancelar", role: .cancel) { }
            }
            .alert("Foto", isPresented: $showMediaError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(mediaErrorMessage)
            }
        }
        .tint(Brand.tint)
        .onAppear {
            if let coord = viewModel.eventCoordinate {
                viewModel.camera = .region(
                    MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                )
                hasCenteredMap = true
            }
        }
        .onReceive(
            locationManager.$userLocation
                .compactMap { $0 }
                .removeDuplicates(by: { a, b in a.latitude == b.latitude && a.longitude == b.longitude })
        ) { coord in
            if !hasCenteredMap {
                hasCenteredMap = true
                if viewModel.eventCoordinate == nil {
                    viewModel.eventCoordinate = coord
                    viewModel.camera = .region(
                        MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06))
                    )
                }
            }
        }
    }

    // MARK: - UI helpers

    private func field<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            content()
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
        }
    }

    // MARK: - Media actions

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            mediaErrorMessage = "Este dispositivo no tiene cámara disponible (o estás en el Simulator)."
            showMediaError = true
            return
        }
        // iOS mostrará el prompt si falta permiso, pero si falta Info.plist se cae.
        showingCamera = true
    }

    private func openLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            mediaErrorMessage = "No se puede abrir la librería de fotos."
            showMediaError = true
            return
        }
        pickerSourceType = .photoLibrary
        showingImagePicker = true
    }

    // MARK: - Map

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
        }
    }

    // MARK: - Image resize

    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scale = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
    }
}
