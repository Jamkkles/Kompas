import SwiftUI
import MapKit

struct SetDestinationView: View {
    
    // 1. <-- MODIFICACIÓN: Leemos el LocationManager desde el entorno
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -34.9833, longitude: -71.2333), // Curicó
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    // 2. <-- MODIFICACIÓN: Variable para centrar el mapa solo una vez
    @State private var hasCenteredMap = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // 3. <-- MODIFICACIÓN: Añadimos 'showsUserLocation: true'
            Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea()
            
            // Tarjeta de información inferior
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Taqueria Maria").font(.title2.bold())
                    Spacer()
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }
                Text("Estado 370, Curicó").foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "face.smiling")
                    Text("Recomendado")
                }
                .font(.caption)
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(15)

                Button(action: {}) {
                    Text("Fijar destino")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
            .padding(20)
            .background(.thinMaterial)
            .cornerRadius(20)
            .padding()
        }
        // 4. <-- MODIFICACIÓN: Observamos cambios en la ubicación
        .onChange(of: locationManager.userLocation) { newLocation in
            if let newLocation, !hasCenteredMap {
                region.center = newLocation
                hasCenteredMap = true
            }
        }
    }
}

#Preview {
    SetDestinationView()
        // 5. <-- MODIFICACIÓN: Añadimos un manager de prueba al Preview
        .environmentObject(LocationManager())
}
