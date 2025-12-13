import SwiftUI

struct EventPin: View {
    let name: String
    let icon: EventIcon?
    let date: Date?
    let photoBase64: String?
    let onTap: (String?) -> Void

    var body: some View {
        Button(action: {
            onTap(photoBase64)
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    if let icon = icon {
                        Image(systemName: icon.symbolName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                
                VStack(spacing: 2) {
                    Text(name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                    
                    if let date = date {
                        Text(date, style: .date)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(date, style: .time)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.8))
                .cornerRadius(4)
            }
        }
    }
}
