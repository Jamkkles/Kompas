import SwiftUI

struct GroupsView: View {
    @StateObject private var repo = GroupRepository()
    @State private var showingNewGroup = false
    @State private var newGroupName = ""
    @State private var searchText: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                ForEach(filtered(repo.groups)) { group in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.name).font(.headline)
                            Text("Miembros: \(group.memberIds.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Menu {
                            Button("Renombrar") { promptRename(group: group) }
                            Button("Eliminar", role: .destructive) { Task { await delete(group) } }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Grupos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingNewGroup = true } label: { Image(systemName: "plus") }
                }
            }
            .onAppear { repo.startListening() }
            .onDisappear { repo.stopListening() }
            .alert("Nuevo grupo", isPresented: $showingNewGroup) {
                TextField("Nombre", text: $newGroupName)
                Button("Crear") { Task { await createGroup() } }
                Button("Cancelar", role: .cancel) { newGroupName = "" }
            } message: {
                Text("Crea un grupo (máx. 5)")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func filtered(_ groups: [Group]) -> [Group] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return groups }
        return groups.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    private func createGroup() async {
        do {
            try await repo.createGroup(name: newGroupName)
            newGroupName = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ group: Group) async {
        do { try await repo.deleteGroup(group) }
        catch { errorMessage = error.localizedDescription }
    }

    private func promptRename(group: Group) {
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
}

// Helper UIKit bridge
import UIKit
extension UIApplication {
    func topMostViewController(base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
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
