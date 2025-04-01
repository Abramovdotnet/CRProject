import SwiftUI

struct DebugView: View {
    @ObservedObject var viewModel: DebugViewViewModel
    
    var body: some View {
        ZStack {
            Theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Top Widget
                TopWidgetView(viewModel: viewModel)
                
                // Main Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Location Info
                        LocationInfoView(scene: viewModel.currentScene, viewModel: viewModel)
                        
                        // Navigation
                        NavigationView(viewModel: viewModel)
                        
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
    let viewModel: DebugViewViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 0)
        {
            VStack(alignment: .leading, spacing: 8) {
                Text(scene?.name ?? "Unknown Location")
                    .font(Theme.titleFont)
                if let description = scene?.name {
                    Text(description)
                        .font(Theme.bodyFont)
                }
            }
            Spacer()
            VStack(alignment: .center, spacing: 8) {
                Text("Characters: ")
                    .font(Theme.titleFont)
                if let isIndoors = scene?.isIndoor {
                    Text("Is indoors: " + ( isIndoors ? " Yes" : " No"))
                        .font(Theme.bodyFont)
                }
            }
        }
    }
}

// MARK: - Navigation
private struct NavigationView: View {
    @ObservedObject var viewModel: DebugViewViewModel
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                VStack(spacing: 12) {
                    // Parent Location
                    if let parentScene = viewModel.parentScene {
                        Button(action: { viewModel.navigateToParent() }) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title2)
                                Text("To \(parentScene.name)")
                                    .font(Theme.bodyFont)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Theme.secondaryColor)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Child Locations
                    ForEach(viewModel.childScenes, id: \.id) { scene in
                        Button(action: { viewModel.navigateToChild(scene) }) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title2)
                                Text("To \(scene.name)")
                                    .font(Theme.bodyFont)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Theme.secondaryColor)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Sibling Locations
                    ForEach(viewModel.siblingScenes, id: \.id) { scene in
                        Button(action: { viewModel.navigateToSibling(scene) }) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                                Text("To \(scene.name)")
                                    .font(Theme.bodyFont)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Theme.secondaryColor)
                            .cornerRadius(8)
                        }
                    }
                }
            },
            label: {
                HStack {
                    Text("Navigation")
                        .font(Theme.headingFont)
                    Spacer()
                    Text("\(viewModel.childScenes.count + viewModel.siblingScenes.count + (viewModel.parentScene != nil ? 1 : 0)) locations")
                        .font(Theme.bodyFont)
                        .foregroundColor(.gray)
                }
            }
        )
        .padding()
        .background(Theme.secondaryColor)
        .cornerRadius(8)
    }
}

// MARK: - NPCs List
private struct NPCsListView: View {
    @ObservedObject var viewModel: DebugViewViewModel
    @State private var selectedNPC: NPC?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Characters")
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
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textColor)
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
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Awareness: \(Int(viewModel.sceneAwareness))%")
                    .font(Theme.bodyFont)
                ProgressBar(value: Double(viewModel.sceneAwareness / 100.0), color: Theme.awarenessProgressColor)
            }
        }
        .padding()
        .background(Theme.secondaryColor)
    }
}

#Preview {
    DebugView(viewModel: DebugViewViewModel())
} 
