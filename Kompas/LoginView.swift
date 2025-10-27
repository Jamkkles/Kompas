// LoginView.swift

import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    // Recibe el "binding" desde ContentView.
    @Binding var isLoggedIn: Bool

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 20) {
                // Asegúrate de tener una imagen llamada "kompasLogo" en Assets.xcassets
                Image("kompasLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
                    
                Text("Inicio de Sesión")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                    
                Text("Ingresa tu usuario y contraseña para iniciar sesión")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 30)

                // Campo de usuario
                TextField("Usuario", text: $username)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .foregroundColor(.primary)
                    .tint(.gray)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                // Campo de contraseña
                SecureField("Contraseña", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .foregroundColor(.primary)
                    .tint(.gray)

                // Mensaje de error
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
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
                .disabled(isLoading || username.isEmpty || password.isEmpty)
                .opacity((username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                .padding(.top, 20)
                
                // Información de usuarios de prueba
                VStack(spacing: 8) {
                    Text("Usuarios de prueba:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("admin / 1234")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("pablo / pablo123")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 30)
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .preferredColorScheme(.light)
        }
    }
    
    // MARK: - Función de login
    private func handleLogin() {
        // Ocultar el teclado
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Validaciones básicas
        guard !username.isEmpty else {
            showErrorMessage("Por favor ingresa un usuario")
            return
        }
        
        guard !password.isEmpty else {
            showErrorMessage("Por favor ingresa una contraseña")
            return
        }
        
        // Simular un pequeño delay (opcional, para dar sensación de validación)
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Intentar hacer login
            let success = AuthManager.shared.login(username: username, password: password)
            
            isLoading = false
            
            if success {
                // Login exitoso
                withAnimation {
                    isLoggedIn = true
                }
            } else {
                // Login fallido
                showErrorMessage("Usuario o contraseña incorrectos")
                // Limpiar la contraseña por seguridad
                password = ""
            }
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        // Ocultar el error después de 3 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showError = false
            }
        }
    }
}
