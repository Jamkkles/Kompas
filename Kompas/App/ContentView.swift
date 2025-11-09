import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        ZStack {
            if session.isAuthenticated {
                MainAppView()
            } else {
                LoginView()
            }
        }
        .task {
            await session.bootstrap()
        }
    }
}
