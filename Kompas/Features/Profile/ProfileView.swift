import SwiftUI
import FirebaseAuth
import FirebaseStorage

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingLogoutAlert = false
    @State private var showEditProfile = false
    @State private var showNotifications = false
    @State private var showPrivacy = false
    @State private var showSettings = false
    @State private var showRouteHistory = false
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var requestingPermissions = false  // { changed code } nuevo estado local

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
            .sheet(isPresented: $showRouteHistory) {
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
                .fill(denseCardBackgroundColor)      
        )
        .glassEffect(in: .rect(cornerRadius: 22)) // 
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
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
                icon: "clock.arrow.circlepath",
                title: "Historial de Rutas",
                iconColor: .blue
            ) {
                showRouteHistory = true
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
                icon: "gearshape.fill",
                title: "Configuración",
                iconColor: .gray
            ) {
                showSettings = true
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(denseCardBackgroundColor)
        )
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
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
    
    @ViewBuilder
    private var editProfileSheet: some View {
        if let user = session.user {
            NavigationView {
                EditProfileView(user: user)
                    .environmentObject(session)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tint(Brand.tint)
        }
    }
    
    private var notificationsSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notificaciones")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Controla cómo recibes alertas")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                
                Divider()
                
                // Contenido
                ScrollView {
                    VStack(spacing: 16) {
                        // Toggle de notificaciones
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Activar notificaciones")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $notificationsEnabled)
                                .onChange(of: notificationsEnabled) { oldValue, newValue in
                                    if newValue {
                                        Task {
                                            let granted = await NotificationManager.shared.requestAuthorization()
                                            if !granted {
                                                notificationsEnabled = false
                                                print("❌ Permisos rechazados")
                                            } else {
                                                print("✅ Permisos concedidos")
                                            }
                                        }
                                    }
                                }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(20)
                }
                
                Spacer()
            }
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
                        Text("Español").foregroundStyle(.secondary)
                    }
                    Picker("Tema", selection: .constant("auto")) {
                        Text("Automático").tag("auto")
                        Text("Claro").tag("light")
                        Text("Oscuro").tag("dark")
                    }
                } header: { Text("Apariencia") }
                
                Section {
                    Toggle("Precisión de ubicación alta", isOn: .constant(true))
                    Toggle("Actualizaciones en segundo plano", isOn: .constant(false))
                } header: { Text("Mapa") } footer: {
                    Text("La precisión alta consume más batería pero mejora la exactitud")
                }
                
                // { changed code } NUEVA SECCIÓN DE TESTING
                Section {
                    Button {
                        NotificationManager.shared.notifyArrivalAtDestination(
                            memberName: session.user?.name ?? "Usuario",
                            destination: "Casa"
                        )
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Probar notificación llegada")
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .foregroundStyle(Brand.tint)
                    }
                    
                    Button {
                        NotificationManager.shared.notifyDeparture(
                            memberName: session.user?.name ?? "Usuario",
                            origin: "Trabajo"
                        )
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Probar notificación salida")
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .foregroundStyle(Brand.tint)
                    }
                    
                    Button {
                        NotificationManager.shared.notifySOSActivation(
                            memberName: session.user?.name ?? "Usuario"
                        )
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Probar notificación SOS")
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .foregroundStyle(.red)
                    }
                } header: { Text("Testing") } footer: {
                    Text("Botones para probar notificaciones en desarrollo")
                }
                
                Section {
                    Button("Limpiar caché") {}
                    Button("Reportar un problema") {}
                } header: { Text("Soporte") }
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

    private var denseCardBackgroundColor: Color {        
        colorScheme == .dark
            ? Color(.systemGray6).opacity(0.8)     
            : Color(.systemBackground).opacity(0.95)    
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
            .contentShape(Rectangle()) 
        }
        .buttonStyle(.plain)
    }
}

extension SessionStore {
    @MainActor
    func updateProfile(name: String, photoBase64: String?) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "FirebaseAuth", code: -10, userInfo: [NSLocalizedDescriptionKey: "No hay usuario autenticado"])
        }

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name

        if let photoBase64 = photoBase64 {
            let storageRef = Storage.storage().reference().child("profile_pictures/\(user.uid).jpg")
            if let imageData = Data(base64Encoded: photoBase64) {
                do {
                    _ = try await storageRef.putDataAsync(imageData)
                    
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
                    
                    let downloadURL = try await storageRef.downloadURL()
                    changeRequest.photoURL = downloadURL
                    print("✅ Foto subida: \(downloadURL)")
                } catch {
                    print("❌ Error subiendo imagen: \(error.localizedDescription)")
                    throw error
                }
            }
        }

        try await changeRequest.commitChanges()
    }
}

#Preview {
    ProfileView()
        .environmentObject(SessionStore.shared)
}
