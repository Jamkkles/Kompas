import SwiftUI

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
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView()
            }
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
                    Text(event.title).font(.headline)
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
