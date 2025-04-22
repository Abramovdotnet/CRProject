// 
//  DialogueView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import SwiftUI

// MARK: - DialogueView
struct DialogueView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: DialogueViewModel
    @ObservedObject var mainViewModel: MainSceneViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var backgroundOpacity = 0.0
    @State private var moonPhase: Double = 0.0
    @State private var contentOpacity = 0.0
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: UIImage(named: "location\(GameStateService.shared.currentScene!.id.description)") ?? UIImage(named: "MainSceneBackground")!)
                    .resizable()
                    .ignoresSafeArea()
                
                DustEmitterView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                       .edgesIgnoringSafeArea(.all)
                    
                // Dialogue Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Current Dialogue Text
                        HStack {
                            HorizontalPlayerWidget(player: GameStateService.shared.player!)
                            Spacer()
                            HorizontalNPCWidget(npc: viewModel.npc)
                        }
                        VStack {
                            HStack(spacing: 12) {
                                if !viewModel.currentDialogueText.isEmpty {
                                    Text("\(viewModel.npc.name): \(viewModel.currentDialogueText)")
                                        .font(Theme.smallFont)
                                }
                                Spacer()
                                
                                Image(systemName: viewModel.npc.sex == .female ? "figure.stand.dress" : "figure.wave")
                                    .font(Theme.smallFont)
                                    .foregroundColor(viewModel.npc.isVampire ? Theme.primaryColor : Theme.textColor)
                            }
                            .padding()
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .background(.black.opacity(0.9))
                        .cornerRadius(8)
                        
                        // Options
                        if !viewModel.options.isEmpty {
                            VStack {
                                ForEach(viewModel.options) { option in
                                    DialogueOptionButton(character: GameStateService.shared.player!, option: option) {
                                        viewModel.selectOption(option)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .opacity(contentOpacity)
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
                    /*HypnosisGameView(onComplete: { score in
                        viewModel.onHypnosisGameComplete(score: score)
                    }, npc: viewModel.npc)
                    .transition(.opacity.animation(.linear(duration: 0.2)))
                    .zIndex(2)
                    .ignoresSafeArea()*/
                }
            }
            .foregroundColor(Theme.textColor)
            .interactiveDismissDisabled(viewModel.showHypnosisGame)
            
            
            TopWidgetView(viewModel: mainViewModel)
                .frame(maxWidth: .infinity)
                .padding(.top, geometry.safeAreaInsets.top)
                .foregroundColor(Theme.textColor)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                backgroundOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                contentOpacity = 1
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                moonPhase = 1
            }
        }
    }
}

private struct DialogueOptionButton: View {
    let character: any Character
    let option: DialogueOption
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("\(character.name): \(option.text)")
                    .font(Theme.smallFont)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if option.type != .normal {
                    Image(systemName: option.type == .intimidate ? "exclamationmark.triangle" : "person.fill.questionmark")
                        .foregroundColor(option.type == .intimidate ? .red : .pink)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    .opacity(0.9)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
