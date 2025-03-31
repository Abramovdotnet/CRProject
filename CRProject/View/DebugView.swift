import SwiftUI

struct DebugView: View {
    @StateObject private var viewModel = DebugViewViewModel()
    
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
                        Text("Is Night: \(viewModel.gameTime.isNightTime ? "Yes" : "No")")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    Button("Respawn NPCs") {
                        viewModel.respawnNPCs()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                // Scene Info
                VStack(alignment: .leading) {
                    Text("Scene: \(viewModel.currentScene.name)")
                        .font(.headline)
                    Text("Characters: \(viewModel.currentScene.getCharacters().count)")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                // Player Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Player")
                            .font(.title2)
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
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                
                // NPCs
                VStack(alignment: .leading, spacing: 15) {
                    Text("NPCs")
                        .font(.title2)
                    
                    ForEach(viewModel.npcs, id: \.id) { npc in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Name: \(npc.name)")
                                    .font(.headline)
                                Spacer()
                                Text(npc.isAlive ? "Alive" : "Dead")
                                    .foregroundColor(npc.isAlive ? .green : .red)
                            }
                            
                            Text("Age: \(npc.age)")
                            Text("Profession: \(npc.profession)")
                            Text("Sex: \(npc.sex == .male ? "Male" : "Female")")
                            Text("Is Vampire: \(npc.isVampire ? "Yes" : "No")")
                            
                            VStack(alignment: .leading) {
                                Text("Blood Level: \(Int(viewModel.npcBloodPercentages[npc.id] ?? 0))%")
                                ProgressView(value: viewModel.npcBloodPercentages[npc.id] ?? 0, total: 100)
                                    .tint(.red)
                            }
                            
                            Button("Feed on \(npc.name)") {
                                viewModel.feedOnNPC(npc)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!npc.isAlive)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    DebugView()
} 