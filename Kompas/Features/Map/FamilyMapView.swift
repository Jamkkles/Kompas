import SwiftUI
import MapKit

// Modelo simple para un miembro de la familia.
struct FamilyMember: Identifiable {
    let id = UUID()
    let name: String
    let locationInfo: String
    let coordinate: CLLocationCoordinate2D
}

struct FamilyMapView: View {
    @EnvironmentObject var locationManager: LocationManager

    @State private var camera: MapCameraPosition = .automatic
    @State private var fallbackRegion: MKCoordinateRegion = .init(
        center: CLLocationCoordinate2D(latitude: -34.985, longitude: -71.239),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    // Datos de ejemplo
    private let members: [FamilyMember] = [
        .init(
            name: "Mamá",
            locationInfo: "Casa",
            coordinate: CLLocationCoordinate2D(latitude: -34.985, longitude: -71.239)
        ),
        .init(
            name: "Papá",
            locationInfo: "Trabajo",
            coordinate: CLLocationCoordinate2D(latitude: -34.98, longitude: -71.25)
        )
    ]

    var body: some View {
        ZStack {
            Map(position: $camera) {
                ForEach(members) { member in
                    Annotation(member.name, coordinate: member.coordinate) {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Brand.tint)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text(initials(member.name))
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                )
                            Image(systemName: "triangle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Brand.tint)
                                .rotationEffect(.degrees(180))
                                .offset(y: -6)
                        }
                    }
                }
            }
            .ignoresSafeArea()

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mi familia")
                            .font(.headline)
                        Text("Ejemplo de vista de mapa familiar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                .padding()

                Spacer()
            }
        }
        .onAppear {
            if let coord = locationManager.userLocation {
                camera = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                    )
                )
            } else {
                camera = .region(fallbackRegion)
            }
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? Substring("")
        let second = parts.dropFirst().first?.prefix(1) ?? Substring("")
        let result = "\(first)\(second)"
        return result.isEmpty ? String(name.prefix(2)) : result
    }
}

#Preview {
    FamilyMapView()
        .environmentObject(LocationManager())
}
