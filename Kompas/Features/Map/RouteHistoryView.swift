import SwiftUI

struct Route: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let distance: Double
}

struct RouteHistoryView: View {
    let routes: [Route] = [
        Route(name: "Ruta al trabajo", date: Date().addingTimeInterval(-86400), distance: 12.5),
        Route(name: "Caminata al parque", date: Date().addingTimeInterval(-172800), distance: 3.2),
        Route(name: "Viaje al centro", date: Date().addingTimeInterval(-259200), distance: 8.7)
    ]

    var body: some View {
        NavigationView {
            List(routes) { route in
                VStack(alignment: .leading) {
                    Text(route.name)
                        .font(.headline)
                    Text("\(route.date, format: .dateTime.day().month().year()) - \(String(format: "%.1f", route.distance)) km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Historial de Rutas")
        }
    }
}

#Preview {
    RouteHistoryView()
}