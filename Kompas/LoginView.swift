// LoginView.swift

import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    
    // Recibe el "binding" desde ContentView.
    @Binding var isLoggedIn: Bool

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 20) {
                // Asegúrate de tener una imagen llamada "kompasLogo" en Assets.xcassets
                Image("kompasLogo") // Asegúrate de tener una imagen llamada "kompasLogo" en tus assets.
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

                TextField("Usuario", text: $username)
                    .padding()
                    // .white o Color(.systemGray6) son buenas opciones.
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .foregroundColor(.primary)
                    .tint(.gray) // Color del cursor

                SecureField("Contraseña", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .foregroundColor(.primary)
                    .tint(.gray)

                Button(action: {
                    // Simula un inicio de sesión exitoso.
                    withAnimation {
                        isLoggedIn = true
                    }
                }) {
                    Text("Iniciar Sesión")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor) // Usar el color de acento está bien.
                        .foregroundColor(.white) // Texto blanco sobre el botón de color es estándar.
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .preferredColorScheme(.light)
        }
    }
}
