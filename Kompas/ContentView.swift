//  ContentView.swift
//  Kompas
//
//  Created by Pablo Correa Mella on 12-10-25.
//

import SwiftUI

struct ContentView: View {
    // Esta variable simple controlará si el usuario ha iniciado sesión.
    // En una app real, esto sería más complejo (guardarías el estado del usuario).
    @State private var isLoggedIn = false
    
    @StateObject private var locationManager = LocationManager()
    var body: some View {
        if isLoggedIn {
            // Si el usuario ya inició sesión, muestra la vista principal con las pestañas.
            
            MainAppView()
                .environmentObject(locationManager)
        } else {
            // Si no, muestra la pantalla de inicio de sesión.
            // Pasamos 'isLoggedIn' para que LoginView pueda cambiar su valor.
            LoginView(isLoggedIn: $isLoggedIn)
                .environmentObject(locationManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
}
