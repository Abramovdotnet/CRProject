import SwiftUI

struct DebugView: View {
    @ObservedObject var viewModel: DebugViewViewModel
    @State private var showingNavigation = false
    
    var body: some View {
        if viewModel.isGameEnd {
            EndGameView()
        } else {
            ZStack {
                Image("MainSceneBackground")
                    .resizable()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Widget - will now stick to top
                    TopWidgetView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .background(Color.clear) // Optional: add background if needed
                    
                    // Main Content Area
                    HStack(alignment: .top, spacing: 20) {  // Changed to .top alignment
                        // NPCs List
                        CircularNPCView(npcs: viewModel.npcs)
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
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
                        }
                        .padding()
                    }
                    .frame(maxHeight: .infinity)  // Allow content to expand
                }
            }
            .foregroundColor(Theme.textColor)
            .sheet(isPresented: $showingNavigation) {
                NavigationDetailView(viewModel: viewModel)
            }
        }
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
    @State private var showingDialogue = false
    
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
                    Button("Investigate") {
                        viewModel.investigateNPC(npc)
                    }
                    .buttonStyle(VampireButtonStyle())
                    .disabled(!viewModel.canInvestigateNPC(npc))
                    
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
                        
                        Button("Dialogue") {
                            showingDialogue = true
                        }
                        .buttonStyle(VampireButtonStyle())
                        
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
        .sheet(isPresented: $showingDialogue) {
            if let player = viewModel.gameStateService.getPlayer() {
                DialogueView(viewModel: DialogueViewModel(npc: npc, player: player))
            }
        }
    }
}

// MARK: - Bottom Widget
private struct BottomWidgetView: View {
    @ObservedObject var viewModel: DebugViewViewModel
    
    var body: some View {
        HStack {
            Text("Debug:")
                .font(Theme.bodyFont)
            
            Spacer()
            
            Text("Blood: \(Int(viewModel.playerBloodPercentage))%")
                .font(Theme.bodyFont)
            
        }
        .padding(.top, 5)
        .padding(.bottom, 5)
    }
}

#Preview {
    DebugView(viewModel: DebugViewViewModel())
} 
