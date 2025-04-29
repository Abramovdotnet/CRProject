import SwiftUI

struct PopUpData: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let details: String?
    let image: Image?
    let onClose: (() -> Void)?
    
    static func == (lhs: PopUpData, rhs: PopUpData) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.details == rhs.details
        // image и onClose не сравниваются, так как Image не Equatable и onClose — функция
    }
}

class PopUpState: ObservableObject {
    static let shared = PopUpState()
    @Published var stack: [PopUpData] = []
    
    func show(title: String, details: String? = nil, image: Image? = nil, onClose: (() -> Void)? = nil) {
        let data = PopUpData(title: title, details: details, image: image, onClose: onClose)
        stack.append(data)
    }
    
    func closeTop() {
        if let top = stack.last {
            top.onClose?()
        }
        if !stack.isEmpty {
            stack.removeLast()
        }
    }
    
    func next() {
        closeTop()
    }
}

struct PopUpOverlayView: View {
    @EnvironmentObject var state: PopUpState
    var body: some View {
        ZStack {
            if let top = state.stack.last {
                ZStack {
                    VStack(spacing: 16) {
                        if let image = top.image {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Text(top.title)
                            .font(Theme.headingLightFont)
                            .foregroundColor(Theme.textColor)
                            .multilineTextAlignment(.center)
                        if let details = top.details {
                            Text(details)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textColor)
                                .multilineTextAlignment(.center)
                        }
                        HStack(spacing: 16) {
                            if state.stack.count > 1 {
                                Button("Next") {
                                    state.next()
                                }
                                .buttonStyle(VampireButtonStyle())
                            } else {
                                Button("Close") {
                                    state.closeTop()
                                }
                                .buttonStyle(VampireButtonStyle())
                            }
                        }
                    }
                    .padding(20)
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.92))
                .cornerRadius(18)
                .shadow(radius: 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .frame(maxWidth: 400)
        .animation(.easeInOut, value: state.stack)
    }
} 
