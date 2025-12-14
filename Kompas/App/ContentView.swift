import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionStore
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                KompasLogoView() // pantalla de carga con el logo
                    .transition(.opacity)
            } else {
                if session.isAuthenticated {
                    MainAppView()
                } else {
                    LoginView()
                }
            }
        }
        .task {
            await session.bootstrap()
            // pequeño retardo opcional para que se vea el splash
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation(.easeOut(duration: 0.35)) {
                showSplash = false
            }
        }
    }
}
