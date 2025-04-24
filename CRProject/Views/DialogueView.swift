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
            let centralColumnWidth = geometry.size.width * 0.5
            let bubbleMaxWidth = centralColumnWidth * 0.95 // Max width for bubbles

            ZStack {
                // Background ZStack (Covers entire area)
                ZStack {
                    Image(uiImage: UIImage(named: "location\(GameStateService.shared.currentScene!.id.description)") ?? UIImage(named: "MainSceneBackground")!)
                        .resizable()
                        .ignoresSafeArea()
                    
                    DustEmitterView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                }
                
                // Main Layout HStack (Player | Spacer | Dialogue | Spacer | NPC)
                HStack(alignment: .top, spacing: 0) {
                    // Player Widget (Left Side)
                    PlayerWidget(player: GameStateService.shared.player!)
                        .frame(width: geometry.size.width * 0.23) // Adjusted width
                        .padding(.leading)
                        .padding(.top, 40) 

                    Spacer() // Pushes Dialogue View towards center
                        
                    // Dialogue ScrollView (Center)
                    ScrollView {
                        VStack(spacing: 12) { // Adjust spacing as needed
                            // NPC Text Bubble
                            if !viewModel.currentDialogueText.isEmpty {
                                HStack(alignment: .top, spacing: 8) { // NPC Bubble Content
                                    getNPCImage(npc: viewModel.npc)
                                        .resizable().frame(width: 30, height: 30).clipShape(RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("\(viewModel.npc.name):").font(Theme.bodyFont.weight(.semibold))
                                        Text(viewModel.currentDialogueText)
                                            .font(Theme.bodyFont)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(12)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(12)
                                // Apply max width first
                                .frame(maxWidth: bubbleMaxWidth)
                                // THEN align the sized bubble left
                                .frame(maxWidth: .infinity, alignment: .leading) 
                            }
                            
                            // Player Options
                            ForEach(viewModel.options) { option in
                                DialogueOptionButton(character: GameStateService.shared.player!, option: option) {
                                    viewModel.selectOption(option)
                                }
                                .frame(maxWidth: bubbleMaxWidth)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .id("option_\(option.id)") 
                                .transition(.opacity)
                            }
                        }
                       .padding(.horizontal, 10) 
                       .padding(.vertical, 20) 
                    }
                    .opacity(contentOpacity)
                    .frame(width: centralColumnWidth) 
                    .padding(.top, 20)
                    
                    Spacer() 
                    
                    // NPC Widget (Right Side)
                    NPCWidget(npc: viewModel.npc, isSelected: false, isDisabled: false, showCurrentActivity: false, onTap: { Void() }, onAction: { _ in Void ()})
                        .frame(width: geometry.size.width * 0.23) // Adjusted width
                        .padding(.trailing)
                        .padding(.top, 40) 
                    
                }
                .padding(.top, geometry.safeAreaInsets.top + 5)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 10)
                
                // Action Result Overlay (Centered on top)
                if viewModel.showActionResult {
                    VStack {
                        Text(viewModel.actionResultMessage)
                            .font(Theme.headingFont)
                            .foregroundColor(viewModel.actionResultSuccess ? .green : .red)
                            .padding()
                            .background(Theme.secondaryColor.opacity(0.9))
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    .zIndex(1) // Ensure it's above the main layout but below top widget/love scene
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.showActionResult)
                    .padding(.top, 50) // Position below TopWidget
                }
                
                // Top Widget - Rendered below Love Scene if active
                TopWidgetView(viewModel: mainViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, geometry.safeAreaInsets.top)
                    .foregroundColor(Theme.textColor)
                    .opacity(viewModel.showLoveScene ? 0 : 1) // Hide if LoveScene is shown
                    .zIndex(2) // Above Action Result

                // Love Scene Overlay - Now covers everything including TopWidget
                if viewModel.showLoveScene {
                    LoveScene()
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.showLoveScene)
                        .zIndex(3) // Ensure it's on top
                        .ignoresSafeArea() // Cover entire screen
                }
            }
            .foregroundColor(Theme.textColor) // Apply default text color to ZStack
            .interactiveDismissDisabled(viewModel.showHypnosisGame)
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
            // Add onChange to handle dismissal
            .onChange(of: viewModel.shouldDismiss) { newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
    
    private func getNPCImage(npc: NPC) -> Image {
        return Image(uiImage: UIImage(named: "npc\(npc.id.description)") ?? UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
    }
}

private struct DialogueOptionButton: View {
    let character: any Character
    let option: DialogueOption
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            // Ensure top alignment for consistency with NPC bubble
            HStack(alignment: .top, spacing: 8) {
                getCharacterImage()
                    .resizable()
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(character.name):")
                        .font(Theme.bodyFont.weight(.semibold))
                    
                    Text(option.text)
                        .font(Theme.bodyFont)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if option.type != .normal {
                    Spacer()
                    getInteractionIcon()
                        .foregroundColor(getIconColor())
                }
            }
            .padding(12) 
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getInteractionIcon() -> Image {
        switch option.type {
        case .intimidate:
            return Image(systemName: "exclamationmark.triangle")
        case .investigate:
            return Image(systemName: "person.fill.questionmark")
        case .normal:
            return Image(systemName: "message.fill")
        case .seduce:
            return Image(systemName: "heart.fill")
        case .intrigue:
            return Image(systemName: "heart.fill")
        case .loveForSail:
            return Image(systemName: "heart.fill")
        case .relationshipIncrease:
            return Image(systemName: "arrow.up.heart.fill")
        case .relationshipDecrease:
            return Image(systemName: "arrow.down.heart.fill")
        }
    }
    
    private func getIconColor() -> Color {
        switch option.type {
        case .intimidate:
            return .red
        case .investigate:
            return .blue
        case .normal:
            return .white
        case .seduce:
            return .pink
        case .intrigue:
            return .purple
        case .loveForSail:
            return .pink
        case .relationshipIncrease:
            return .green
        case .relationshipDecrease:
            return .red
        }
    }
    
    private func getCharacterImage() -> Image {
        if character is Player {
            return Image("player1")
        } else {
            return Image(uiImage: UIImage(named: "npc\(character.id.description)") ?? UIImage(named: character.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
        }
    }
}
