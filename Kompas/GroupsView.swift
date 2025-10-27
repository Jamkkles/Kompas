//
//  GroupsView.swift
//  Kompas
//
//  Created by Pablo Correa Mella on 12-10-25.
//

import SwiftUI

// Modelo de datos para un Grupo
struct Group: Identifiable {
    let id = UUID()
    let name: String
    let members: String
    let lastUpdate: String
}

struct GroupsView: View {
    // Datos de ejemplo
    let groups = [
        Group(name: "Familia", members: "Mamá | Papá | Hermana", lastUpdate: "12:09"),
        Group(name: "Amigos", members: "Pablo | Nelson | José", lastUpdate: "12:09"),
        Group(name: "Trabajo", members: "Compañero 1 | Compañero 2", lastUpdate: "04:50")
    ]

    var body: some View {
        NavigationView {
            List(groups) { group in
                GroupRow(group: group)
                    .listRowBackground(Color.white)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle("Grupos")
            .background(Color.white)
        }
    }
}

// Vista para cada fila de la lista
struct GroupRow: View {
    let group: Group
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "person.2.fill")
                .font(.title2)
                .foregroundColor(.black)
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text(group.members)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(group.lastUpdate)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    GroupsView()
        .preferredColorScheme(.light)
}
