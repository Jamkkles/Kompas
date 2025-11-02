//
//  CreateEventView.swift
//  Kompas
//
//  Created by Pablo Correa Mella on 12-10-25.
//

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
    
    // 1. CONECTA CON EL GPS (tiempo real)
    @EnvironmentObject var locationManager: LocationManager
    
    // 2. REGIÓN DEL MAPA (Sintaxis Moderna)
    // Usamos @State private var position para controlar el mapa
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -34.9833, longitude: -71.2333), // Centro inicial (Curicó)
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    
    // Variable para centrar el mapa solo una vez
    @State private var hasCenteredMap = false
    
    // 3. DATOS DEL FORMULARIO (vacíos para personalizar)
    @State private var eventName: String = ""
    @State private var eventDescription: String = ""
    @State private var eventDate: Date = Date()
    @State private var eventParticipants: String = ""
    
    // 4. UBICACIÓN DEL EVENTO (el pin que pones al tocar)
    @State private var eventCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // 5. MAPREADER (para detectar toques)
                MapReader { proxy in
                    
                    // 6. EL MAPA (SINTAXIS CORREGIDA)
                    // Usamos Map(position: $position) que SÍ acepta un bloque de contenido
                    Map(position: $position) {
                        
                        // Muestra el punto azul de tu ubicación
                        UserAnnotation()
                        
                        // Dibuja el pin del evento SI el usuario ha tocado
                        if let coordinate = eventCoordinate {
                            Annotation("Nuevo Evento", coordinate: coordinate) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .onTapGesture { tapPosition in
                        // 7. LÓGICA DEL TOQUE
                        if let coordinate = proxy.convert(tapPosition, from: .local) {
                            eventCoordinate = coordinate // Guarda la coordenada
                            if eventName.isEmpty {
                                eventName = "Nuevo Evento" // Pone un nombre por defecto
                            }
                        }
                    }
                }
                .frame(height: UIScreen.main.bounds.height / 3)
                
                // 8. FORMULARIO PERSONALIZABLE
                Form {
                    Section(header: Text("Detalles del Evento")) {
                        TextField("Nombre del evento", text: $eventName)
                        TextField("Descripción (opcional)", text: $eventDescription)
                        DatePicker("Fecha y Hora", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    Section(header: Text("Participantes")) {
                        TextField("Añadir participantes", text: $eventParticipants)
                    }
                    
                    Section {
                        Button(action: {
                            // Lógica para guardar
                            print("Guardando evento: \(eventName)")
                        }) {
                            Text("Crear evento")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .disabled(eventCoordinate == nil) // Desactivado si no hay pin
                    }
                }
            }
            .navigationTitle("Crear Evento")
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: locationManager.userLocation) { newLocation in
                // 9. LÓGICA DE TIEMPO REAL
                // Centra la "posición" del mapa (solo la primera vez)
                if let newLocation, !hasCenteredMap {
                    position = .region(MKCoordinateRegion(
                        center: newLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                    hasCenteredMap = true
                }
            }
        }
    }
}

#Preview {
    CreateEventView()
        .environmentObject(LocationManager()) // No olvides el environmentObject para el Preview
}
