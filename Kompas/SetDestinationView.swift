//
//  SetDestinationView.swift
//  Kompas
//
//  Created by Pablo Correa Mella on 12-10-25.
//

// SetDestinationView.swift

import SwiftUI
import MapKit

struct SetDestinationView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7577, longitude: -122.4376),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region).ignoresSafeArea()
            
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
    }
}

#Preview {
    SetDestinationView()
}
