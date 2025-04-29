import SwiftUI

class PopUpManager: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var message: String = ""
    @Published var icon: String? = nil

    func show(message: String, icon: String? = nil, duration: Double = 2.0) {
        self.message = message
        self.icon = icon
        withAnimation {
            self.isPresented = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                self.isPresented = false
            }
        }
    }
} 