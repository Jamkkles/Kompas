import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingLogoutAlert = false
    @State private var showEditProfile = false
    @State private var showNotifications = false
    @State private var showPrivacy = false
    @State private var showSettings = false
    @State private var showRouteHistory = false


    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header con avatar
                    profileHeader
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    
                    // Tarjeta de información
                    if let user = session.user {
                        infoCard(user: user)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    }
                    
                    // Sección de opciones
                    VStack(spacing: 12) {
                        optionsSection
                            .padding(.horizontal, 16)
                        
                        // Botón de logout
                        logoutButton
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }
                    
                    // Footer
                    footerInfo
                        .padding(.top, 32)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Perfil")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .alert("Cerrar Sesión", isPresented: $showingLogoutAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar Sesión", role: .destructive) {
                    Task { await session.logout() }
                }
            } message: {
                Text("¿Estás seguro de que quieres cerrar sesión?")
            }
            .sheet(isPresented: $showRouteHistory) { // Presentar el historial de rutas como hoja modal
                RouteHistoryView()
            }
            .sheet(isPresented: $showEditProfile) {
                editProfileSheet
            }
            .sheet(isPresented: $showNotifications) {
                notificationsSheet
            }
            .sheet(isPresented: $showPrivacy) {
                privacySheet
            }
            .sheet(isPresented: $showSettings) {
                settingsSheet
            }
        }
        .tint(Brand.tint)
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            if let user = session.user {
                // Avatar
                if let photoURL = user.photoURL {
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Brand.tint.opacity(0.1))
                            .overlay(
                                ProgressView()
                                    .tint(Brand.tint)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Brand.tint.opacity(0.2), lineWidth: 3)
                    )
                } else {
                    ZStack {
                        Circle()
                            .fill(Brand.tint.opacity(0.15))
                            .frame(width: 100, height: 100)
                        
                        Text(user.name.prefix(1).uppercased())
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Brand.tint)
                    }
                }
                
                // Nombre
                Text(user.name)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                
                // Email
                Text(user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Info Card
    
    private func infoCard(user: User) -> some View {
        HStack(spacing: 20) {
            // Grupos
            VStack(spacing: 6) {
                Text("5")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Grupos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            // Amigos
            VStack(spacing: 6) {
                Text("12")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Contactos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            // Ubicaciones
            VStack(spacing: 6) {
                Text("28")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Compartidas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
        )
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(spacing: 0) {
            ProfileOptionRow(
                icon: "person.fill",
                title: "Editar Perfil",
                iconColor: Brand.tint
            ) {
                showEditProfile = true
            }
            
            Divider()
                .padding(.leading, 56)
            
            ProfileOptionRow(
                icon: "bell.fill",
                title: "Notificaciones",
                iconColor: .orange
            ) {
                showNotifications = true
            }
            
            Divider()
                .padding(.leading, 56)

            ProfileOptionRow(
                icon: "clock.arrow.circlepath", // Icono para el historial de rutas
                title: "Historial de Rutas",
                iconColor: .blue
            ) {
                showRouteHistory = true // Mostrar la hoja modal del historial de rutas
            }

            Divider()
                .padding(.leading, 56)
            
            ProfileOptionRow(
                icon: "lock.fill",
                title: "Privacidad y Seguridad",
                iconColor: .purple
            ) {
                showPrivacy = true
            }
            
            Divider()
                .padding(.leading, 56)
            
            ProfileOptionRow(
                icon: "gear",
                title: "Configuración",
                iconColor: .gray
            ) {
                showSettings = true
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
        )
    }
    
    // MARK: - Logout Button
    
    private var logoutButton: some View {
        Button {
            showingLogoutAlert = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Cerrar Sesión")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.red.opacity(0.1))
            )
        }
    }
    
    // MARK: - Footer
    
    private var footerInfo: some View {
        VStack(spacing: 8) {
            Text("Kompas")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Text("Versión 1.0.0")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    // MARK: - Sheets
    
    private var editProfileSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Brand.tint.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Brand.tint)
                }
                
                VStack(spacing: 8) {
                    Text("Editar Perfil")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    
                    Text("Esta función estará disponible pronto.\nPodrás personalizar tu perfil, foto y más.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showEditProfile = false }
                }
            }
        }
        .tint(Brand.tint)
    }
    
    private var notificationsSheet: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Notificaciones Push", isOn: .constant(true))
                    Toggle("Sonidos", isOn: .constant(true))
                    Toggle("Vibración", isOn: .constant(false))
                } header: {
                    Text("General")
                }
                
                Section {
                    Toggle("Nuevos mensajes", isOn: .constant(true))
                    Toggle("Invitaciones a grupos", isOn: .constant(true))
                    Toggle("Ubicación compartida", isOn: .constant(false))
                } header: {
                    Text("Alertas")
                } footer: {
                    Text("Recibe notificaciones cuando alguien comparte su ubicación contigo")
                }
            }
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showNotifications = false }
                }
            }
        }
        .tint(Brand.tint)
    }
    
    private var privacySheet: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Compartir ubicación automáticamente", isOn: .constant(false))
                    Toggle("Mostrar estado en línea", isOn: .constant(true))
                } header: {
                    Text("Ubicación")
                } footer: {
                    Text("Controla quién puede ver tu ubicación en tiempo real")
                }
                
                Section {
                    NavigationLink("Datos y privacidad") {}
                    NavigationLink("Términos de servicio") {}
                    NavigationLink("Política de privacidad") {}
                } header: {
                    Text("Legal")
                }
            }
            .navigationTitle("Privacidad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showPrivacy = false }
                }
            }
        }
        .tint(Brand.tint)
    }
    
    private var settingsSheet: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Idioma")
                        Spacer()
                        Text("Español")
                            .foregroundStyle(.secondary)
                    }
                    
                    Picker("Tema", selection: .constant("auto")) {
                        Text("Automático").tag("auto")
                        Text("Claro").tag("light")
                        Text("Oscuro").tag("dark")
                    }
                } header: {
                    Text("Apariencia")
                }
                
                Section {
                    Toggle("Precisión de ubicación alta", isOn: .constant(true))
                    Toggle("Actualizaciones en segundo plano", isOn: .constant(false))
                } header: {
                    Text("Mapa")
                } footer: {
                    Text("La precisión alta consume más batería pero mejora la exactitud")
                }
                
                Section {
                    Button("Limpiar caché") {}
                    Button("Reportar un problema") {}
                } header: {
                    Text("Soporte")
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showSettings = false }
                }
            }
        }
        .tint(Brand.tint)
    }
    
    // MARK: - Helpers
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark
            ? Color(.systemGray6).opacity(0.5)
            : Color(.systemBackground)
    }
}

// MARK: - Profile Option Row

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icono con fondo
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                
                // Título
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView()
        .environmentObject(SessionStore.shared)
}
