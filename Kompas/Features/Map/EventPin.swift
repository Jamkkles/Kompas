import SwiftUI

struct EventPin: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}
