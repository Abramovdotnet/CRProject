import SwiftUI

enum Theme {
    static let primaryColor = Color(red: 0.8, green: 0.1, blue: 0.1) // Deep red
    static let secondaryColor = Color(red: 0.2, green: 0.1, blue: 0.2) // Dark purple
    static let accentColor = Color(red: 0.9, green: 0.8, blue: 0.8) // Light blood
    static let backgroundColor = Color(red: 0.1, green: 0.05, blue: 0.1) // Dark background
    static let textColor = Color(red: 0.9, green: 0.9, blue: 0.9) // Light text
    
    static let bloodProgressColor = Color(red: 0.8, green: 0.1, blue: 0.1) // Blood red
    static let awarenessProgressColor = Color(red: 0.4, green: 0.1, blue: 0.5) // Purple
    
    static let titleFont = Font.custom("Optima-Bold", size: 18)
    static let headingFont = Font.custom("Optima-Bold", size: 14)
    static let bodyFont = Font.custom("Optima", size: 12)
    
    static let subheadingFont = Font.headline
    static let captionFont = Font.caption
}

struct VampireButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .background(Theme.primaryColor)
            .foregroundColor(Theme.textColor)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ProgressBar: View {
    let value: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track (inactive part)
                Rectangle()
                    .foregroundColor(.black.opacity(0.5))
                
                // Progress fill (active part)
                Rectangle()
                    .foregroundColor(color)
                    .frame(width: geometry.size.width * CGFloat(value))
            }
        }
        .frame(height: 8)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black, lineWidth: 1)
                .opacity(0.5)
        )
    }
}
