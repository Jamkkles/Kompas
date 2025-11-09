import SwiftUI

struct Group: Identifiable {
    let id = UUID()
    let name: String
    let members: [String]
    let lastUpdate: String
    let color: Color
    
    var memberCount: Int { members.count }
}

struct GroupsView: View {
    @State private var searchText = ""
    
    let groups = [
        Group(
            name: "Familia",
            members: ["Mamá", "Papá", "Hermana"],
            lastUpdate: "12:09",
            color: .blue
        ),
        Group(
            name: "Amigos",
            members: ["Pablo", "Nelson", "José"],
            lastUpdate: "12:09",
            color: .green
        ),
        Group(
            name: "Trabajo",
            members: ["Compañero 1", "Compañero 2"],
            lastUpdate: "04:50",
            color: .orange
        )
    ]
    
    var filteredGroups: [Group] {
        if searchText.isEmpty {
            return groups
        }
        return groups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredGroups) { group in
                            GroupCard(group: group)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Grupos")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Buscar grupos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Acción para crear nuevo grupo
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
    }
}

struct GroupCard: View {
    let group: Group
    
    var body: some View {
        NavigationLink {
            GroupDetailView(group: group)
        } label: {
            HStack(spacing: 16) {
                // Ícono del grupo
                ZStack {
                    Circle()
                        .fill(group.color.gradient)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                // Información del grupo
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("\(group.memberCount) miembros")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Hora y chevron
                VStack(alignment: .trailing, spacing: 4) {
                    Text(group.lastUpdate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// Vista de detalle del grupo
struct GroupDetailView: View {
    let group: Group
    
    var body: some View {
        List {
            Section {
                ForEach(group.members, id: \.self) { member in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(group.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(member.prefix(1).uppercased())
                                    .font(.headline)
                                    .foregroundStyle(group.color)
                            )
                        
                        Text(member)
                            .font(.body)
                        
                        Spacer()
                        
                        Button {
                            // Acción de mensaje
                        } label: {
                            Image(systemName: "message.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            } header: {
                Text("Miembros")
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        // Acción
                    } label: {
                        Label("Agregar miembro", systemImage: "person.badge.plus")
                    }
                    
                    Button {
                        // Acción
                    } label: {
                        Label("Editar grupo", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        // Acción
                    } label: {
                        Label("Salir del grupo", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

#Preview {
    GroupsView()
}
