import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.colorScheme) private var scheme

    @State private var isRegister = false
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var familyCode = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var isLoading = false
    @FocusState private var focus: Field?

    enum Field { case name, email, phone, password, confirm, family }

    var body: some View {
        ZStack {
            // Fondo limpio
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 20)
                    
                    // MARK: - Header
                    VStack(spacing: 12) {
                        AppLogo()
                            .frame(width: 80, height: 80)
                        
                        Text("Kompas")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        
                        Text("Encuentra, cuida y mantente conectado")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // MARK: - Formulario
                    VStack(spacing: 16) {
                        if isRegister {
                            CustomTextField(
                                icon: "person.fill",
                                placeholder: "Nombre completo",
                                text: $name
                            )
                            .textContentType(.name)
                            .focused($focus, equals: .name)
                            
                            CustomTextField(
                                icon: "phone.fill",
                                placeholder: "Teléfono (opcional)",
                                text: $phone
                            )
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .focused($focus, equals: .phone)
                        }

                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "Correo electrónico",
                            text: $email
                        )
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .focused($focus, equals: .email)
                        
                        CustomSecureField(
                            icon: "lock.fill",
                            placeholder: "Contraseña",
                            text: $password
                        )
                        .textContentType(isRegister ? .newPassword : .password)
                        .focused($focus, equals: .password)

                        if isRegister {
                            CustomSecureField(
                                icon: "lock.rotation",
                                placeholder: "Confirmar contraseña",
                                text: $confirm
                            )
                            .textContentType(.newPassword)
                            .focused($focus, equals: .confirm)
                            
                            CustomTextField(
                                icon: "person.3.fill",
                                placeholder: "Código de familia (opcional)",
                                text: $familyCode
                            )
                            .focused($focus, equals: .family)
                        }

                        if let err = session.errorMessage, !err.isEmpty {
                            ErrorMessage(text: err)
                        }

                        // Botón principal
                        Button {
                            hideKeyboard()
                            Task { await submit() }
                        } label: {
                            ZStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isRegister ? "Crear cuenta" : "Iniciar sesión")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 10))
                        .disabled(disabledButton)
                    }
                    .padding(.horizontal)

                    // MARK: - Divider
                    HStack {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(height: 0.5)
                        Text("o")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(height: 0.5)
                    }
                    .padding(.horizontal)

                    // MARK: - Social Login
                    VStack(spacing: 12) {
                        // Apple Sign In
                        SignInWithAppleButton { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            Task {
                                if let window = UIApplication.shared.windows.first {
                                    await session.signInWithApple(anchor: window)
                                }
                            }
                        }
                        .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                        .frame(height: 44)
                        .cornerRadius(10)

                        // Google Sign In
                        Button {
                            Task { await session.signInWithGoogle() }
                        } label: {
                            HStack(spacing: 12) {
                                // Placeholder for Google logo
                                Image(systemName: "globe")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                Text("Continuar con Google")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isRegister.toggle()
                            session.errorMessage = nil
                            clearForm()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isRegister ? "¿Ya tienes cuenta?" : "¿No tienes cuenta?")
                                .foregroundStyle(.secondary)
                            Text(isRegister ? "Inicia sesión" : "Regístrate")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
        }
    }

    // MARK: - Helpers
    private var disabledButton: Bool {
        if isRegister {
            return name.isEmpty ||
                   email.isEmpty ||
                   password.isEmpty ||
                   confirm.isEmpty ||
                   password != confirm ||
                   isLoading
        }
        return email.isEmpty || password.isEmpty || isLoading
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func clearForm() {
        name = ""
        email = ""
        phone = ""
        familyCode = ""
        password = ""
        confirm = ""
    }

    private func submit() async {
        guard !disabledButton else { return }
        isLoading = true
        defer { isLoading = false }
        
        if isRegister {
            await session.register(name: name, email: email, password: password)
        } else {
            await session.login(email: email, password: password)
        }
    }
}

// MARK: - Custom Components

private struct AppLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "location.north.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
        }
        .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
    }
}

private struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .font(.body)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

private struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            if isVisible {
                TextField(placeholder, text: $text)
                    .font(.body)                // 👈 el font va aquí
            } else {
                SecureField(placeholder, text: $text)
                    .font(.body)                // 👈 y aquí
            }

            Button { isVisible.toggle() } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}


private struct ErrorMessage: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.red)
        )
    }
}
