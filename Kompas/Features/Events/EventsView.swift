import SwiftUI

import SwiftUI
import CoreLocation

struct EventsView: View {
    @State private var showingCreateEvent = false
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = EventsViewModel()

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Próximos Eventos").font(.title2.bold()).padding(.horizontal)
                            ForEach(viewModel.upcomingEvents) { event in
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
                CreateEventView(session: session)
            }
            .onAppear {
                viewModel.fetchEvents()
            }
        }
        .environmentObject(viewModel)
    }
}

struct EventCard: View {
    let event: EventItem
    @State private var placemark: CLPlacemark?

    var body: some View {
        NavigationLink(destination: EventDetailView(event: event)) {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(event.createdAt.dateValue(), format: .dateTime.day())
                        .font(.title.bold())
                        .foregroundStyle(event.color)
                    Text(event.createdAt.dateValue(), format: .dateTime.month(.abbreviated))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 60)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(event.color.opacity(0.1)))

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.name).font(.headline)
                    HStack(spacing: 12) {
                        if let placemark = placemark {
                            Label("\(placemark.thoroughfare ?? ""), \(placemark.locality ?? "")", systemImage: "mappin.circle.fill")
                        } else {
                            Label("Cargando...", systemImage: "mappin.circle.fill")
                        }
                        Label("\(event.participants.count)", systemImage: "person.2.fill")
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
        .onAppear(perform: getPlacemark)
    }

    private func getPlacemark() {
        let location = CLLocation(latitude: event.location.latitude, longitude: event.location.longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Error reverse geocoding: \(error.localizedDescription)")
            } else if let placemarks = placemarks {
                self.placemark = placemarks.first
            }
        }
    }
}
