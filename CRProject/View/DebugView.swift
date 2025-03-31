import SwiftUI

struct DebugView: View {
    @StateObject private var viewModel = DebugViewViewModel()
    @State private var showEndGame = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Debug Log
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Chronicle")
                            .font(.custom("Georgia", size: 24))
                            .foregroundColor(.red)
                        
                        ForEach(viewModel.debugPrompts, id: \.self) { prompt in
                            Text(prompt)
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(10)
                    
                    // Game Time Info
                    VStack(spacing: 15) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(viewModel.gameTime.description)
                                    .font(.custom("Georgia", size: 20))
                                    .foregroundColor(.white)
                                HStack {
                                    Text("Time of Day:")
                                        .font(.custom("Georgia", size: 16))
                                        .foregroundColor(.gray)
                                    Text(viewModel.gameTime.isNightTime ? "Night 🌙" : "Day ☀️")
                                        .font(.custom("Georgia", size: 16))
                                        .foregroundColor(viewModel.gameTime.isNightTime ? .purple : .orange)
                                }
                                Text("Location: \(viewModel.sceneReference.isIndoor ? "Indoor" : "Outdoor")")
                                    .font(.custom("Georgia", size: 16))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 10) {
                                Button("Summon NPCs") {
                                    viewModel.respawnNPCs()
                                }
                                .buttonStyle(VampireButtonStyle())
                                
                                Button("Purge Awareness") {
                                    viewModel.resetAwareness()
                                }
                                .buttonStyle(VampireButtonStyle(color: .purple))
                            }
                        }
                    }
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(10)
                    
                    // Scene Info
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Location: \(viewModel.sceneReference.name)")
                            .font(.custom("Georgia", size: 20))
                            .foregroundColor(.white)
                        Text("Mortals Present: \(viewModel.npcs.count)")
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(10)
                    
                    // Player Info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("The Vampire")
                                .font(.custom("Georgia", size: 24))
                                .foregroundColor(.red)
                            Spacer()
                            Text(viewModel.player.isAlive ? "Undead" : "Final Death")
                                .foregroundColor(viewModel.player.isAlive ? .green : .red)
                                .font(.custom("Georgia", size: 16))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            PlayerInfoRow(title: "Name", value: viewModel.player.name)
                            PlayerInfoRow(title: "Age", value: "\(viewModel.player.age) years")
                            PlayerInfoRow(title: "Profession", value: "\(viewModel.player.profession)")
                            PlayerInfoRow(title: "Sex", value: viewModel.player.sex == .male ? "Male" : "Female")
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Blood Reserves: \(Int(viewModel.playerBloodPercentage))%")
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(.red)
                            ProgressView(value: viewModel.playerBloodPercentage, total: 100)
                                .tint(.red)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Mortal Suspicion: \(Int(viewModel.sceneAwareness))%")
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(.purple)
                            ProgressView(value: viewModel.sceneAwareness, total: 100)
                                .tint(.purple)
                        }
                    }
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(10)
                    
                    // NPCs
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Mortals")
                            .font(.custom("Georgia", size: 24))
                            .foregroundColor(.red)
                        
                        ForEach(viewModel.npcs, id: \.id) { npc in
                            NPCView(npc: npc, viewModel: viewModel)
                        }
                    }
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(10)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showEndGame) {
            EndGameView(statistics: viewModel.statisticsService)
        }
        .onReceive(viewModel.vampireNatureRevealService.exposedPublisher) { _ in
            showEndGame = true
        }
    }
}

struct PlayerInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Georgia", size: 16))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.custom("Georgia", size: 16))
                .foregroundColor(.white)
        }
    }
}

struct NPCView: View {
    let npc: NPC
    @ObservedObject var viewModel: DebugViewViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if npc.isUnknown {
                    Text("Unknown Mortal")
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(.white)
                } else {
                    Text(npc.name)
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(.white)
                }
                Spacer()
                Text(npc.isAlive ? "Living" : "Deceased")
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(npc.isAlive ? .green : .red)
            }
            
            if npc.isUnknown {
                Text("Information Hidden")
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(.gray)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Age: \(npc.age)")
                    Text("Profession: \(npc.profession)")
                    Text("Sex: \(npc.sex == .male ? "Male" : "Female")")
                    
                    VStack(alignment: .leading) {
                        Text("Blood: \(Int(viewModel.npcBloodPercentages[npc.id] ?? 0))%")
                        ProgressView(value: viewModel.npcBloodPercentages[npc.id] ?? 0, total: 100)
                            .tint(.red)
                    }
                }
                .font(.custom("Georgia", size: 14))
                .foregroundColor(.gray)
            }
            
            HStack(spacing: 10) {
                if !npc.isUnknown {
                    Button("Feed") {
                        viewModel.feedOnNPC(npc)
                    }
                    .buttonStyle(VampireButtonStyle())
                }
                
                Button("Drain") {
                    viewModel.emptyNPCBlood(npc)
                }
                .buttonStyle(VampireButtonStyle(color: .red))
                
                if npc.isUnknown {
                    Button("Investigate") {
                        viewModel.investigateNPC(npc)
                    }
                    .buttonStyle(VampireButtonStyle(color: .blue))
                    .disabled(!viewModel.canInvestigateNPC(npc))
                }
            }
        }
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(8)
    }
}

struct VampireButtonStyle: ButtonStyle {
    var color: Color = .blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundColor(.white)
            .font(.custom("Georgia", size: 14))
            .cornerRadius(8)
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    DebugView()
} 
