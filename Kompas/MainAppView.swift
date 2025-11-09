import SwiftUI
import MapKit

struct MainAppView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MapHomeView()
                .tabItem { Label("Mapa", systemImage: "map.fill") }
                .tag(0)

            GroupsView()
                .tabItem { Label("Grupos", systemImage: "person.2.fill") }
                .tag(1)

            EventsView()
                .tabItem { Label("Eventos", systemImage: "calendar") }
                .tag(2)

            ProfileView()
                .tabItem { Label("Perfil", systemImage: "person.circle.fill") }
                .tag(3)
        }
        .tint(.blue)
    }
}

// MARK: - Vista Principal del Mapa (sin botones flotantes)
struct MapHomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var locationManager: LocationManager

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -34.9833, longitude: -71.2333),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var hasCenteredMap = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Mapa
            Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea()

            // Header superior
            VStack {
                HStack {
                    // Botón / avatar de perfil
                    NavigationLink { ProfileView() } label: {
                        if let user = session.user {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .cyan],
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(user.name.prefix(1).uppercased())
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                        } else {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                                .overlay(Image(systemName: "person.fill").foregroundStyle(.primary))
                        }
                    }

                    Spacer()

                    // Logo central
                    Text("Kompas")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())

                    Spacer()

                    // (Opcional) ícono notificaciones
                    Button {} label: {
                        Image(systemName: "bell.fill")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // Panel inferior estilo “menú” con material translúcido
            WelcomePanel()
                .padding(.horizontal)
                .padding(.bottom, 12)
        }
        .onChange(of: locationManager.userLocation) { newLocation in
            if let newLocation, !hasCenteredMap {
                region.center = newLocation
                hasCenteredMap = true
            }
        }
    }
}

// MARK: - Panel inferior (resumen / “Hola, ¿a dónde vamos hoy?”)
struct WelcomePanel: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let user = session.user {
                        Text("Hola, \(user.name.components(separatedBy: " ").first ?? user.name)")
                            .font(.title3.bold())
                    } else {
                        Text("Hola")
                            .font(.title3.bold())
                    }
                    Text("¿A dónde vamos hoy?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Resumen (placeholder por ahora)
            HStack(spacing: 12) {
                SummaryPill(icon: "person.2.fill", value: "5", label: "Grupos", color: .blue)
                SummaryPill(icon: "calendar", value: "3", label: "Eventos", color: .orange)
                SummaryPill(icon: "mappin.circle.fill", value: "12", label: "Lugares", color: .green)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial) // opacidad/blur estilo Apple
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
    }
}

struct SummaryPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.headline).foregroundStyle(color)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(color.opacity(0.1)))
    }
}

// MARK: - Vista de Eventos (igual que antes)
struct EventsView: View {
    @State private var showingCreateEvent = false

    let upcomingEvents = [
        EventItem(title: "Almuerzo Familiar", date: Date().addingTimeInterval(3600),
                  location: "Taquería María", participants: 5, color: .blue),
        EventItem(title: "Reunión Amigos", date: Date().addingTimeInterval(86400),
                  location: "Plaza de Armas", participants: 8, color: .green),
        EventItem(title: "Compras", date: Date().addingTimeInterval(172800),
                  location: "Mall Paseo Curicó", participants: 3, color: .orange)
    ]

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Próximos Eventos").font(.title2.bold()).padding(.horizontal)
                            ForEach(upcomingEvents) { event in
                                EventCard(event: event)
                            }
                        }
                        .padding(.top)
                    }
                    .padding(.horizontal)
                }
                // Deja el botón para crear evento si lo quieres aquí; puedes quitarlo si no.
                Button { showingCreateEvent = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(.blue.gradient))
                        .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
                }
                .padding()
            }
            .navigationTitle("Eventos")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateEvent) { CreateEventView() }
        }
    }
}

struct EventItem: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let location: String
    let participants: Int
    let color: Color
}

struct EventCard: View {
    let event: EventItem
    var body: some View {
        NavigationLink {
            Text("Detalle del evento: \(event.title)")
        } label: {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(event.date, format: .dateTime.day())
                        .font(.title.bold())
                        .foregroundStyle(event.color)
                    Text(event.date, format: .dateTime.month(.abbreviated))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 60)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(event.color.opacity(0.1)))

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title).font(.headline).foregroundStyle(.primary)
                    HStack(spacing: 12) {
                        Label(event.location, systemImage: "mappin.circle.fill")
                        Label("\(event.participants)", systemImage: "person.2.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground)))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Perfil (igual que antes)
struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            if let user = session.user {
                                Circle()
                                    .fill(LinearGradient(colors: [.blue, .cyan],
                                                         startPoint: .topLeading,
                                                         endPoint: .bottomTrailing))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text(user.name.prefix(1).uppercased())
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundStyle(.white)
                                    )
                                    .shadow(color: .blue.opacity(0.3), radius: 15, y: 8)
                                Text(user.name).font(.title2.bold())
                                Text(user.email).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 20)

                        // Opciones
                        VStack(spacing: 0) {
                            ProfileOption(icon: "person.fill", title: "Editar Perfil", color: .blue)
                            Divider().padding(.leading, 60)
                            ProfileOption(icon: "bell.fill", title: "Notificaciones", color: .orange)
                            Divider().padding(.leading, 60)
                            ProfileOption(icon: "lock.fill", title: "Privacidad", color: .purple)
                            Divider().padding(.leading, 60)
                            ProfileOption(icon: "gear", title: "Configuración", color: .gray)
                        }
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                        .padding(.horizontal)

                        Button {
                            showingLogoutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Cerrar Sesión").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(.red.opacity(0.1)))
                            .foregroundStyle(.red)
                        }
                        .padding(.horizontal)

                        Text("Versión 1.0.0").font(.caption).foregroundStyle(.tertiary).padding(.bottom)
                    }
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Cerrar Sesión", isPresented: $showingLogoutAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar Sesión", role: .destructive) { Task { await session.logout() } }
            } message: { Text("¿Estás seguro de que quieres cerrar sesión?") }
        }
    }
}

struct ProfileOption: View {
    let icon: String
    let title: String
    let color: Color
    var body: some View {
        Button {} label: {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.title3).foregroundStyle(color).frame(width: 28)
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainAppView()
        .environmentObject(SessionStore.shared)
        .environmentObject(LocationManager())
}
