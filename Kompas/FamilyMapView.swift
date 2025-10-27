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
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -35.02215137264192, longitude: -71.2375557705796), // Curicó
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    let members = [
        FamilyMember(name: "Benjamín Puebla", locationInfo: "Curicó • Batería", coordinate: .init(latitude: -34.97421747130357, longitude: -71.23060052963186)),
        FamilyMember(name: "José Díaz", locationInfo: "Santiago • Batería", coordinate: .init(latitude: -34.99077925554075, longitude: -71.24494371375613)),
        FamilyMember(name: "Pablo Correa", locationInfo: "Romeral • Batería", coordinate: .init(latitude: -34.95671844493942, longitude: -71.12495151842457))
    ]

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $region, annotationItems: members) { member in
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
        }
    }
}

#Preview {
    FamilyMapView()
        .preferredColorScheme(.dark)
}
