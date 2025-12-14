import SwiftUI
import MapKit

struct MainAppView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedTab = 0
    @StateObject private var eventsVM = EventsViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            // Nuevo mapa (el avanzado con selector de grupo, lupa, etc.)
            MapHomeView()
                .environmentObject(eventsVM)
                .tabItem {
                    Label("Mapa", systemImage: "map.fill")
                }
                .tag(0)

            GroupsView()
                .tabItem {
                    Label("Grupos", systemImage: "person.2.fill")
                }
                .tag(1)

            EventsView(selectedTab: $selectedTab)
                .environmentObject(eventsVM)
                .tabItem {
                    Label("Eventos", systemImage: "calendar")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.circle.fill")
                }
                .tag(3)
        }
        .tint(.blue)
        .environmentObject(locationManager) // Asegurarse de pasar el locationManager
    }
}

#Preview {
    MainAppView()
        .environmentObject(SessionStore.shared)
        .environmentObject(LocationManager())
}
