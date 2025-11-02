// LoginView.swift

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showRegisterView = false
    @State private var showForgotPassword = false
    
    // Recibe el "binding" desde ContentView.
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Logo
                        Image("kompasLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250)
                            .padding(.top, 40)
                        
                        Text("Inicio de Sesión")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)
                        
                        Text("Ingresa tu correo y contraseña")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 30)
                        
                        // Campo de email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Correo electrónico")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("ejemplo@correo.com", text: $email)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .foregroundColor(.primary)
                                .tint(.gray)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                        }
                        
                        // Campo de contraseña
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contraseña")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Mínimo 6 caracteres", text: $password)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .foregroundColor(.primary)
                                .tint(.gray)
                        }
                        
                        // Botón de olvidé mi contraseña
                        Button(action: {
                            showForgotPassword = true
                        }) {
                            Text("¿Olvidaste tu contraseña?")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, -10)
                        
                        // Mensaje de error
                        if showError {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Botón de iniciar sesión
                        Button(action: {
                            handleLogin()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Iniciar Sesión")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        .padding(.top, 20)
                        
                        // Botón de registrarse
                        HStack {
                            Text("¿No tienes cuenta?")
                                .foregroundColor(.gray)
                            Button(action: {
                                showRegisterView = true
                            }) {
                                Text("Regístrate")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                }
            }
            .sheet(isPresented: $showRegisterView) {
                RegisterView(isPresented: $showRegisterView)
            }
            .alert("Recuperar Contraseña", isPresented: $showForgotPassword) {
                TextField("Correo electrónico", text: $email)
                Button("Cancelar", role: .cancel) { }
                Button("Enviar") {
                    handlePasswordReset()
                }
            } message: {
                Text("Ingresa tu correo electrónico para recibir instrucciones de recuperación")
            }
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Función de login
    private func handleLogin() {
        // Ocultar el teclado
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Validaciones básicas
        guard !email.isEmpty else {
            showErrorMessage("Por favor ingresa un correo electrónico")
            return
        }
        
        guard !password.isEmpty else {
            showErrorMessage("Por favor ingresa una contraseña")
            return
        }
        
        guard password.count >= 6 else {
            showErrorMessage("La contraseña debe tener al menos 6 caracteres")
            return
        }
        
        isLoading = true
        
        // Intentar hacer login con Firebase
        AuthManager.shared.login(email: email, password: password) { result in
            isLoading = false
            
            switch result {
            case .success:
                // Login exitoso
                withAnimation {
                    isLoggedIn = true
                }
            case .failure(let error):
                // Login fallido
                let errorMsg = AuthManager.shared.getErrorMessage(from: error)
                showErrorMessage(errorMsg)
                password = "" // Limpiar contraseña
            }
        }
    }
    
    // MARK: - Recuperar contraseña
    private func handlePasswordReset() {
        guard !email.isEmpty else {
            showErrorMessage("Por favor ingresa tu correo electrónico")
            return
        }
        
        AuthManager.shared.resetPassword(email: email) { result in
            switch result {
            case .success:
                showErrorMessage("Se ha enviado un correo de recuperación a \(email)")
            case .failure(let error):
                let errorMsg = AuthManager.shared.getErrorMessage(from: error)
                showErrorMessage(errorMsg)
            }
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        // Ocultar el error después de 4 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showError = false
            }
        }
    }
}

// MARK: - Vista de Registro
struct RegisterView: View {
    @Binding var isPresented: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Crear Cuenta")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)
                            .padding(.top, 40)
                        
                        Text("Completa los datos para registrarte")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 20)
                        
                        // Campo de nombre de usuario
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nombre de usuario")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Tu nombre", text: $username)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .foregroundColor(.primary)
                                .tint(.gray)
                                .autocorrectionDisabled()
                        }
                        
                        // Campo de email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Correo electrónico")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("ejemplo@correo.com", text: $email)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .foregroundColor(.primary)
                                .tint(.gray)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                        }
                        
                        // Campo de contraseña
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contraseña")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Mínimo 6 caracteres", text: $password)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .foregroundColor(.primary)
                                .tint(.gray)
                        }
                        
                        // Campo de confirmar contraseña
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirmar contraseña")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Repite tu contraseña", text: $confirmPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .foregroundColor(.primary)
                                .tint(.gray)
                        }
                        
                        // Mensaje de error
                        if showError {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Botón de registrarse
                        Button(action: {
                            handleRegister()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Registrarse")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading || !isFormValid())
                        .opacity(!isFormValid() ? 0.6 : 1.0)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                }
            }
            .navigationBarItems(leading: Button("Cancelar") {
                isPresented = false
            })
        }
    }
    
    private func isFormValid() -> Bool {
        return !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && !username.isEmpty
    }
    
    private func handleRegister() {
        // Ocultar el teclado
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Validaciones
        guard password == confirmPassword else {
            showErrorMessage("Las contraseñas no coinciden")
            return
        }
        
        guard password.count >= 6 else {
            showErrorMessage("La contraseña debe tener al menos 6 caracteres")
            return
        }
        
        isLoading = true
        
        AuthManager.shared.registerUser(email: email, password: password, username: username) { result in
            isLoading = false
            
            switch result {
            case .success:
                // Registro exitoso
                isPresented = false
            case .failure(let error):
                let errorMsg = AuthManager.shared.getErrorMessage(from: error)
                showErrorMessage(errorMsg)
                password = ""
                confirmPassword = ""
            }
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showError = false
            }
        }
    }
}
