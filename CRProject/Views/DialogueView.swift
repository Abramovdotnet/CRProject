import SwiftUI

struct DialogueView: View {
    @ObservedObject var viewModel: DialogueViewModel
    @ObservedObject var mainViewModel: MainSceneViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("MainSceneBackground")
                    .resizable()
                    .ignoresSafeArea()
                    
                // Dialogue Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Current Dialogue Text
                        VStack {
                            HStack {
                                VStack(alignment: .center, spacing: 4) {
                                    if !viewModel.npc.isUnknown {
                                        HStack(spacing: 4) {
                                            Image(systemName: viewModel.npc.sex == .female ? "figure.stand.dress" : "figure.wave")
                                                .font(Theme.bodyFont)
                                                .foregroundColor(viewModel.npc.isVampire ? Theme.primaryColor : Theme.textColor)
                                            
                                            Image(systemName: viewModel.npc.profession.icon)
                                                .font(Theme.bodyFont)
                                                .foregroundColor(viewModel.npc.profession.color)
                                        }
                                        .offset(y: -2)
                                        
                                        // Blood meter
                                        HStack(spacing: 1) {
                                            ForEach(0..<5) { index in
                                                let segmentValue = Double(viewModel.npc.bloodMeter.currentBlood) / 100.0
                                                let segmentThreshold = Double(index + 1) / 5.0
                                                
                                                Rectangle()
                                                    .fill(segmentValue >= segmentThreshold ?
                                                          Theme.bloodProgressColor : Color.black.opacity(0.3))
                                                    .frame(height: 2)
                                            }
                                        }
                                        .frame(width: 30)
                                    }
                                }
                                .padding(.top, 10)
                                .padding(.horizontal, 10)
                                
                                if viewModel.npc.isSleeping {
                                    Image(systemName: "moon.zzz.fill")
                                        .foregroundColor(.blue)
                                        .font(Theme.bodyFont)
                                }
                                if viewModel.npc.isIntimidated {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(Theme.bloodProgressColor)
                                        .font(Theme.bodyFont)
                                }
                                if !viewModel.npc.isUnknown {
                                    Text(viewModel.npc.name)
                                        .font(Theme.bodyFont)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                if !viewModel.npc.isUnknown {
                                    Text("\(viewModel.npc.profession.rawValue)")
                                        .font(Theme.bodyFont)
                                        .foregroundColor(viewModel.npc.profession.color)
                                        .lineLimit(1)
                                }
                                Image(systemName: "waveform.path.ecg")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(viewModel.npc.isAlive ? .green : Theme.primaryColor)
                                
                                Text(viewModel.npc.isUnknown ? "Unknown" : viewModel.npc.isVampire ? "Vampire" : "Mortal")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(viewModel.npc.isVampire ? Theme.primaryColor : .green)
                            }
                            
                            if !viewModel.currentDialogueText.isEmpty {
                                Text(viewModel.currentDialogueText)
                                    .font(Theme.bodyFont)
                                    .padding(5)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.primaryColor.opacity(0.5))
                        .cornerRadius(8)
                        
                        // Options
                        if !viewModel.options.isEmpty {
                            VStack {
                                ForEach(viewModel.options) { option in
                                    DialogueOptionButton(option: option) {
                                        viewModel.selectOption(option)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .padding(.top, 10)
                
                // Action Result Overlay
                if viewModel.showActionResult {
                    VStack {
                        Text(viewModel.actionResultMessage)
                            .font(Theme.headingFont)
                            .foregroundColor(viewModel.actionResultSuccess ? .green : .red)
                            .padding()
                            .background(Theme.secondaryColor)
                            .cornerRadius(8)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.showActionResult)
                }
                
                // Hypnosis Game Overlay
                if viewModel.showHypnosisGame {
                    HypnosisGameView(onComplete: { score in
                        viewModel.onHypnosisGameComplete(score: score)
                    }, npc: viewModel.npc)
                    .transition(.opacity.animation(.linear(duration: 0.2)))
                    .zIndex(2)
                    .ignoresSafeArea()
                }
            }
            .foregroundColor(Theme.textColor)
            .interactiveDismissDisabled(viewModel.showHypnosisGame)
            
            
            TopWidgetView(viewModel: mainViewModel)
                .frame(maxWidth: .infinity)
                .padding(.top, geometry.safeAreaInsets.top)
                .foregroundColor(Theme.textColor)
        }
    }
}

private struct DialogueOptionButton: View {
    let option: DialogueOption
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option.text)
                    .font(Theme.bodyFont)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if option.type != .normal {
                    Image(systemName: option.type == .intimidate ? "exclamationmark.triangle" : "heart")
                        .foregroundColor(option.type == .intimidate ? .red : .pink)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.5))
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    .opacity(0.9)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
