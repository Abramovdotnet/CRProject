import SwiftUI

struct DebugView: View {
    @StateObject private var viewModel = DebugViewViewModel()
    @State private var showEndGame = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Debug Log (at the top)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Debug Log")
                        .font(.headline)
                    
                    ForEach(viewModel.debugPrompts, id: \.self) { prompt in
                        Text(prompt)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Game Time Info with Respawn Button
                HStack {
                    VStack(alignment: .leading) {
                        Text("Game Time: \(viewModel.gameTime.description)")
                            .font(.headline)
                        HStack {
                            Text("Is Night: \(viewModel.gameTime.isNightTime ? "Yes" : "No")")
                                .font(.subheadline)
                            Text(viewModel.gameTime.isNightTime ? "🌙" : "☀️")
                                .font(.title2)
                        }
                        Text("Is indoor: \(viewModel.sceneReference.isIndoor ? "Yes" : "No")")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button("Respawn NPCs") {
                            viewModel.respawnNPCs()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Reset Awareness") {
                            viewModel.resetAwareness()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                // Scene Info
                VStack(alignment: .leading) {
                    Text("Scene: \(viewModel.sceneReference.name)")
                        .font(.headline)
                    Text("Characters: \(viewModel.sceneReference.getCharacters().count)")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                // Player Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Player")
                            .font(.headline)
                        Spacer()
                        Text(viewModel.player.isAlive ? "Alive" : "Dead")
                            .foregroundColor(viewModel.player.isAlive ? .green : .red)
                    }
                    
                    Text("Name: \(viewModel.player.name)")
                    Text("Age: \(viewModel.player.age)")
                    Text("Profession: \(viewModel.player.profession)")
                    Text("Sex: \(viewModel.player.sex == .male ? "Male" : "Female")")
                    Text("Is Vampire: \(viewModel.player.isVampire ? "Yes" : "No")")
                    
                    VStack(alignment: .leading) {
                        Text("Blood Level: \(Int(viewModel.playerBloodPercentage))%")
                        ProgressView(value: viewModel.playerBloodPercentage, total: 100)
                            .tint(.red)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Vampire Nature Awareness: \(Int(viewModel.sceneAwareness))%")
                        ProgressView(value: viewModel.sceneAwareness, total: 100)
                            .tint(.purple)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                
                // NPCs
                VStack(alignment: .leading, spacing: 15) {
                    Text("NPCs")
                        .font(.headline)
                    
                    ForEach(viewModel.npcs, id: \.id) { npc in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                if npc.isUnknown {
                                    HStack {
                                        Text("Info:")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                        Text("Hidden")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                    }
                                } else {
                                    Text("\(npc.name)")
                                        .font(.headline)
                                }
                                Spacer()
                                Text(npc.isAlive ? "Alive" : "Dead")
                                    .foregroundColor(npc.isAlive ? .green : .red)
                            }
                            
                            if npc.isUnknown {
                                    Text("Sex: \(npc.sex == .male ? "Male" : "Female")")
                                }
                                else {
                                    Text("Age: \(npc.age)")
                                    Text("Profession: \(npc.profession)")
                                    Text("Is Vampire: \(npc.isVampire ? "Yes" : "No")")
                                    
                                    VStack(alignment: .leading) {
                                        Text("Blood Level: \(Int(viewModel.npcBloodPercentages[npc.id] ?? 0))%")
                                        ProgressView(value: viewModel.npcBloodPercentages[npc.id] ?? 0, total: 100)
                                            .tint(.red)
                                }
                            }
                            
                            HStack {
                                if !npc.isUnknown {
                                    Button("Feed on \(npc.name)") {
                                        viewModel.feedOnNPC(npc)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(!npc.isAlive)
                                }
                                
                                Button("Empty Blood") {
                                    viewModel.emptyNPCBlood(npc)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(!npc.isAlive)
                                
                                if npc.isUnknown {
                                    Button("Investigate") {
                                        viewModel.investigateNPC(npc)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.blue)
                                    .disabled(!viewModel.canInvestigateNPC(npc) || !npc.isAlive)
                                }
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showEndGame) {
            EndGameView(statistics: viewModel.statisticsService)
        }
        .onReceive(viewModel.vampireNatureRevealService.exposedPublisher) { _ in
            showEndGame = true
        }
    }
}

#Preview {
    DebugView()
} 
