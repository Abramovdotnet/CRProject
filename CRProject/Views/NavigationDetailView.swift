import SwiftUI

struct NavigationDetailView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Image("MainSceneBackground")
                .resizable()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Navigation")
                        .font(Theme.headingFont)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.textColor.opacity(0.7))
                            .font(.title2)
                    }
                }
                .padding()
                .background(Theme.secondaryColor)
                
                // Navigation Content
                ScrollView {
                    HStack(alignment: .top, spacing: 20) {
                        // Parent Location Column
                        if let parent = viewModel.parentScene {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Return")
                                    .font(Theme.subheadingFont)
                                    .foregroundColor(Theme.textColor.opacity(0.7))
                                
                                NavigationButton(
                                    location: parent,
                                    type: .parent,
                                    awareness: viewModel.getLocationAwareness(parent),
                                    action: {
                                        viewModel.navigateToParent()
                                        dismiss()
                                    }
                                )
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Nearby Locations Column
                        if !viewModel.siblingScenes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nearby Locations")
                                    .font(Theme.subheadingFont)
                                    .foregroundColor(Theme.textColor.opacity(0.7))
                                
                                ForEach(viewModel.siblingScenes.sorted(by: { 
                                    viewModel.getLocationAwareness($0) > viewModel.getLocationAwareness($1) 
                                })) { scene in
                                    NavigationButton(
                                        location: scene,
                                        type: .sibling,
                                        awareness: viewModel.getLocationAwareness(scene),
                                        action: {
                                            viewModel.navigateToSibling(scene)
                                            dismiss()
                                        }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Explorable Areas Column
                        if !viewModel.childScenes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Explorable Areas")
                                    .font(Theme.subheadingFont)
                                    .foregroundColor(Theme.textColor.opacity(0.7))
                                
                                ForEach(viewModel.childScenes.sorted(by: { 
                                    viewModel.getLocationAwareness($0) > viewModel.getLocationAwareness($1) 
                                })) { scene in
                                    NavigationButton(
                                        location: scene,
                                        type: .child,
                                        awareness: viewModel.getLocationAwareness(scene),
                                        action: {
                                            viewModel.navigateToChild(scene)
                                            dismiss()
                                        }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    NavigationDetailView(viewModel: MainSceneViewModel())
}

private struct NavigationButton: View {
    let location: Scene
    let type: LocationType
    let awareness: Float
    let action: () -> Void
    
    enum LocationType {
        case parent
        case sibling
        case child
        
        var icon: String {
            switch self {
            case .parent: "arrow.up.circle.fill"
            case .sibling: "arrow.right.circle.fill"
            case .child: "arrow.down.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .parent: .blue
            case .sibling: .purple
            case .child: .green
            }
        }
        
        var label: String {
            switch self {
            case .parent: "Return to"
            case .sibling: "Go to"
            case .child: "Enter"
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: type.icon)
                        .foregroundColor(type.color)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(type.label) \(location.name)")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                        
                        Text(location.isIndoor ? "Indoor Location" : "Outdoor Location")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textColor.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.textColor.opacity(0.5))
                }
                
                // Awareness bar
                VStack(alignment: .leading, spacing: 4) {
                    Text("Awareness: \(Int(awareness))%")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textColor.opacity(0.7))
                    ProgressBar(value: Double(awareness / 100.0), color: Theme.awarenessProgressColor)
                }
            }
            .padding()
            .background(Theme.secondaryColor.opacity(0.5))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
