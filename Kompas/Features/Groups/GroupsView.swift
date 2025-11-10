import SwiftUI
import UniformTypeIdentifiers

struct GroupsView: View {
    @StateObject private var repo = GroupRepository()

    @State private var searchText = ""
    @State private var errorMessage: String?

    // Sheets / dialogs
    @State private var showActionMenu = false
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false

    @State private var newGroupName = ""
    @State private var joinCode = ""

    // Invite presentation
    @State private var inviteForGroup: UserGroup?
    @State private var generatedCode: String?
    @State private var showInviteSheet = false

    var body: some View {
        NavigationView {
            SwiftUI.Group {
                if repo.groups.isEmpty && searchText.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("Grupos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showActionMenu = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Brand.tint)
                    }
                    .accessibilityLabel("Opciones")
                }
            }
            .confirmationDialog("Opciones", isPresented: $showActionMenu, titleVisibility: .visible) {
                Button("Crear grupo") { showCreateSheet = true }
                Button("Unirse por código") { showJoinSheet = true }
                Button("Cancelar", role: .cancel) { }
            }
            .sheet(isPresented: $showCreateSheet) { createGroupSheet }
            .sheet(isPresented: $showJoinSheet) { joinGroupSheet }
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

    // MARK: - Content

    private var listContent: some View {
        List {
            Section {
                ForEach(filtered(repo.groups)) { group in
                    groupRow(group)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                Task { await makeInvite(for: group) }
                            } label: {
                                Label("Invitar", systemImage: "person.badge.plus")
                            }
                            .tint(.blue)

                            Button(role: .destructive) {
                                Task { await delete(group) }
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
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
                                Label("Crear código de invitación", systemImage: "link.badge.plus")
                            }
                        }
                }
            } header: {
                Text("Mis grupos")
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }

    // MARK: - Rows

    private func groupRow(_ group: UserGroup) -> some View {
        HStack(spacing: 12) {
            avatarCircle(text: initials(for: group.name))
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                Text("\(group.memberIds.count) miembro\(group.memberIds.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private func avatarCircle(text: String) -> some View {
        ZStack {
            Circle()
                .fill(Brand.tint.opacity(0.15))
                .frame(width: 44, height: 44)
            Text(text.uppercased())
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Brand.tint)
        }
    }

    private func initials(for name: String) -> String {
        let comps = name.split(separator: " ")
        let first = comps.first?.prefix(1) ?? Substring("")
        let second = comps.dropFirst().first?.prefix(1) ?? Substring("")
        let result = "\(first)\(second)"
        return result.isEmpty ? String(name.prefix(2)) : result
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 52))
                .foregroundStyle(Brand.tint.opacity(0.7))
            Text("Aún no tienes grupos")
                .font(.title3).fontWeight(.semibold)
            Text("Crea un grupo nuevo o únete con un código de invitación.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                showActionMenu = true
            } label: {
                Label("Crear o unirse", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(Brand.tint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 80)
    }

    // MARK: - Sheets

    private var createGroupSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Nombre del grupo")) {
                    TextField("Ej. Familia", text: $newGroupName)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Crear grupo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showCreateSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        Task { await createGroup() }
                    }
                    .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .tint(Brand.tint)
    }

    private var joinGroupSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Código de invitación")) {
                    TextField("ABC1234", text: $joinCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Unirse a un grupo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showJoinSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Unirme") {
                        Task { await joinByCode() }
                    }
                    .disabled(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .tint(Brand.tint)
    }

    private var inviteCodeSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let group = inviteForGroup, let code = generatedCode {
                    Text("Invitación para \(group.name)")
                        .font(.headline)
                    Text(code)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .padding()
                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Label("Copiar código", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Brand.tint)
                } else {
                    ProgressView()
                }
                Spacer()
            }
            .navigationTitle("Código de invitación")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showInviteSheet = false }
                }
            }
        }
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
        } catch { errorMessage = error.localizedDescription }
    }

    private func joinByCode() async {
        do {
            try await repo.joinByCode(joinCode)
            joinCode = ""
            showJoinSheet = false
        } catch { errorMessage = error.localizedDescription }
    }

    private func delete(_ group: UserGroup) async {
        do { try await repo.deleteGroup(group) }
        catch { errorMessage = error.localizedDescription }
    }

    private func renamePrompt(group: UserGroup) {
        var nameBuffer = group.name
        let alert = UIAlertController(title: "Renombrar", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.text = nameBuffer }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { _ in
            if let text = alert.textFields?.first?.text {
                Task {
                    do { try await repo.renameGroup(group, to: text) }
                    catch { errorMessage = error.localizedDescription }
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
        } catch { errorMessage = error.localizedDescription }
    }
}

// Helper UIKit
import UIKit
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
