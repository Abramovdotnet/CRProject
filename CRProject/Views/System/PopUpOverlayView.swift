import SwiftUI

enum PopUpImage: Equatable {
    case system(name: String, color: Color = Theme.textColor)
    case asset(name: String)
}

struct PopUpData: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let details: String?
    let image: PopUpImage?
    let onClose: (() -> Void)?
    
    static func == (lhs: PopUpData, rhs: PopUpData) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.details == rhs.details && lhs.image == rhs.image
    }
}

class PopUpState: ObservableObject {
    static let shared = PopUpState()
    @Published var stack: [PopUpData] = []
    
    func show(title: String, details: String? = nil, image: PopUpImage? = nil, onClose: (() -> Void)? = nil) {
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
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
            }
            ZStack {
                if let top = state.stack.last {
                    ZStack {
                        VStack(spacing: 16) {
                            if let image = top.image {
                                switch image {
                                case .system(let name, let color):
                                    Image(systemName: name)
                                        .renderingMode(.template)
                                        .font(.system(size: 48))
                                        .foregroundColor(color)
                                        .frame(width: 48, height: 48)
                                        .shadow(color: color.opacity(0.7), radius: 8, x: 0, y: 4)
                                case .asset(let name):
                                    Image(name)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: Theme.textColor.opacity(0.5), radius: 8, x: 0, y: 4)
                                }
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
                    .shadow(color: Theme.textColor.opacity(0.4), radius: 32, x: 0, y: 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1000)
                }
            }
            .frame(maxWidth: 400)
        }
        .animation(.easeInOut, value: state.stack)
    }
} 
