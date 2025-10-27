//
//  AuthManager.swift
//  Kompas
//
//  Simple authentication manager using UserDefaults
//

import Foundation

class AuthManager {
    static let shared = AuthManager()
    
    private let usersKey = "registeredUsers"
    private let userDefaults = UserDefaults.standard
    
    private init() {
        // Crear un usuario de prueba si no existe ninguno
        if getUsers().isEmpty {
            _ = registerUser(username: "admin", password: "1234")
            _ = registerUser(username: "pablo", password: "pablo123")
        }
    }
    
    // MARK: - Estructura de Usuario
    struct User: Codable {
        let username: String
        let password: String
    }
    
    // MARK: - Obtener todos los usuarios
    private func getUsers() -> [User] {
        guard let data = userDefaults.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }
    
    // MARK: - Guardar usuarios
    private func saveUsers(_ users: [User]) {
        if let data = try? JSONEncoder().encode(users) {
            userDefaults.set(data, forKey: usersKey)
        }
    }
    
    // MARK: - Registrar nuevo usuario
    func registerUser(username: String, password: String) -> Bool {
        var users = getUsers()
        
        // Verificar si el usuario ya existe
        if users.contains(where: { $0.username == username }) {
            return false
        }
        
        let newUser = User(username: username, password: password)
        users.append(newUser)
        saveUsers(users)
        return true
    }
    
    // MARK: - Iniciar sesión
    func login(username: String, password: String) -> Bool {
        let users = getUsers()
        
        // Verificar credenciales
        return users.contains { user in
            user.username == username && user.password == password
        }
    }
    
    // MARK: - Verificar si existe un usuario
    func userExists(username: String) -> Bool {
        let users = getUsers()
        return users.contains { $0.username == username }
    }
    
    // MARK: - Obtener lista de nombres de usuario (para debug)
    func getAllUsernames() -> [String] {
        return getUsers().map { $0.username }
    }
}
