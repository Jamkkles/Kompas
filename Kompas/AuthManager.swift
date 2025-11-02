//
//  AuthManager.swift
//  Kompas
//
//  Firebase Authentication Manager
//

import Foundation
import FirebaseAuth

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        // Verificar si hay un usuario ya autenticado
        if let firebaseUser = Auth.auth().currentUser {
            self.currentUser = firebaseUser
            self.isAuthenticated = true
        }
        
        // Observar cambios en el estado de autenticación
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Registrar nuevo usuario
    func registerUser(email: String, password: String, username: String? = nil, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el usuario"])))
                return
            }
            
            // Actualizar el nombre de usuario si se proporcionó
            if let username = username {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = username
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Error al actualizar nombre: \(error.localizedDescription)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = true
            }
            
            completion(.success(user))
        }
    }
    
    // MARK: - Iniciar sesión
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al iniciar sesión"])))
                return
            }
            
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = true
            }
            
            completion(.success(user))
        }
    }
    
    // MARK: - Cerrar sesión
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Recuperar contraseña
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
    // MARK: - Obtener información del usuario actual
    func getCurrentUserEmail() -> String? {
        return currentUser?.email
    }
    
    func getCurrentUserDisplayName() -> String? {
        return currentUser?.displayName
    }
    
    func getCurrentUserUID() -> String? {
        return currentUser?.uid
    }
    
    // MARK: - Actualizar perfil
    func updateDisplayName(newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No hay usuario autenticado"])))
            return
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        changeRequest.commitChanges { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Eliminar cuenta
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No hay usuario autenticado"])))
            return
        }
        
        user.delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                DispatchQueue.main.async {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
                completion(.success(()))
            }
        }
    }
}

// MARK: - Extensión para mensajes de error amigables
extension AuthManager {
    func getErrorMessage(from error: Error) -> String {
        let errorCode = (error as NSError).code
        
        switch errorCode {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Este correo ya está registrado"
        case AuthErrorCode.invalidEmail.rawValue:
            return "El correo electrónico no es válido"
        case AuthErrorCode.weakPassword.rawValue:
            return "La contraseña debe tener al menos 6 caracteres"
        case AuthErrorCode.wrongPassword.rawValue:
            return "Contraseña incorrecta"
        case AuthErrorCode.userNotFound.rawValue:
            return "Usuario no encontrado"
        case AuthErrorCode.networkError.rawValue:
            return "Error de conexión. Verifica tu internet"
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Demasiados intentos. Intenta más tarde"
        case AuthErrorCode.userDisabled.rawValue:
            return "Esta cuenta ha sido deshabilitada"
        default:
            return error.localizedDescription
        }
    }
}
