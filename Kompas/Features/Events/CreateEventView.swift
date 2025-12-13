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
                            showingImagePicker = true
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
                                if let inputImage = inputImage, let imageData = inputImage.jpegData(compressionQuality: 0.8) {
                                    photoBase64 = imageData.base64EncodedString()
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
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
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
