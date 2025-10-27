//
//  FamilyMapView.swift
//  Kompas
//
//  Created by Pablo Correa Mella on 12-10-25.
//

// FamilyMapView.swift

import SwiftUI
import MapKit

// Modelo para un miembro de la familia.
struct FamilyMember: Identifiable {
    let id = UUID()
    let name: String
    let locationInfo: String
    let coordinate: CLLocationCoordinate2D
}

struct FamilyMapView: View {
    
    // 1. <-- MODIFICACIÓN: Leemos el LocationManager desde el entorno
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var region = MKCoordinateRegion(
        // Damos un valor inicial cualquiera, se centrará automáticamente
        center: CLLocationCoordinate2D(latitude: -34.9833, longitude: -71.2333), // Curicó
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // 2. <-- MODIFICACIÓN: Variable para centrar el mapa solo una vez
    @State private var hasCenteredMap = false
    
    let members = [
        FamilyMember(name: "Benjamín Puebla", locationInfo: "Curicó • Batería", coordinate: .init(latitude: -34.98, longitude: -71.23)),
        FamilyMember(name: "José Díaz", locationInfo: "Santiago • Batería", coordinate: .init(latitude: -33.45, longitude: -70.66)),
        FamilyMember(name: "Pablo Correa", locationInfo: "Romeral • Batería", coordinate: .init(latitude: -34.96, longitude: -71.20))
    ]

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // 3. <-- MODIFICACIÓN: Añadimos 'showsUserLocation: true'
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: members) { member in
                    MapMarker(coordinate: member.coordinate, tint: .cyan)
                }
                .ignoresSafeArea()

                VStack {
                    Text("Familia")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.top, .horizontal])

                    List(members) { member in
                        HStack {
                            Image(systemName: "person.circle.fill").font(.largeTitle).foregroundColor(.gray)
                            VStack(alignment: .leading) {
                                Text(member.name).fontWeight(.semibold)
                                Text(member.locationInfo).font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "message.fill").foregroundColor(.gray)
                        }
                    }
                    .listStyle(.plain)
                }
                .frame(maxHeight: UIScreen.main.bounds.height / 2.5)
                .background(.regularMaterial) // Efecto translúcido
                .cornerRadius(20)
            }
            .navigationTitle("Familia")
            .navigationBarHidden(true)
            // 4. <-- MODIFICACIÓN: Observamos cambios en la ubicación
            .onChange(of: locationManager.userLocation) { newLocation in
                if let newLocation, !hasCenteredMap {
                    region.center = newLocation
                    hasCenteredMap = true
                }
            }
        }
    }
}

#Preview {
    FamilyMapView()
        .preferredColorScheme(.dark)
        // 5. <-- MODIFICACIÓN: Añadimos un manager de prueba al Preview
        .environmentObject(LocationManager())
}
