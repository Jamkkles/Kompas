//
//  CreateEventView.swift
//  Kompas
//
//  Created by Pablo Correa Mella on 12-10-25.
//

// CreateEventView.swift

import SwiftUI
import MapKit

struct Place: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D

    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }

    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct CreateEventView: View {
    @State private var selectedPlace: Place? = nil
    @State private var showPlacePicker = false
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    @State private var selectedTime: Date = Date()
    @State private var showTimePicker = false

    @State private var descriptionText: String = ""
    @FocusState private var isEditingDescription: Bool
    @State private var participants: [String] = ["José Díaz"]
    @State private var showAddParticipant: Bool = false
    @State private var newParticipantName: String = ""

    private let places: [Place] = [
        Place(name: "Taqueria Maria", coordinate: CLLocationCoordinate2D(latitude: 37.7880, longitude: -122.4074)),
        Place(name: "Café Buena Vista", coordinate: CLLocationCoordinate2D(latitude: 37.8067, longitude: -122.4200)),
        Place(name: "Parque Dolores", coordinate: CLLocationCoordinate2D(latitude: 37.7596, longitude: -122.4269)),
        Place(name: "Ferry Building", coordinate: CLLocationCoordinate2D(latitude: 37.7955, longitude: -122.3937))
    ]

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7880, longitude: -122.4074), // SF MOMA area
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_CL")
        df.dateStyle = .long
        df.timeStyle = .none
        return df
    }
    
    private var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_CL")
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }

    var body: some View {
        VStack(spacing: 0) {
            Map(coordinateRegion: $region)
                .frame(height: UIScreen.main.bounds.height / 3)
                .onChange(of: selectedPlace) { _, newValue in
                    if let place = newValue {
                        withAnimation {
                            region.center = place.coordinate
                        }
                    }
                }
            
            // Formulario para crear el evento
            VStack(alignment: .leading, spacing: 16) {
                Text("Crear evento").font(.title2.bold())
                Text("Agregar descripción").foregroundColor(.accentColor)
                
                Divider()
                
                HStack {
                    Text("Destino")
                    Spacer()
                    Button(action: { showPlacePicker = true }) {
                        HStack(spacing: 6) {
                            Text(selectedPlace?.name ?? "Seleccionar…")
                                .foregroundColor(.accentColor)
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                HStack {
                    Text("Día")
                    Spacer()
                    Button(action: { showDatePicker = true }) {
                        HStack(spacing: 6) {
                            Text(dateFormatter.string(from: selectedDate))
                                .foregroundColor(.accentColor)
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                HStack {
                    Text("Hora")
                    Spacer()
                    Button(action: { showTimePicker = true }) {
                        HStack(spacing: 6) {
                            Text(timeFormatter.string(from: selectedTime))
                                .foregroundColor(.accentColor)
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()

                HStack {
                    Text("Participantes").fontWeight(.bold)
                    Spacer()
                    Button {
                        newParticipantName = ""
                        showAddParticipant = true
                    } label: {
                        Label("Agregar", systemImage: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }

                if participants.isEmpty {
                    Text("Sin participantes").foregroundColor(.secondary)
                } else {
                    ForEach(participants, id: \.self) { name in
                        HStack {
                            Image(systemName: "person.fill").foregroundColor(.gray)
                            Text(name)
                            Spacer()
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let idx = participants.firstIndex(of: name) {
                                    participants.remove(at: idx)
                                }
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
                }

                Spacer()

                Button(action: {}) {
                    Text("Crear evento")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground)) // Se adapta al modo claro/oscuro
        }
        .sheet(isPresented: $showAddParticipant) {
            NavigationView {
                Form {
                    Section(footer: Text("Ingresa el nombre del participante")) {
                        TextField("Nombre", text: $newParticipantName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(false)
                            .submitLabel(.done)
                    }
                }
                .navigationTitle("Nuevo participante")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showAddParticipant = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Agregar") {
                            let trimmed = newParticipantName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                participants.append(trimmed)
                            }
                            showAddParticipant = false
                        }
                        .disabled(newParticipantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.fraction(0.3), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPlacePicker) {
            NavigationView {
                List(places) { place in
                    Button(action: {
                        selectedPlace = place
                        region.center = place.coordinate
                        showPlacePicker = false
                    }) {
                        HStack {
                            Text(place.name)
                            Spacer()
                            if place == selectedPlace {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .navigationTitle("Seleccionar destino")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cerrar") { showPlacePicker = false }
                    }
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        DatePicker(
                            "Seleccionar día",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
                .ignoresSafeArea(.keyboard)
                .navigationTitle("Elegir día")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Listo") { showDatePicker = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTimePicker) {
            NavigationView {
                VStack(alignment: .leading) {
                    DatePicker(
                        "Seleccionar hora",
                        selection: $selectedTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()

                    Spacer()
                }
                .navigationTitle("Elegir hora")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Listo") { showTimePicker = false }
                    }
                }
            }
            .presentationDetents([.fraction(0.35), .medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if selectedPlace == nil {
                selectedPlace = places.first
                if let place = selectedPlace {
                    region.center = place.coordinate
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    CreateEventView()
}
