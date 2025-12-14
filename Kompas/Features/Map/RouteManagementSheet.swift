import SwiftUI
import MapKit

struct RouteManagementSheet: View {
    let eventRoutes: [String: MKRoute]
    let upcomingEvents: [EventItem]
    let onCancelRoute: (String) -> Void
    let onCancelAllRoutes: () -> Void
    let onFocusRoute: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rutas Activas")
                                .font(.system(size: 28, weight: .bold))
                            
                            Text("\(eventRoutes.count) ruta\(eventRoutes.count == 1 ? "" : "s") calculada\(eventRoutes.count == 1 ? "" : "s")")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Botón para cancelar todas las rutas
                    if !eventRoutes.isEmpty {
                        Button {
                            onCancelAllRoutes()
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14))
                                Text("Cancelar todas las rutas")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.red, in: Capsule())
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Divider()
                    .padding(.top, 16)
                
                // Lista de rutas
                if eventRoutes.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "route")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.secondary.opacity(0.5))
                        
                        Text("No hay rutas activas")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(eventRoutes.keys), id: \.self) { eventId in
                                if let route = eventRoutes[eventId],
                                   let event = upcomingEvents.first(where: { $0.id == eventId }) {
                                    RouteCard(
                                        event: event,
                                        route: route,
                                        onFocus: { onFocusRoute(eventId) },
                                        onCancel: { onCancelRoute(eventId) }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
    }
}

private struct RouteCard: View {
    let event: EventItem
    let route: MKRoute
    let onFocus: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Icono del evento
                ZStack {
                    Circle()
                        .fill(Brand.tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: event.icon?.symbolName ?? "calendar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Brand.tint)
                }
                
                // Info del evento
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                            Text(String(format: "%.1f km", route.distance / 1000))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                            Text(String(format: "%.0f min", route.expectedTravelTime / 60))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Botones de acción
            HStack(spacing: 12) {
                Button {
                    onFocus()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 12))
                        Text("Ver ruta")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Brand.tint)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Brand.tint.opacity(0.1), in: Capsule())
                }
                
                Spacer()
                
                Button {
                    onCancel()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Cancelar")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.red.opacity(0.1), in: Capsule())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}