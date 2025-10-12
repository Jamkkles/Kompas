//
//  CreateEventView.swift
//  Kompas
//
//  Created by Pablo Correa Mella on 12-10-25.
//

// CreateEventView.swift

import SwiftUI
import MapKit

struct CreateEventView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7880, longitude: -122.4074), // SF MOMA area
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        VStack(spacing: 0) {
            Map(coordinateRegion: $region)
                .frame(height: UIScreen.main.bounds.height / 3)
            
            // Formulario para crear el evento
            VStack(alignment: .leading, spacing: 16) {
                Text("Crear evento").font(.title2.bold())
                Text("Agregar descripción").foregroundColor(.accentColor)
                
                Divider()
                
                HStack {
                    Text("Taqueria Maria")
                    Spacer()
                }
                
                HStack {
                    Text("Día")
                    Spacer()
                    Text("22 de septiembre").foregroundColor(.gray)
                }
                
                HStack {
                    Text("Hora")
                    Spacer()
                    Text("16:00 horas").foregroundColor(.gray)
                }
                
                Divider()
                
                Text("Participantes").fontWeight(.bold)
                Text("José Díaz")
                
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
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    CreateEventView()
}
