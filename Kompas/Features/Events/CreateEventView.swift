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
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingSourceTypeActionSheet = false

    // Estado del mapa
    @State private var hasCenteredMap = false

    // changed code: aceptar coordenada inicial opcional y prellenar el viewModel
    init(session: SessionStore, initialCoordinate: CLLocationCoordinate2D? = nil) {
        // Crear la instancia del ViewModel antes de instalar el StateObject
        let vm = CreateEventViewModel(session: session, initialCoordinate: initialCoordinate)
        _viewModel = StateObject(wrappedValue: vm)
        _hasCenteredMap = State(initialValue: initialCoordinate != nil)
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
                        
                        DatePicker("Fecha", selection: $eventDate, displayedComponents: .date)
                        DatePicker("Hora", selection: $eventTime, displayedComponents: .hourAndMinute)
                        
                        Picker("Icono", selection: $selectedIcon) {
                            ForEach(EventIcon.allCases, id: \.self) { icon in
                                Image(systemName: icon.symbolName).tag(icon)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        // Image Picker Button
                        Button {
                            showingSourceTypeActionSheet = true
                        } label: {
                            Label("Seleccionar Foto", systemImage: "photo.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        // Selected Image Thumbnail
                        if let inputImage = inputImage {
                            Image(uiImage: inputImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(8)
                        }

                        Button {
                            Task {
                                let calendar = Calendar.current
                                let dateComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
                                let timeComponents = calendar.dateComponents([.hour, .minute], from: eventTime)
                                
                                var combinedComponents = DateComponents()
                                combinedComponents.year = dateComponents.year
                                combinedComponents.month = dateComponents.month
                                combinedComponents.day = dateComponents.day
                                combinedComponents.hour = timeComponents.hour
                                combinedComponents.minute = timeComponents.minute
                                
                                var photoBase64: String? = nil
                                if let inputImage = inputImage {
                                    let resizedImage = resizeImage(image: inputImage, targetSize: CGSize(width: 1024, height: 1024))
                                    if let imageData = resizedImage.jpegData(compressionQuality: 0.5) {
                                        photoBase64 = imageData.base64EncodedString()
                                    }
                                }

                                if let combinedDate = calendar.date(from: combinedComponents) {
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
                        .disabled(viewModel.eventName.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.eventCoordinate == nil)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .padding()
                }
            }
            .navigationTitle("Nuevo evento")
            .navigationBarTitleDisplayMode(.inline)
                       .toolbar {
               ToolbarItem(placement: .cancellationAction) {
                   Button("Cancelar") {
                       dismiss()
                   }
               }
           }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage, sourceType: imagePickerSourceType)
            }
            .actionSheet(isPresented: $showingSourceTypeActionSheet) {
                ActionSheet(title: Text("Seleccionar origen de la foto"), buttons: [
                    .default(Text("Cámara")) {
                        imagePickerSourceType = .camera
                        showingImagePicker = true
                    },
                    .default(Text("Librería de Fotos")) {
                        imagePickerSourceType = .photoLibrary
                        showingImagePicker = true
                    },
                    .cancel()
                ])
            }
        }
        // <-- changed code: asegurar que si ya hay coordenada precargada, el mapa se centra al aparecer
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
                .removeDuplicates(by: { a, b in
                    a.latitude == b.latitude && a.longitude == b.longitude })
        ) { coord in
            // Centramos solo una vez al obtener la ubicación
            if !hasCenteredMap {
                hasCenteredMap = true
                // No sobrescribir si ya hay una coordenada inicial (p. ej. desde búsqueda)
                if viewModel.eventCoordinate == nil {
                    viewModel.eventCoordinate = coord
                    viewModel.camera = .region(
                        MKCoordinateRegion(center: coord,
                                           span: MKCoordinateSpan(latitudeDelta: 0.06,
                                                                   longitudeDelta: 0.06))
                    )
                }
            }
        }
    }

    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Determine what our actual size should be
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
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
