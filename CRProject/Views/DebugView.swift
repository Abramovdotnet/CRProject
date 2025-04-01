import SwiftUI

struct DebugView: View {
    @ObservedObject var viewModel: DebugViewViewModel
    @State private var showingNavigation = false
    
    var body: some View {
        ZStack {
            Theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Top Widget
                TopWidgetView(viewModel: viewModel)
                
                // Main Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Navigation Button
                        Button(action: { showingNavigation = true }) {
                            HStack {
                                Image(systemName: "moon.stars.fill")
                                    .foregroundColor(Theme.accentColor)
                                Text(viewModel.currentScene?.name ?? "Unknown")
                                    .font(Theme.bodyFont)
                                Spacer()
                                Text("\(viewModel.childScenes.count + viewModel.siblingScenes.count + (viewModel.parentScene != nil ? 1 : 0)) locations")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textColor.opacity(0.7))
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Theme.textColor.opacity(0.5))
                            }
                            .padding()
                            .background(Theme.secondaryColor)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Location Info
                        LocationInfoView(scene: viewModel.currentScene, viewModel: viewModel)
                        
                        // NPCs List
                        NPCsListView(viewModel: viewModel)
                    }
                    .padding()
                }
                
                // Bottom Widget
                BottomWidgetView(viewModel: viewModel)
            }
        }
        .foregroundColor(Theme.textColor)
        .sheet(isPresented: $showingNavigation) {
            NavigationDetailView(viewModel: viewModel)
        }
    }
}

// MARK: - Top Widget
private struct TopWidgetView: View {
    @ObservedObject var viewModel: DebugViewViewModel
    
    var body: some View {
        HStack {
            // World Info
            VStack(alignment: .leading) {
                Text("Day \(viewModel.currentDay)")
                    .font(Theme.headingFont)
                Text("\(viewModel.currentHour):00")
                    .font(Theme.bodyFont)
                if let isIndoors = viewModel.currentScene?.isIndoor {
                    Text("Is indoors: " + ( isIndoors ? " Yes" : " No"))
                        .font(Theme.bodyFont)
                }
            }
            
            Spacer()
            
            // Day/Night Indicator
            Image(systemName: viewModel.isNight ? "moon.fill" : "sun.max.fill")
                .font(.title)
                .foregroundColor(viewModel.isNight ? .white : .yellow)
            
            Spacer()
            
            // Control Buttons
            HStack(spacing: 10) {
                Button("R") {
                    viewModel.respawnNPCs()
                }
                .buttonStyle(VampireButtonStyle())
                
                Button("A") {
                    viewModel.resetAwareness()
                }
                .buttonStyle(VampireButtonStyle())
            }
        }
        .padding()
        .background(Theme.secondaryColor)
    }
}

// MARK: - Location Info
private struct LocationInfoView: View {
    let scene: Scene?
    @ObservedObject var viewModel: DebugViewViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location awareness: \(Int(viewModel.sceneAwareness))%")
                .font(Theme.bodyFont)
            
            ProgressBar(value: Double(viewModel.sceneAwareness / 100.0), color: Theme.awarenessProgressColor)
        }
    }
}

// MARK: - Location Navigation View
private struct LocationNavigationView: View {
    @ObservedObject var viewModel: DebugViewViewModel
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
private struct LocationButton: View {
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

// MARK: - NPCs List
private struct NPCsListView: View {
    @ObservedObject var viewModel: DebugViewViewModel
    @State private var selectedNPC: NPC?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Characters : \(viewModel.npcs.count)")
                .font(Theme.headingFont)
            
            if let selectedNPC = selectedNPC {
                NPCInfoView(npc: selectedNPC, viewModel: viewModel) {
                    self.selectedNPC = nil
                }
            } else {
                ForEach(viewModel.npcs, id: \.id) { npc in
                    Button(action: { selectedNPC = npc }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                if npc.isUnknown {
                                    Text("Sex: \(npc.sex)")
                                    Spacer()
                                    Text("Info: hidden")
                                        .foregroundColor(.gray)
                                } else {
                                    Text(npc.name)
                                        .font(Theme.bodyFont)
                                    Spacer()
                                    Text("\(npc.age) y.o. \(npc.profession)")
                                        .font(Theme.bodyFont)
                                }
                                Spacer()
                                Text(npc.isAlive ? "Alive" : "Dead")
                                    .foregroundColor(npc.isAlive ? .green : .red)
                            }
                            
                            if !npc.isUnknown {
                                ProgressBar(value: Double(npc.bloodMeter.bloodPercentage / 100), color: Theme.bloodProgressColor)
                            }
                        }
                        .padding()
                        .background(Theme.secondaryColor)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// MARK: - NPC Info
private struct NPCInfoView: View {
    let npc: NPC
    @ObservedObject var viewModel: DebugViewViewModel
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Status")
                    .font(Theme.headingFont)
                Spacer()
                Text(npc.isAlive ? "Alive" : "Dead")
                    .foregroundColor(npc.isAlive ? .green : .red)
                Button(action: onClose) {
                    Image(systemName: "chevron.up")
                        .foregroundColor(Theme.textColor.opacity(0.5))
                }
            }
            
            if npc.isUnknown {
                HStack {
                    Text("Sex: \(npc.sex)")
                    Spacer()
                    Text("Info: hidden")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    
                    if npc.isUnknown {
                        Button("Investigate") {
                            viewModel.investigateNPC(npc)
                        }
                        .buttonStyle(VampireButtonStyle())
                        .disabled(!viewModel.canInvestigateNPC(npc))
                    }
                    
                    Spacer()
                    
                    if npc.isAlive {
                        Button("Drain") {
                            viewModel.emptyBloodFromCharacter(npc)
                        }
                        .buttonStyle(VampireButtonStyle())
                        .disabled(!viewModel.canFeedOnCharacter(npc))
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(npc.name)
                        .font(Theme.bodyFont)
                    Text("\(npc.age) y.o. \(npc.profession)")
                        .font(Theme.bodyFont)
                    
                    ProgressBar(value: Double(npc.bloodMeter.bloodPercentage / 100), color: Theme.bloodProgressColor)
                }
                
                if npc.isAlive {
                    HStack {
                        Button("Feed") {
                            viewModel.feedOnCharacter(npc)
                        }
                        .buttonStyle(VampireButtonStyle())
                        .disabled(!viewModel.canFeedOnCharacter(npc))
                        
                        Spacer()
                        
                        Button("Drain") {
                            viewModel.emptyBloodFromCharacter(npc)
                        }
                        .buttonStyle(VampireButtonStyle())
                        .disabled(!viewModel.canFeedOnCharacter(npc))
                    }
                }
            }
        }
        .padding()
        .background(Theme.secondaryColor)
        .cornerRadius(8)
    }
}

// MARK: - Bottom Widget
private struct BottomWidgetView: View {
    @ObservedObject var viewModel: DebugViewViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(viewModel.playerName)
                    .font(Theme.headingFont)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Blood: \(Int(viewModel.playerBloodPercentage))%")
                    .font(Theme.bodyFont)
                ProgressBar(value: Double(viewModel.playerBloodPercentage / 100.0), color: Theme.bloodProgressColor)
            }
        }
        .padding()
        .background(Theme.secondaryColor)
    }
}

#Preview {
    DebugView(viewModel: DebugViewViewModel())
} 
