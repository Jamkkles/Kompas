//
//  MainAppView.swift
//  Kompas
//
//  Created by Pablo Correa Mella on 12-10-25.
//

// MainAppView.swift

import SwiftUI

struct MainAppView: View {
    init() {
        // Personaliza la apariencia de la barra de pestañas para que sea oscura.
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            GroupsView()
                .tabItem {
                    Label("Grupos", systemImage: "person.3.fill")
                }

            FamilyMapView()
                .tabItem {
                    Label("Mapa Familia", systemImage: "map.fill")
                }
            
            SetDestinationView()
                .tabItem {
                    Label("Destino", systemImage: "mappin.and.ellipse")
                }
            
            CreateEventView()
                .tabItem {
                    Label("Crear Evento", systemImage: "calendar.badge.plus")
                }
        }
        .tint(.white) // Color del ícono y texto seleccionado en la TabView.
    }
}

#Preview {
    MainAppView()
        .preferredColorScheme(.dark)
}
