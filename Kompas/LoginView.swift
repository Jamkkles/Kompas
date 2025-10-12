// LoginView.swift

import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    
    // Recibe el "binding" desde ContentView.
    @Binding var isLoggedIn: Bool

    var body: some View {
        ZStack {
            // Color de fondo oscuro.
            Color(red: 0.1, green: 0.1, blue: 0.1).ignoresSafeArea()

            VStack(spacing: 20) {
                // Asegúrate de tener una imagen llamada "kompasLogo" en Assets.xcassets
                // Image("kompasLogo")
                // Si no tienes el logo, puedes usar un ícono del sistema como placeholder:
                Image("kompasLogo") // Asegúrate de tener una imagen llamada "kompasLogo" en tus assets.
                                   .resizable()
                                   .scaledToFit()
                                   .frame(width: 250)
                                  

                Text("Inicio de Sesión")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    

                Text("Ingresa tu usuario y contraseña para iniciar sesión")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 30)

                TextField("Usuario", text: $username)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .tint(.white) // Color del cursor

                SecureField("Contraseña", text: $password)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .tint(.white)

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
                        .background(Color.accentColor) // Usa el color de acento del proyecto.
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.horizontal, 30)
        }
    }
}
