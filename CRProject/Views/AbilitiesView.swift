//
//  AbilitiesView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 29.04.2025.
//

import SwiftUICore
import UIKit
import SwiftUI
import Combine


struct AbilitiesView: View {
    let scene: Scene
    let mainViewModel: MainSceneViewModel
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var abilitiesSystem = AbilitiesSystem.shared
    @ObservedObject private var statisticsService = StatisticsService.shared
    
    @State private var backgroundOpacity = 0.0
    @State private var contentOpacity = 0.0
    @State private var moonPhase: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundView(scene: scene)
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    // Top widget
                    TopWidgetView(viewModel: mainViewModel)
                        .frame(height: 35)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .padding(.top, geometry.safeAreaInsets.top)
                        .foregroundColor(Theme.textColor)
                    
                    // Main content
                    mainContentView(geometry: geometry)
                        .padding(.top, 10) // Добавляем небольшой отступ от виджета
                }
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
    
    private func backgroundView(scene: Scene) -> some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            Image("vampiricWall")
                .resizable()
                .ignoresSafeArea()
                .opacity(0.7)
            
            // Blood moon effect
            BloodMoonEffect(phase: moonPhase)
                .opacity(backgroundOpacity * 0.8)
                .ignoresSafeArea()
          
            // Blood mist effect with fixed animation instead of TimelineView
            CustomBloodMistEffect()
                .opacity(0.4)
                .ignoresSafeArea()
                
            DustEmitterView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
        }
    }
                
    private func topBar(geometry: GeometryProxy) -> some View {
        TopWidgetView(viewModel: mainViewModel)
            .frame(height: 35)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, geometry.safeAreaInsets.top)
            .foregroundColor(Theme.textColor)
            .allowsHitTesting(false)
    }
    
    private func mainContentView(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 20) {
            // Left side - Abilities with progress (increased width)
            abilitiesListView()
                .frame(maxWidth: geometry.size.width * 0.65)
            
            // Right side - Statistics (decreased width)
            statisticsView()
                .frame(maxWidth: geometry.size.width * 0.35)
        }
        .padding(.horizontal)
        .padding(.bottom)
        .opacity(contentOpacity)
    }
    
    private func mainContentBackground() -> some View {
        // This method is no longer needed
        EmptyView()
    }
    
    // Abilities List with Progress
    private func abilitiesListView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed title without background
            Text("Vampire Abilities")
                .font(Theme.headingLightFont)
                .foregroundColor(Color.red)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider to separate title from content
            Divider()
                .background(Color.red.opacity(0.4))
            
            // Scrollable content with hidden scrollbar
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    abilitiesSectionView(title: "Vampiric Powers", abilities: [.seduction, .domination, .whisper, .enthralling, .command, .invisibility, .dayWalker, .lordOfBlood, .darkness, .memoryErasure, .sonOfDracula, .ghost, .insight, .dreamstealer, .kingSalamon])
                    
                    abilitiesSectionView(title: "Crafting Skills", abilities: [.smithingNovice, .smithingApprentice, .smithingExpert, .smithingMaster, .alchemyNovice, .alchemyApprentice, .alchemyExpert, .alchemyMaster])
                    
                    abilitiesSectionView(title: "Social Skills", abilities: [.bribe, .trader, .masquerade, .unholyTongue, .mysteriousPerson, .oldFriend, .undeadCasanova, .lionAmongSheep, .noble])
                }
                .padding()
            }
        }
        .cornerRadius(12)
    }
    
    private func abilitiesSectionView(title: String, abilities: [Ability]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Theme.bodyFont)
                .foregroundColor(Color.white.opacity(0.9))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.black.opacity(0.45))
                .cornerRadius(8)
            
            ForEach(abilities, id: \.self) { ability in
                abilityItemView(ability: ability)
            }
        }
    }
    
    private func abilityItemView(ability: Ability) -> some View {
        let isUnlocked = abilitiesSystem.playerAbilities.contains(ability)
        let progress = calculateProgress(for: ability)
        
        return VStack(alignment: .leading, spacing: 4) {
            abilityHeaderView(ability: ability, isUnlocked: isUnlocked)
            abilityProgressView(ability: ability, progress: progress)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(isUnlocked ? 0.6 : 0.45))
                .shadow(color: isUnlocked ? ability.color.opacity(0.5) : Color.gray.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
    
    private func abilityHeaderView(ability: Ability, isUnlocked: Bool) -> some View {
        HStack {
            Image(systemName: ability.icon)
                .foregroundColor(ability.color)
                .frame(width: 30, height: 30)
                .shadow(color: ability.color.opacity(0.7), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(ability.name)
                    .font(Theme.bodyFont)
                    .foregroundColor(isUnlocked ? Color.white : Color.white.opacity(0.6))
                
                Text(ability.description)
                    .font(Theme.bodyFont.weight(.light))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .shadow(color: Color.green.opacity(0.5), radius: 6, x: 0, y: 3)
            }
        }
    }
    
    private func abilityProgressView(ability: Ability, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Requirement text
            Text(ability.requirement)
                .font(Theme.bodyFont.weight(.light).italic())
                .foregroundColor(Color.white.opacity(0.6))
                .padding(.bottom, 4)
            
            // Detailed subrequirements
            subrequirementsView(for: ability)
            
            // Progress bar
            ZStack(alignment: .leading) {
                // Background bar
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                // Progress bar with fixed width calculation
                progressFillBar(progress: progress)
            }
        }
    }
    
    private func subrequirementsView(for ability: Ability) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            switch ability {
            case .seduction:
                subrequirementRow(label: "Sleeping victims", current: statisticsService.feedingsOverSleepingVictims, required: 5)
                subrequirementRow(label: "Desired victims", current: statisticsService.feedingsOverDesiredVictims, required: 1)
                
            case .domination:
                subrequirementRow(label: "Bribe victims", current: statisticsService.bribes, required: 5)
                subrequirementRow(label: "Seduce victims", current: statisticsService.peopleSeducted, required: 5)
                subrequirementRow(label: "Feed over desired victims", current: statisticsService.feedingsOverDesiredVictims, required: 3)
                subrequirementRow(label: "Drain victims", current: statisticsService.victimsDrained, required: 1)
                
            case .whisper:
                subrequirementRow(label: "Days survived", current: statisticsService.daysSurvived, required: 10)
                subrequirementRow(label: "Seduce victims", current: statisticsService.peopleSeducted, required: 15)
                subrequirementRow(label: "Feed over desired victims", current: statisticsService.feedingsOverDesiredVictims, required: 10)
                
            case .command:
                subrequirementRow(label: "Use seduction", current: statisticsService.peopleSeducted, required: 5)
                subrequirementRow(label: "Feed over desired victims", current: statisticsService.feedingsOverDesiredVictims, required: 5)
                
            case .enthralling:
                subrequirementRow(label: "Use domination", current: statisticsService.peopleDominated, required: 10)
                subrequirementRow(label: "Feed over desired victims", current: statisticsService.feedingsOverDesiredVictims, required: 10)
                subrequirementRow(label: "Drain victims", current: statisticsService.victimsDrained, required: 5)
                subrequirementRow(label: "Own property", current: statisticsService.propertiesBought, required: 1)
                
            case .smithingNovice:
                subrequirementRow(label: "Smithing recipes", current: statisticsService.smithingRecipesUnlocked, required: 10)
                
            case .smithingApprentice:
                subrequirementRow(label: "Smithing recipes", current: statisticsService.smithingRecipesUnlocked, required: 20)
                
            case .smithingExpert:
                subrequirementRow(label: "Smithing recipes", current: statisticsService.smithingRecipesUnlocked, required: 40)
                
            case .smithingMaster:
                subrequirementRow(label: "Smithing recipes", current: statisticsService.smithingRecipesUnlocked, required: 60)
                
            case .alchemyNovice:
                subrequirementRow(label: "Alchemy recipes", current: statisticsService.alchemyRecipesUnlocked, required: 10)
                
            case .alchemyApprentice:
                subrequirementRow(label: "Alchemy recipes", current: statisticsService.alchemyRecipesUnlocked, required: 20)
                
            case .alchemyExpert:
                subrequirementRow(label: "Alchemy recipes", current: statisticsService.alchemyRecipesUnlocked, required: 40)
                
            case .alchemyMaster:
                subrequirementRow(label: "Alchemy recipes", current: statisticsService.alchemyRecipesUnlocked, required: 60)
                
            case .bribe:
                subrequirementRow(label: "500+ coins deals", current: statisticsService._500CoinsDeals, required: 10)
                
            case .trader:
                subrequirementRow(label: "1000+ coins deals", current: statisticsService._1000CoinsDeals, required: 20)
                
            case .invisibility:
                subrequirementRow(label: "Days survived", current: statisticsService.daysSurvived, required: 5)
                subrequirementRow(label: "People seduced", current: statisticsService.peopleSeducted, required: 10)
                subrequirementRow(label: "Feed over desired victims", current: statisticsService.feedingsOverDesiredVictims, required: 5)
                
            case .dayWalker:
                subrequirementRow(label: "Days survived", current: statisticsService.daysSurvived, required: 10)
                subrequirementRow(label: "Feed over desired victims", current: statisticsService.feedingsOverDesiredVictims, required: 10)
                subrequirementRow(label: "Drain victims", current: statisticsService.victimsDrained, required: 3)
                
            case .lordOfBlood:
                subrequirementRow(label: "Days survived", current: statisticsService.daysSurvived, required: 30)
                subrequirementRow(label: "Feed over desired victims", current: statisticsService.feedingsOverDesiredVictims, required: 30)
                subrequirementRow(label: "Dominate victims", current: statisticsService.peopleDominated, required: 30)
                
            case .masquerade:
                subrequirementRow(label: "Days survived", current: statisticsService.daysSurvived, required: 30)
                subrequirementRow(label: "Food consumed", current: statisticsService.foodConsumed, required: 100)
                subrequirementRow(label: "Seduce victims", current: statisticsService.peopleSeducted, required: 20)
                
            case .unholyTongue:
                subrequirementRow(label: "Bribe victims", current: statisticsService.bribes, required: 20)
                
            case .mysteriousPerson:
                subrequirementRow(label: "Successful bribes", current: statisticsService.bribes, required: 10)
                subrequirementRow(label: "Barters completed", current: statisticsService.bartersCompleted, required: 20)
                
            case .darkness:
                subrequirementRow(label: "Desired victims", current: statisticsService.feedingsOverDesiredVictims, required: 15)
                subrequirementRow(label: "Days survived", current: statisticsService.daysSurvived, required: 21)
                subrequirementRow(label: "Sleeping victims", current: statisticsService.feedingsOverSleepingVictims, required: 30)
                
            case .memoryErasure:
                subrequirementRow(label: "Days survived", current: statisticsService.daysSurvived, required: 40)
                subrequirementRow(label: "Dominate victims", current: statisticsService.peopleDominated, required: 20)
                
            case .oldFriend:
                subrequirementRow(label: "Friendships created", current: statisticsService.friendshipsCreated, required: 10)
                
            case .undeadCasanova:
                subrequirementRow(label: "Friendships created", current: statisticsService.friendshipsCreated, required: 15)
                subrequirementRow(label: "Nights spent with someone", current: statisticsService.nightSpentsWithSomeone, required: 20)
                subrequirementRow(label: "Feed on desired victims", current: statisticsService.feedingsOverDesiredVictims, required: 20)
                
            case .sonOfDracula:
                subrequirementRow(label: "Days survived", current: statisticsService.daysSurvived, required: 100)
                subrequirementRow(label: "Drain victims", current: statisticsService.victimsDrained, required: 50)
                
            case .ghost:
                subrequirementRow(label: "Disappearances", current: statisticsService.disappearances, required: 30)
                
            case .insight:
                subrequirementRow(label: "Investigations", current: statisticsService.investigations, required: 100)
                
            case .lionAmongSheep:
                subrequirementRow(label: "Allies created", current: statisticsService.friendshipsCreated, required: 10)
                subrequirementRow(label: "Desired victims", current: statisticsService.feedingsOverDesiredVictims, required: 40)
                
            case .dreamstealer:
                subrequirementRow(label: "Use seduction", current: statisticsService.peopleSeducted, required: 20)
                
            case .kingSalamon:
                subrequirementRow(label: "Dominate victims", current: statisticsService.peopleDominated, required: 10)
                
            case .noble:
                subrequirementRow(label: "Lord friendships", current: statisticsService.friendshipsCreated, required: 10)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func subrequirementRow(label: String, current: Int, required: Int) -> some View {
        let isCompleted = current >= required
        let displayCurrent = isCompleted ? required : min(current, required) // Cap the displayed value
        
        return HStack(spacing: 8) {
            // Completion checkmark on the left with smaller font and reduced opacity
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(Theme.smallFont)
                    .foregroundColor(Color.green.opacity(0.7))
                    .shadow(color: Color.green.opacity(0.3), radius: 3, x: 0, y: 2)
            } else {
                // Empty space to maintain alignment when no checkmark
                Color.clear.frame(width: 16, height: 16)
            }
            
            // Label and progress text with lighter strikethrough for completed items
            Text("\(label): \(displayCurrent)/\(required)")
                .font(Theme.smallFont)
                .foregroundColor(isCompleted ? Color.green.opacity(0.9) : Color.white.opacity(0.7))
                .strikethrough(isCompleted, color: Color.green.opacity(0.5))
            
            Spacer()
        }
    }
    
    private func progressFillBar(progress: Double) -> some View {
        GeometryReader { geometry in
            // Main progress bar with gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.bloodProgressColor.opacity(0.7),
                            Theme.bloodProgressColor,
                            Theme.bloodProgressColor.opacity(0.9)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geometry.size.width * CGFloat(progress))
                .cornerRadius(4)
                .shadow(color: Theme.bloodProgressColor.opacity(0.7), radius: 4, x: 0, y: 0)
        }
        .frame(height: 8)
    }
    
    private func abilityProgressBar(ability: Ability, progress: Double) -> some View {
        progressFillBar(progress: progress)
    }
    
    private func abilityBackground(ability: Ability, isUnlocked: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(isUnlocked ? 0.5 : 0.3))
    }
    
    // Statistics view 
    private func statisticsView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed title without background
            Text("Vampire Statistics")
                .font(Theme.headingLightFont)
                .foregroundColor(Color.red)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider to separate title from content
            Divider()
                .background(Color.red.opacity(0.4))
            
            // Scrollable content with hidden scrollbar
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    createStatGroups()
                        .padding()
                }
            }
        }
        .cornerRadius(12)
    }
    
    private func createStatGroups() -> some View {
        VStack(spacing: 16) {
            // Survival stats
            statGroup(title: "Survival", stats: survivalStats())
            
            // Feeding stats
            statGroup(title: "Feeding", stats: feedingStats())
            
            // Social stats
            statGroup(title: "Social", stats: socialStats())
            
            // Commerce stats
            statGroup(title: "Commerce", stats: commerceStats())
            
            // Crafting stats
            statGroup(title: "Crafting", stats: craftingStats())
        }
    }
    
    private func survivalStats() -> [(String, String)] {
        return [
            ("Days Survived", "\(statisticsService.daysSurvived)")
        ]
    }
    
    private func feedingStats() -> [(String, String)] {
        return [
            ("Total Feedings", "\(statisticsService.feedings)"),
            ("Sleeping Victims", "\(statisticsService.feedingsOverSleepingVictims)"),
            ("Desired Victims", "\(statisticsService.feedingsOverDesiredVictims)"),
            ("Victims Drained", "\(statisticsService.victimsDrained)"),
            ("People Killed", "\(statisticsService.peopleKilled)"),
            ("Food Consumed", "\(statisticsService.foodConsumed)")
        ]
    }
    
    private func socialStats() -> [(String, String)] {
        return [
            ("Seductions", "\(statisticsService.peopleSeducted)"),
            ("Dominations", "\(statisticsService.peopleDominated)"),
            ("Bribes Paid", "\(statisticsService.bribes)"),
            ("Investigations", "\(statisticsService.investigations)"),
            ("Friendships Created", "\(statisticsService.friendshipsCreated)"),
            ("Nights With Someone", "\(statisticsService.nightSpentsWithSomeone)"),
            ("Disappearances", "\(statisticsService.disappearances)")
        ]
    }
    
    private func commerceStats() -> [(String, String)] {
        return [
            ("Barters Completed", "\(statisticsService.bartersCompleted)"),
            ("500+ Coins Deals", "\(statisticsService._500CoinsDeals)"),
            ("1000+ Coins Deals", "\(statisticsService._1000CoinsDeals)"),
            ("Properties Owned", "\(statisticsService.propertiesBought)"),
            ("Times Arrested", "\(statisticsService.timesArrested)")
        ]
    }
    
    private func craftingStats() -> [(String, String)] {
        return [
            ("Smithing Recipes", "\(statisticsService.smithingRecipesUnlocked)"),
            ("Alchemy Recipes", "\(statisticsService.alchemyRecipesUnlocked)")
        ]
    }
    
    // Break down statGroup into smaller components
    private func statGroup(title: String, stats: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.bodyFont)
                .foregroundColor(Color.white.opacity(0.9))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.black.opacity(0.45))
                .cornerRadius(8)
            
            statItemsContainer(stats: stats)
        }
    }
    
    private func statItemsContainer(stats: [(String, String)]) -> some View {
        VStack(spacing: 6) {
            ForEach(Array(stats.enumerated()), id: \.element.0) { index, stat in
                statItemRow(stat: stat, isLast: index == stats.count - 1)
            }
        }
        .padding()
        .background(statBackground())
    }
    
    private func statItemRow(stat: (String, String), isLast: Bool) -> some View {
        VStack {
            HStack {
                Text(stat.0)
                    .font(Theme.bodyFont)
                    .foregroundColor(Color.white.opacity(0.7))
                
                Spacer()
                
                Text(stat.1)
                    .font(Theme.bodyFont.bold())
                    .foregroundColor(Color.white)
            }
            .padding(.vertical, 4)
            
            if !isLast {
                Divider()
                    .background(Color.gray.opacity(0.3))
            }
        }
    }
    
    private func statBackground() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.55))
            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // Helper function to calculate progress for each ability
    private func calculateProgress(for ability: Ability) -> Double {
        if abilitiesSystem.playerAbilities.contains(ability) {
            return 1.0
        }
        
        switch ability {
        case .seduction:
            return calculateSeductionProgress()
        case .domination:
            return calculateDominationProgress()
        case .whisper:
            return calculateWhisperProgress()
        case .command:
            return calculateCommandProgress()
        case .enthralling:
            return calculateEnthrallingProgress()
        case .smithingNovice:
            return calculateSmithingNoviceProgress()
        case .smithingApprentice:
            return calculateSmithingApprenticeProgress()
        case .smithingExpert:
            return calculateSmithingExpertProgress()
        case .smithingMaster:
            return calculateSmithingMasterProgress()
        case .alchemyNovice:
            return calculateAlchemyNoviceProgress()
        case .alchemyApprentice:
            return calculateAlchemyApprenticeProgress()
        case .alchemyExpert:
            return calculateAlchemyExpertProgress()
        case .alchemyMaster:
            return calculateAlchemyMasterProgress()
        case .bribe:
            return calculateBribeProgress()
        case .trader:
            return calculateTraderProgress()
        case .invisibility:
            return calculateInvisibilityProgress()
        case .dayWalker:
            return calculateDayWalkerProgress()
        case .lordOfBlood:
            return calculateLordOfBloodProgress()
        case .masquerade:
            return calculateMasqueradeProgress()
        case .unholyTongue:
            return calculateUnholyTongueProgress()
        case .mysteriousPerson:
            return calculateMysteriousPersonProgress()
        case .darkness:
            return calculateDarknessProgress()
        case .memoryErasure:
            return calculateMemoryErasureProgress()
        case .oldFriend:
            return calculateOldFriendProgress()
        case .undeadCasanova:
            return calculateUndeadCasanovaProgress()
        case .sonOfDracula:
            return calculateSonOfDraculaProgress()
        case .ghost:
            return calculateGhostProgress()
        case .insight:
            return calculateInsightProgress()
        case .lionAmongSheep:
            return calculateLionAmongSheepProgress()
        case .dreamstealer:
            return calculateDreamstealerProgress()
        case .kingSalamon:
            return calculateKingSalamonProgress()
        case .noble:
            return calculateNobleProgress()
        }
    }
    
    // Helper methods for calculating individual ability progress
    private func calculateSeductionProgress() -> Double {
        let sleepProgress = min(1.0, Double(statisticsService.feedingsOverSleepingVictims) / 5.0)
        let desiredProgress = min(1.0, Double(statisticsService.feedingsOverDesiredVictims) / 1.0)
        return (sleepProgress + desiredProgress) / 2.0
    }
    
    private func calculateDominationProgress() -> Double {
        let bribesProgress = min(1.0, Double(statisticsService.bribes) / 5.0)
        let seduceProgress = min(1.0, Double(statisticsService.peopleSeducted) / 5.0)
        let feedProgress = min(1.0, Double(statisticsService.feedingsOverDesiredVictims) / 3.0)
        let drainProgress = min(1.0, Double(statisticsService.victimsDrained) / 1.0)
        return (bribesProgress + seduceProgress + feedProgress + drainProgress) / 4.0
    }
    
    private func calculateWhisperProgress() -> Double {
        let seduceProgress = min(1.0, Double(statisticsService.peopleSeducted) / 10.0)
        let sleepProgress = min(1.0, Double(statisticsService.feedingsOverSleepingVictims) / 5.0)
        let feedProgress = min(1.0, Double(statisticsService.feedingsOverDesiredVictims) / 3.0)
        return (seduceProgress + sleepProgress + feedProgress) / 3.0
    }
    
    private func calculateCommandProgress() -> Double {
        let seduceProgress = min(1.0, Double(statisticsService.peopleSeducted) / 5.0)
        let feedProgress = min(1.0, Double(statisticsService.feedingsOverDesiredVictims) / 5.0)
        return (seduceProgress + feedProgress) / 2.0
    }
    
    private func calculateEnthrallingProgress() -> Double {
        let dominateProgress = min(1.0, Double(statisticsService.peopleDominated) / 10.0)
        let propertyProgress = min(1.0, Double(statisticsService.propertiesBought) / 1.0)
        let feedProgress = min(1.0, Double(statisticsService.feedingsOverDesiredVictims) / 10.0)
        let drainProgress = min(1.0, Double(statisticsService.victimsDrained) / 5.0)
        return (dominateProgress + propertyProgress + feedProgress + drainProgress) / 4.0
    }
    
    private func calculateSmithingNoviceProgress() -> Double {
        return min(1.0, Double(statisticsService.smithingRecipesUnlocked) / 10.0)
    }
    
    private func calculateSmithingApprenticeProgress() -> Double {
        return min(1.0, Double(statisticsService.smithingRecipesUnlocked) / 20.0)
    }
    
    private func calculateSmithingExpertProgress() -> Double {
        return min(1.0, Double(statisticsService.smithingRecipesUnlocked) / 40.0)
    }
    
    private func calculateSmithingMasterProgress() -> Double {
        return min(1.0, Double(statisticsService.smithingRecipesUnlocked) / 60.0)
    }
    
    private func calculateAlchemyNoviceProgress() -> Double {
        return min(1.0, Double(statisticsService.alchemyRecipesUnlocked) / 10.0)
    }
    
    private func calculateAlchemyApprenticeProgress() -> Double {
        return min(1.0, Double(statisticsService.alchemyRecipesUnlocked) / 20.0)
    }
    
    private func calculateAlchemyExpertProgress() -> Double {
        return min(1.0, Double(statisticsService.alchemyRecipesUnlocked) / 40.0)
    }
    
    private func calculateAlchemyMasterProgress() -> Double {
        return min(1.0, Double(statisticsService.alchemyRecipesUnlocked) / 60.0)
    }
    
    private func calculateBribeProgress() -> Double {
        return min(1.0, Double(statisticsService._500CoinsDeals) / 10.0)
    }
    
    private func calculateTraderProgress() -> Double {
        return min(1.0, Double(statisticsService._1000CoinsDeals) / 20.0)
    }
    
    private func calculateInvisibilityProgress() -> Double {
        let daysProgress = min(1.0, Double(statisticsService.daysSurvived) / 5.0)
        let feedProgress = min(1.0, Double(statisticsService.feedingsOverDesiredVictims) / 5.0)
        return (daysProgress + feedProgress) / 2.0
    }
    
    private func calculateDayWalkerProgress() -> Double {
        let daysProgress = min(1.0, Double(statisticsService.daysSurvived) / 10.0)
        let feedProgress = min(1.0, Double(statisticsService.feedingsOverDesiredVictims) / 10.0)
        let drainProgress = min(1.0, Double(statisticsService.victimsDrained) / 3.0)
        return (daysProgress + feedProgress + drainProgress) / 3.0
    }
    
    private func calculateLordOfBloodProgress() -> Double {
        let daysProgress = min(1.0, Double(statisticsService.daysSurvived) / 30.0)
        let feedProgress = min(1.0, Double(statisticsService.feedingsOverDesiredVictims) / 30.0)
        let dominateProgress = min(1.0, Double(statisticsService.peopleDominated) / 30.0)
        return (daysProgress + feedProgress + dominateProgress) / 3.0
    }
    
    private func calculateMasqueradeProgress() -> Double {
        let daysProgress = min(1.0, Double(statisticsService.daysSurvived) / 30.0)
        let foodProgress = min(1.0, Double(statisticsService.foodConsumed) / 100.0)
        let seduceProgress = min(1.0, Double(statisticsService.peopleSeducted) / 20.0)
        return (daysProgress + foodProgress + seduceProgress) / 3.0
    }
    
    private func calculateUnholyTongueProgress() -> Double {
        return min(1.0, Double(statisticsService.bribes) / 20.0)
    }
    
    private func calculateMysteriousPersonProgress() -> Double {
        let bribeProgress = min(1.0, Double(statisticsService.bribes) / 10.0)
        let barterProgress = min(1.0, Double(statisticsService.bartersCompleted) / 20.0)
        return (bribeProgress + barterProgress) / 2.0
    }
    
    private func calculateDarknessProgress() -> Double {
        let desiredProgress = min(1.0, Double(statisticsService.feedingsOverDesiredVictims) / 15.0)
        let daysProgress = min(1.0, Double(statisticsService.daysSurvived) / 21.0)
        let sleepingProgress = min(1.0, Double(statisticsService.feedingsOverSleepingVictims) / 30.0)
        return (desiredProgress + daysProgress + sleepingProgress) / 3.0
    }
    
    private func calculateMemoryErasureProgress() -> Double {
        let daysProgress = min(1.0, Double(statisticsService.daysSurvived) / 40.0)
        let dominationProgress = min(1.0, Double(statisticsService.peopleDominated) / 20.0)
        return (daysProgress + dominationProgress) / 2.0
    }
    
    private func calculateOldFriendProgress() -> Double {
        return min(1.0, Double(statisticsService.friendshipsCreated) / 10.0)
    }
    
    private func calculateUndeadCasanovaProgress() -> Double {
        let friendshipProgress = min(1.0, Double(statisticsService.friendshipsCreated) / 15.0)
        let nightsProgress = min(1.0, Double(statisticsService.nightSpentsWithSomeone) / 20.0)
        let feedingProgress = min(1.0, Double(statisticsService.feedingsOverDesiredVictims) / 20.0)
        return (friendshipProgress + nightsProgress + feedingProgress) / 3.0
    }
    
    private func calculateSonOfDraculaProgress() -> Double {
        let daysProgress = min(1.0, Double(statisticsService.daysSurvived) / 100.0)
        let drainProgress = min(1.0, Double(statisticsService.victimsDrained) / 50.0)
        return (daysProgress + drainProgress) / 2.0
    }
    
    private func calculateGhostProgress() -> Double {
        return min(1.0, Double(statisticsService.disappearances) / 30.0)
    }
    
    private func calculateInsightProgress() -> Double {
        return min(1.0, Double(statisticsService.investigations) / 100.0)
    }
    
    private func calculateLionAmongSheepProgress() -> Double {
        let friendshipProgress = min(1.0, Double(statisticsService.friendshipsCreated) / 10.0)
        let feedingProgress = min(1.0, Double(statisticsService.feedingsOverDesiredVictims) / 40.0)
        return (friendshipProgress + feedingProgress) / 2.0
    }
    
    private func calculateDreamstealerProgress() -> Double {
        return min(1.0, Double(statisticsService.peopleSeducted) / 20.0)
    }
    
    private func calculateKingSalamonProgress() -> Double {
        return min(1.0, Double(statisticsService.peopleDominated) / 10.0)
    }
    
    private func calculateNobleProgress() -> Double {
        return min(1.0, Double(statisticsService.friendshipsCreated) / 10.0)
    }
}

// Add this new implementation to the AbilitiesView - it uses a regular animation timer
// instead of TimelineView with onChange
struct CustomBloodMistEffect: View {
    @State private var phase: CGFloat = 0
    @State private var animationTimer: AnyCancellable?
    
    var body: some View {
        Canvas { context, size in
            context.addFilter(.blur(radius: 30))
            
            for i in 0..<15 {
                var path = Path()
                let offset = CGFloat(i) * 0.2 + phase
                
                for x in stride(from: 0, through: size.width, by: 20) {
                    let y = sin(x/60 + offset) * 40 + size.height/2
                    if x == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addQuadCurve(
                            to: CGPoint(x: x, y: y),
                            control: CGPoint(x: x - 10, y: y + 10 * sin(x/30 + offset))
                        )
                    }
                }
                
                context.stroke(
                    path,
                    with: .color(.red.opacity(0.15)),
                    lineWidth: 30
                )
            }
        }
        .onAppear {
            // Use a timer instead of TimelineView
            animationTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
                .sink { _ in
                    phase += 0.02
                }
        }
        .onDisappear {
            // Cancel the timer when view disappears
            animationTimer?.cancel()
            animationTimer = nil
        }
    }
}
