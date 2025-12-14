import SwiftUI

struct KompasLogoView: View {
    // Estado para una animación simple de entrada
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Color de fondo suave (opcional)
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                
                // --- EL LOGO ---
                // Asegúrate de que tu imagen en Assets.xcassets se llame "KompasLogo"
                Image("kompasLogo") 
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    // Estilo de icono de iOS (bordes redondeados continuos)
                    .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                    // Sombra elegante para dar profundidad
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                // --- TEXTO DE LA APP ---
                VStack(spacing: 8) {
                    Text("Kompas")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Encuentra tu camino")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 20)
                
            }
            .padding()
        }
        .onAppear {
            // Animación suave al cargar la vista
            withAnimation(.easeOut(duration: 1.2)) {
                isAnimating = true
            }
        }
    }
}

// Vista previa para el Canvas de Xcode
struct KompasLogoView_Previews: PreviewProvider {
    static var previews: some View {
        KompasLogoView()
    }
}