import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.colorScheme) private var colorScheme

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
            // Fondo
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    
                    // MARK: - Header
                    headerSection
                        .padding(.bottom, 48)
                    
                    // MARK: - Formulario
                    formSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    
                    // MARK: - Divider
                    dividerSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // MARK: - Social Login
                    socialLoginSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    
                    // MARK: - Toggle
                    toggleSection
                    
                    Spacer().frame(height: 40)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo
            ZStack {
                Circle()
                    .fill(Brand.tint.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "location.north.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Brand.tint)
            }
            
            VStack(spacing: 8) {
                Text("Kompas")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(isRegister ? "Crea tu cuenta" : "¡Bienvenido de nuevo!")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 12) {
            if isRegister {
                EnhancedTextField(
                    icon: "person.fill",
                    placeholder: "Nombre completo",
                    text: $name,
                    iconColor: Brand.tint
                )
                .textContentType(.name)
                .focused($focus, equals: .name)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
                
                EnhancedTextField(
                    icon: "phone.fill",
                    placeholder: "Teléfono (opcional)",
                    text: $phone,
                    iconColor: .green
                )
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .focused($focus, equals: .phone)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }

            EnhancedTextField(
                icon: "envelope.fill",
                placeholder: "Correo electrónico",
                text: $email,
                iconColor: Brand.tint
            )
            .keyboardType(.emailAddress)
            .textContentType(.username)
            .textInputAutocapitalization(.never)
            .focused($focus, equals: .email)
            
            EnhancedSecureField(
                icon: "lock.fill",
                placeholder: "Contraseña",
                text: $password,
                iconColor: Brand.tint
            )
            .textContentType(isRegister ? .newPassword : .password)
            .focused($focus, equals: .password)

            if isRegister {
                EnhancedSecureField(
                    icon: "lock.rotation",
                    placeholder: "Confirmar contraseña",
                    text: $confirm,
                    iconColor: Brand.tint
                )
                .textContentType(.newPassword)
                .focused($focus, equals: .confirm)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
                
                EnhancedTextField(
                    icon: "person.3.fill",
                    placeholder: "Código de grupo (opcional)",
                    text: $familyCode,
                    iconColor: .purple
                )
                .textInputAutocapitalization(.characters)
                .focused($focus, equals: .family)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }

            if let err = session.errorMessage, !err.isEmpty {
                EnhancedErrorMessage(text: err)
                    .transition(.scale.combined(with: .opacity))
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
                            .font(.system(.body, design: .rounded, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(disabledButton ? Brand.tint.opacity(0.5) : Brand.tint)
                )
                .foregroundStyle(.white)
            }
            .disabled(disabledButton)
            .padding(.top, 8)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRegister)
    }
    
    // MARK: - Divider Section
    
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
            
            Text("o continúa con")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
        }
    }
    
    // MARK: - Social Login Section
    
    private var socialLoginSection: some View {
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
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 52)
            .cornerRadius(16)

            // Google Sign In
            Button {
                Task { await session.signInWithGoogle() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Text("Continuar con Google")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardBackgroundColor)
                )
            }
        }
    }
    
    // MARK: - Toggle Section
    
    private var toggleSection: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isRegister.toggle()
                session.errorMessage = nil
                clearForm()
            }
        } label: {
            HStack(spacing: 4) {
                Text(isRegister ? "¿Ya tienes cuenta?" : "¿No tienes cuenta?")
                    .foregroundStyle(.secondary)
                Text(isRegister ? "Inicia sesión" : "Regístrate")
                    .foregroundStyle(Brand.tint)
                    .fontWeight(.semibold)
            }
            .font(.system(size: 15))
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
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark
            ? Color(.systemGray6).opacity(0.5)
            : Color(.systemGray6)
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

// MARK: - Enhanced Text Field

private struct EnhancedTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let iconColor: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(fieldBackgroundColor)
        )
    }
    
    private var fieldBackgroundColor: Color {
        colorScheme == .dark
            ? Color(.systemGray6).opacity(0.5)
            : Color(.systemGray6)
    }
}

// MARK: - Enhanced Secure Field

private struct EnhancedSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let iconColor: Color
    @State private var isVisible = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            if isVisible {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
            } else {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isVisible.toggle()
                }
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(fieldBackgroundColor)
        )
    }
    
    private var fieldBackgroundColor: Color {
        colorScheme == .dark
            ? Color(.systemGray6).opacity(0.5)
            : Color(.systemGray6)
    }
}

// MARK: - Enhanced Error Message

private struct EnhancedErrorMessage: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.red)
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionStore.shared)
}
