import SwiftUI

// MARK: - Location Info
struct LocationInfoView: View {
    let scene: Scene?
    @ObservedObject var viewModel: MainSceneViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressBar(value: Double(viewModel.sceneAwareness / 100.0), color: Theme.awarenessProgressColor)
            Text("Awareness: \(Int(viewModel.sceneAwareness))%")
                .font(Theme.bodyFont)
        }
    }
}

// MARK: - Location Navigation View
struct LocationNavigationView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    @State private var showLocationDetails: Bool = false
    @State private var selectedLocation: Scene?
    
    var body: some View {
        VStack(spacing: 0) {
            // Current Location Header
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(Theme.accentColor)
                Text(viewModel.currentScene?.name ?? "Unknown Location")
                    .font(Theme.headingFont)
                Spacer()
            }
            .padding()
            .background(Theme.secondaryColor)
            
            // Navigation Options
            ScrollView {
                VStack(spacing: 16) {
                    // Parent Location (Return)
                    if let parent = viewModel.parentScene {
                        LocationButton(
                            location: parent,
                            type: .parent,
                            action: { viewModel.navigateToParent() }
                        )
                    }
                    
                    // Nearby Locations (Siblings)
                    if !viewModel.siblingScenes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nearby Locations")
                                .font(Theme.subheadingFont)
                                .foregroundColor(Theme.textColor.opacity(0.7))
                            
                            ForEach(viewModel.siblingScenes) { scene in
                                LocationButton(
                                    location: scene,
                                    type: .sibling,
                                    action: { viewModel.navigateToSibling(scene) }
                                )
                            }
                        }
                    }
                    
                    // Explorable Areas (Children)
                    if !viewModel.childScenes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Explorable Areas")
                                .font(Theme.subheadingFont)
                                .foregroundColor(Theme.textColor.opacity(0.7))
                            
                            ForEach(viewModel.childScenes) { scene in
                                LocationButton(
                                    location: scene,
                                    type: .child,
                                    action: { viewModel.navigateToChild(scene) }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Theme.backgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Location Button
struct LocationButton: View {
    let location: Scene
    let type: LocationType
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
            .padding()
            .background(Theme.secondaryColor.opacity(0.5))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
