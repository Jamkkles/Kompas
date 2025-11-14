import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct GroupsView: View {
    @StateObject private var repo = GroupRepository()
    
    @State private var searchText = ""
    @State private var errorMessage: String?
    @State private var selectedTab: ChatTab = .groups
    
    // Sheets / dialogs
    @State private var showActionMenu = false
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false
    @State private var showNewDirectChat = false
    
    @State private var newGroupName = ""
    @State private var joinCode = ""
    
    // Invite presentation
    @State private var inviteForGroup: UserGroup?
    @State private var generatedCode: String?
    @State private var showInviteSheet = false
    
    enum ChatTab: String, CaseIterable {
        case groups = "Grupos"
        case direct = "Directos"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top bar con controles
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                
                // Content
                if selectedTab == .groups {
                    groupsContent
                } else {
                    directChatsContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mensajes")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .confirmationDialog("Nueva conversación", isPresented: $showActionMenu, titleVisibility: .visible) {
                Button("Nuevo grupo") { showCreateSheet = true }
                Button("Chat directo") { showNewDirectChat = true }
                Button("Unirse por código") { showJoinSheet = true }
                Button("Cancelar", role: .cancel) { }
            }
            .sheet(isPresented: $showCreateSheet) { createGroupSheet }
            .sheet(isPresented: $showJoinSheet) { joinGroupSheet }
            .sheet(isPresented: $showNewDirectChat) { newDirectChatSheet }
            .sheet(isPresented: $showInviteSheet) { inviteCodeSheet }
            .onAppear { repo.startListening() }
            .onDisappear { repo.stopListening() }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .tint(Brand.tint)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 12) {
            // Segmented Control
            customSegmentedControl
            
            Spacer()
            
            // Botón crear/nuevo
            Button {
                showActionMenu = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Brand.tint.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Brand.tint)
                }
            }
        }
    }
    
    // MARK: - Segmented Control
    
    @Namespace private var tabNamespace
    
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(ChatTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(selectedTab == tab ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(Brand.tint)
                                    .matchedGeometryEffect(id: "tab", in: tabNamespace)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Groups Content
    
    private var groupsContent: some View {
        SwiftUI.Group {
            if repo.groups.isEmpty && searchText.isEmpty {
                emptyGroupsState
            } else {
                groupsList
            }
        }
        .searchable(text: $searchText, prompt: "Buscar grupos")
    }
    
    private var groupsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filtered(repo.groups)) { group in
                    GroupCard(group: group)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Navegar al chat del grupo
                        }
                        .contextMenu {
                            Button {
                                renamePrompt(group: group)
                            } label: {
                                Label("Renombrar", systemImage: "pencil")
                            }
                            Button {
                                Task { await makeInvite(for: group) }
                            } label: {
                                Label("Invitar miembros", systemImage: "person.badge.plus")
                            }
                            Divider()
                            Button(role: .destructive) {
                                Task { await delete(group) }
                            } label: {
                                Label("Eliminar grupo", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Direct Chats Content
    
    private var directChatsContent: some View {
        SwiftUI.Group {
            if searchText.isEmpty {
                emptyDirectChatsState
            } else {
                emptyDirectChatsState
            }
        }
        .searchable(text: $searchText, prompt: "Buscar contactos")
    }
    
    // MARK: - Empty States
    
    private var emptyGroupsState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Brand.tint.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Brand.tint)
            }
            
            VStack(spacing: 8) {
                Text("Crea tu primer grupo")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                
                Text("Organiza conversaciones con familia,\namigos o compañeros de trabajo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Button {
                showCreateSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Crear grupo")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Brand.tint, in: Capsule())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    private var emptyDirectChatsState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Brand.tint.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Brand.tint)
            }
            
            VStack(spacing: 8) {
                Text("Sin conversaciones")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                
                Text("Inicia un chat directo con\ncualquier miembro de tus grupos")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Button {
                showNewDirectChat = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Nuevo chat")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Brand.tint, in: Capsule())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Sheets (estilo armonizado)
    
    private var createGroupSheet: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Icono
                    ZStack {
                        Circle()
                            .fill(Brand.tint.opacity(0.12))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Brand.tint)
                    }
                    
                    // Título
                    VStack(spacing: 6) {
                        Text("Nuevo grupo")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text("Elige un nombre descriptivo para tu grupo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    
                    // Card con TextField
                    VStack(spacing: 12) {
                        Text("Nombre del grupo")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("Familia, Amigos, Trabajo…", text: $newGroupName)
                            .textInputAutocapitalization(.words)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    // Botón crear
                    Button {
                        Task { await createGroup() }
                    } label: {
                        Text("Crear grupo")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Brand.tint, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                    
                    Spacer()
                }
            }
            .navigationTitle("Nuevo grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        newGroupName = ""
                        showCreateSheet = false
                    }
                }
            }
        }
        .tint(Brand.tint)
    }
    
    private var joinGroupSheet: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Icono
                    ZStack {
                        Circle()
                            .fill(Brand.tint.opacity(0.12))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 36))
                            .foregroundStyle(Brand.tint)
                    }
                    
                    // Título
                    VStack(spacing: 6) {
                        Text("Unirse a un grupo")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text("Ingresa el código de 7 caracteres que te compartieron")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    
                    // Card con TextField
                    VStack(spacing: 12) {
                        Text("Código de invitación")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("ABC-1234", text: $joinCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    // Botón unirme
                    Button {
                        Task { await joinByCode() }
                    } label: {
                        Text("Unirme al grupo")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Brand.tint, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    .disabled(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                    
                    Spacer()
                }
            }
            .navigationTitle("Unirse a grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        joinCode = ""
                        showJoinSheet = false
                    }
                }
            }
        }
        .tint(Brand.tint)
    }
    
    private var newDirectChatSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Brand.tint.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Brand.tint)
                }
                
                VStack(spacing: 8) {
                    Text("Próximamente")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    
                    Text("Esta función estará disponible pronto.\nPodrás iniciar chats directos con miembros de tus grupos.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Nuevo chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showNewDirectChat = false }
                }
            }
        }
        .tint(Brand.tint)
    }
    
    private var inviteCodeSheet: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if let group = inviteForGroup, let code = generatedCode {
                        Spacer()
                        
                        // Icono
                        ZStack {
                            Circle()
                                .fill(Brand.tint.opacity(0.12))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "link.badge.plus")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(Brand.tint)
                        }
                        .padding(.bottom, 20)
                        
                        // Título
                        VStack(spacing: 6) {
                            Text("Código de invitación")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                            
                            Text(group.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 32)
                        
                        // Código
                        VStack(spacing: 8) {
                            Text(code)
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .tracking(4)
                                .foregroundStyle(Brand.tint)
                                .padding(.vertical, 20)
                                .padding(.horizontal, 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Brand.tint.opacity(0.1))
                                )
                            
                            Text("Válido por 48 horas")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 32)
                        
                        // Botón copiar
                        Button {
                            UIPasteboard.general.string = code
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 16))
                                Text("Copiar código")
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Brand.tint, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                    } else {
                        Spacer()
                        ProgressView()
                            .tint(Brand.tint)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Invitar miembros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        showInviteSheet = false
                        inviteForGroup = nil
                        generatedCode = nil
                    }
                }
            }
        }
        .tint(Brand.tint)
    }
    
    // MARK: - Actions
    
    private func filtered(_ groups: [UserGroup]) -> [UserGroup] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return groups }
        return groups.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }
    
    private func createGroup() async {
        do {
            try await repo.createGroup(name: newGroupName)
            newGroupName = ""
            showCreateSheet = false
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func joinByCode() async {
        do {
            try await repo.joinByCode(joinCode)
            joinCode = ""
            showJoinSheet = false
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func delete(_ group: UserGroup) async {
        do {
            try await repo.deleteGroup(group)
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func renamePrompt(group: UserGroup) {
        let alert = UIAlertController(
            title: "Renombrar grupo",
            message: "Ingresa el nuevo nombre",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.text = group.name
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { _ in
            if let text = alert.textFields?.first?.text {
                Task {
                    do {
                        try await repo.renameGroup(group, to: text)
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        })
        UIApplication.shared.topMostViewController()?.present(alert, animated: true)
    }
    
    private func makeInvite(for group: UserGroup) async {
        do {
            let code = try await repo.createInvite(for: group)
            self.inviteForGroup = group
            self.generatedCode = code
            self.showInviteSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Group Card Component

struct GroupCard: View {
    let group: UserGroup
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Brand.tint.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Text(initials(for: group.name))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.tint)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(group.memberIds.count) miembro\(group.memberIds.count == 1 ? "" : "s")")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
        )
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark
            ? Color(.systemGray6).opacity(0.5)
            : Color(.systemBackground)
    }
    
    private func initials(for name: String) -> String {
        let comps = name.split(separator: " ")
        let first = comps.first?.prefix(1) ?? Substring("")
        let second = comps.dropFirst().first?.prefix(1) ?? Substring("")
        let result = "\(first)\(second)"
        return result.isEmpty ? String(name.prefix(2)) : result
    }
}

// MARK: - UIKit Helper

extension UIApplication {
    func topMostViewController(base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        } else if let tab = base as? UITabBarController,
                  let selected = tab.selectedViewController {
            return topMostViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return base
    }
}

#Preview {
    GroupsView()
}
