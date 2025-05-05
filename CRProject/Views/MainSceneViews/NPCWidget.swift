//
//  NPCWidget.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 24.04.2025.
//

import SwiftUICore
import SwiftUI
import CoreMotion
import UIKit
import Combine

// MARK: - SwiftUI Bridge
struct NPCWidget: View {
    let npc: NPC
    let isSelected: Bool
    let isDisabled: Bool
    var showCurrentActivity: Bool = true
    var showResistance: Bool = false
    let onTap: () -> Void
    let onAction: (NPCAction) -> Void

    var body: some View {
        NPCWidgetUIViewControllerRepresentable(
            npc: npc,
            isSelected: isSelected,
            isDisabled: isDisabled,
            showCurrentActivity: showCurrentActivity,
            showResistance: showResistance,
            onTap: onTap,
            onAction: onAction
        )
        .frame(width: 180, height: 320) // Фиксированный размер виджета
    }
}

struct NPCWidgetUIViewControllerRepresentable: UIViewControllerRepresentable {
    let npc: NPC
    let isSelected: Bool
    let isDisabled: Bool
    let showCurrentActivity: Bool
    let showResistance: Bool
    let onTap: () -> Void
    let onAction: (NPCAction) -> Void
    
    func makeUIViewController(context: Context) -> NPCWidgetUIViewController {
        return NPCWidgetUIViewController(
            npc: npc,
            isSelected: isSelected,
            isDisabled: isDisabled,
            showCurrentActivity: showCurrentActivity,
            showResistance: showResistance,
            onTap: onTap,
            onAction: onAction
        )
    }
    
    func updateUIViewController(_ uiViewController: NPCWidgetUIViewController, context: Context) {
        uiViewController.updateNPC(
            npc: npc,
            isSelected: isSelected,
            isDisabled: isDisabled,
            showCurrentActivity: showCurrentActivity,
            showResistance: showResistance
        )
    }
}

// MARK: - UIKit Implementation
class NPCWidgetUIViewController: UIViewController {
    // MARK: - Properties
    private var npc: NPC
    private var isSelected: Bool
    private var isDisabled: Bool
    private var showCurrentActivity: Bool
    private var showResistance: Bool
    private var onTap: () -> Void
    private var onAction: (NPCAction) -> Void
    private var lastTapTime: Date = Date()
    private var cancellables = Set<AnyCancellable>()
    
    // UI Components
    private let containerView = UIView()
    private let backgroundView = UIView()
    private let npcImageView = UIImageView()
    private let npcNameLabel = UILabel()
    private let npcAgeLabel = UILabel()
    private let npcGenderImageView = UIImageView()
    private let healthLabel = UILabel()
    private let healthValueLabel = UILabel()
    private let healthProgressView = UIProgressView(progressViewStyle: .default)
    private let relationshipLabel = UILabel()
    private let relationshipValueLabel = UILabel()
    private let relationshipProgressView = UIProgressView(progressViewStyle: .default)
    private let resistanceLabel = UILabel()
    private let resistanceValueLabel = UILabel()
    private let resistanceProgressView = UIProgressView(progressViewStyle: .default)
    private let professionIconImageView = UIImageView()
    private let professionLabel = UILabel()
    private let activityIconImageView = UIImageView()
    private let activityLabel = UILabel()
    private let unknownIcon = UILabel()
    private let desiredVictimView = UIView()
    
    // MARK: - Initializers
    init(npc: NPC, isSelected: Bool, isDisabled: Bool, showCurrentActivity: Bool, showResistance: Bool, onTap: @escaping () -> Void, onAction: @escaping (NPCAction) -> Void) {
        self.npc = npc
        self.isSelected = isSelected
        self.isDisabled = isDisabled
        self.showCurrentActivity = showCurrentActivity
        self.showResistance = showResistance
        self.onTap = onTap
        self.onAction = onAction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTapGesture()
        setupNPCObservation()
        updateUI()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Setup container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        
        // Setup background view with gradient
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.layer.cornerRadius = 12
        backgroundView.clipsToBounds = true
        // No border on background view
        
        // Create gradient for background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.8).cgColor,
            convertSwiftUIColorToUIColor(npc.profession.color).withAlphaComponent(0.05).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.cornerRadius = 12
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        containerView.addSubview(backgroundView)
        
        // Add black semi-transparent background for the card
        let infoBackgroundView = UIView()
        infoBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        infoBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        infoBackgroundView.layer.cornerRadius = 12
        containerView.addSubview(infoBackgroundView)
        
        // Setup NPC image view
        npcImageView.translatesAutoresizingMaskIntoConstraints = false
        npcImageView.contentMode = .scaleAspectFill
        npcImageView.clipsToBounds = true
        npcImageView.layer.cornerRadius = 8
        npcImageView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        npcImageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        npcImageView.layer.shadowRadius = 4
        npcImageView.layer.shadowOpacity = 1.0
        containerView.addSubview(npcImageView)
        
        // Setup desired victim icon view (if needed)
        desiredVictimView.translatesAutoresizingMaskIntoConstraints = false
        desiredVictimView.isHidden = true
        containerView.addSubview(desiredVictimView)
        
        // Setup unknown icon
        unknownIcon.translatesAutoresizingMaskIntoConstraints = false
        unknownIcon.text = "?"
        unknownIcon.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        unknownIcon.textColor = UIColor(Theme.textColor)
        unknownIcon.textAlignment = .center
        unknownIcon.isHidden = true
        containerView.addSubview(unknownIcon)
        
        // Setup NPC information labels
        npcGenderImageView.translatesAutoresizingMaskIntoConstraints = false
        npcGenderImageView.contentMode = .scaleAspectFit
        npcGenderImageView.tintColor = npc.isVampire ? 
            UIColor(Theme.primaryColor) : UIColor(Theme.textColor)
        containerView.addSubview(npcGenderImageView)
        
        npcNameLabel.translatesAutoresizingMaskIntoConstraints = false
        npcNameLabel.textColor = UIColor(Theme.textColor)
        npcNameLabel.font = UIFont(name: "Optima", size: 12)
        npcNameLabel.adjustsFontSizeToFitWidth = false
        containerView.addSubview(npcNameLabel)
        
        npcAgeLabel.translatesAutoresizingMaskIntoConstraints = false
        npcAgeLabel.textColor = UIColor(Theme.textColor)
        npcAgeLabel.font = UIFont(name: "Optima", size: 12)
        npcAgeLabel.adjustsFontSizeToFitWidth = false
        npcAgeLabel.textAlignment = .right
        containerView.addSubview(npcAgeLabel)
        
        // Setup health section
        healthLabel.translatesAutoresizingMaskIntoConstraints = false
        healthLabel.textColor = UIColor(Theme.textColor)
        healthLabel.font = UIFont(name: "Optima", size: 12)
        healthLabel.adjustsFontSizeToFitWidth = false
        healthLabel.text = "Health"
        containerView.addSubview(healthLabel)
        
        healthValueLabel.translatesAutoresizingMaskIntoConstraints = false
        healthValueLabel.textColor = UIColor(Theme.bloodProgressColor)
        healthValueLabel.font = UIFont(name: "Optima", size: 12)
        healthValueLabel.adjustsFontSizeToFitWidth = false
        healthValueLabel.textAlignment = .right
        containerView.addSubview(healthValueLabel)
        
        healthProgressView.translatesAutoresizingMaskIntoConstraints = false
        healthProgressView.progressTintColor = UIColor(Theme.bloodProgressColor)
        healthProgressView.trackTintColor = UIColor.black.withAlphaComponent(0.5)
        healthProgressView.layer.cornerRadius = 4
        healthProgressView.clipsToBounds = true
        healthProgressView.layer.borderWidth = 1
        healthProgressView.layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor
        containerView.addSubview(healthProgressView)
        
        // Setup relationship/resistance section
        relationshipLabel.translatesAutoresizingMaskIntoConstraints = false
        relationshipLabel.textColor = UIColor(Theme.textColor)
        relationshipLabel.font = UIFont(name: "Optima", size: 12)
        relationshipLabel.adjustsFontSizeToFitWidth = false
        relationshipLabel.text = "Relationship"
        containerView.addSubview(relationshipLabel)
        
        relationshipValueLabel.translatesAutoresizingMaskIntoConstraints = false
        relationshipValueLabel.font = UIFont(name: "Optima", size: 12)
        relationshipValueLabel.adjustsFontSizeToFitWidth = false
        relationshipValueLabel.textAlignment = .right
        containerView.addSubview(relationshipValueLabel)
        
        relationshipProgressView.translatesAutoresizingMaskIntoConstraints = false
        relationshipProgressView.trackTintColor = UIColor.black.withAlphaComponent(0.5)
        relationshipProgressView.progressTintColor = UIColor.green
        relationshipProgressView.layer.cornerRadius = 4
        relationshipProgressView.clipsToBounds = true
        relationshipProgressView.layer.borderWidth = 1
        relationshipProgressView.layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor
        containerView.addSubview(relationshipProgressView)
        
        // Resistance components (initially hidden)
        resistanceLabel.translatesAutoresizingMaskIntoConstraints = false
        resistanceLabel.textColor = UIColor(Theme.textColor)
        resistanceLabel.font = UIFont(name: "Optima", size: 12)
        resistanceLabel.adjustsFontSizeToFitWidth = false
        resistanceLabel.text = "Resistance"
        resistanceLabel.isHidden = true
        containerView.addSubview(resistanceLabel)
        
        resistanceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        resistanceValueLabel.font = UIFont(name: "Optima", size: 12)
        resistanceValueLabel.adjustsFontSizeToFitWidth = false
        resistanceValueLabel.textAlignment = .right
        resistanceValueLabel.isHidden = true
        containerView.addSubview(resistanceValueLabel)
        
        resistanceProgressView.translatesAutoresizingMaskIntoConstraints = false
        resistanceProgressView.trackTintColor = UIColor.black.withAlphaComponent(0.5)
        resistanceProgressView.progressTintColor = UIColor(Theme.bloodProgressColor).withAlphaComponent(0.7)
        resistanceProgressView.layer.cornerRadius = 4
        resistanceProgressView.clipsToBounds = true
        resistanceProgressView.layer.borderWidth = 1
        resistanceProgressView.layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor
        resistanceProgressView.isHidden = true
        containerView.addSubview(resistanceProgressView)
        
        // Setup profession and activity section
        professionIconImageView.translatesAutoresizingMaskIntoConstraints = false
        professionIconImageView.contentMode = .scaleAspectFit
        professionIconImageView.tintColor = convertSwiftUIColorToUIColor(npc.profession.color)
        containerView.addSubview(professionIconImageView)
        
        professionLabel.translatesAutoresizingMaskIntoConstraints = false
        professionLabel.textColor = UIColor(Theme.textColor)
        professionLabel.font = UIFont(name: "Optima", size: 12)
        professionLabel.adjustsFontSizeToFitWidth = false
        professionLabel.lineBreakMode = .byTruncatingTail
        professionLabel.textAlignment = .left
        containerView.addSubview(professionLabel)
        
        activityIconImageView.translatesAutoresizingMaskIntoConstraints = false
        activityIconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(activityIconImageView)
        
        activityLabel.translatesAutoresizingMaskIntoConstraints = false
        activityLabel.textColor = UIColor(Theme.textColor)
        activityLabel.font = UIFont(name: "Optima", size: 12)
        activityLabel.adjustsFontSizeToFitWidth = false
        activityLabel.lineBreakMode = .byTruncatingTail
        activityLabel.textAlignment = .left
        containerView.addSubview(activityLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Container constraints
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Background view constraints
            backgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Info background constraints
            infoBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
            infoBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            infoBackgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            infoBackgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // NPC image constraints
            npcImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            npcImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            npcImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            npcImageView.heightAnchor.constraint(equalToConstant: 180),
            
            // Unknown icon constraints
            unknownIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            unknownIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // NPC info constraints
            npcGenderImageView.topAnchor.constraint(equalTo: npcImageView.bottomAnchor, constant: 8),
            npcGenderImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            npcGenderImageView.widthAnchor.constraint(equalToConstant: 20),
            npcGenderImageView.heightAnchor.constraint(equalToConstant: 20),
            
            npcNameLabel.centerYAnchor.constraint(equalTo: npcGenderImageView.centerYAnchor),
            npcNameLabel.leadingAnchor.constraint(equalTo: npcGenderImageView.trailingAnchor, constant: 4),
            
            npcAgeLabel.centerYAnchor.constraint(equalTo: npcGenderImageView.centerYAnchor),
            npcAgeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            npcAgeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: npcNameLabel.trailingAnchor, constant: 4),
            
            // Relationship section constraints (also used for resistance)
            relationshipLabel.topAnchor.constraint(equalTo: npcGenderImageView.bottomAnchor, constant: 8),
            relationshipLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            
            relationshipValueLabel.centerYAnchor.constraint(equalTo: relationshipLabel.centerYAnchor),
            relationshipValueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            relationshipProgressView.topAnchor.constraint(equalTo: relationshipLabel.bottomAnchor, constant: 4),
            relationshipProgressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            relationshipProgressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            relationshipProgressView.heightAnchor.constraint(equalToConstant: 6),
            
            // Resistance section constraints
            resistanceLabel.topAnchor.constraint(equalTo: npcGenderImageView.bottomAnchor, constant: 8),
            resistanceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            
            resistanceValueLabel.centerYAnchor.constraint(equalTo: resistanceLabel.centerYAnchor),
            resistanceValueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            resistanceProgressView.topAnchor.constraint(equalTo: resistanceLabel.bottomAnchor, constant: 4),
            resistanceProgressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            resistanceProgressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            resistanceProgressView.heightAnchor.constraint(equalToConstant: 6),
            
            // Health section constraints
            healthLabel.topAnchor.constraint(equalTo: relationshipProgressView.bottomAnchor, constant: 8),
            healthLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            
            healthValueLabel.centerYAnchor.constraint(equalTo: healthLabel.centerYAnchor),
            healthValueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            healthProgressView.topAnchor.constraint(equalTo: healthLabel.bottomAnchor, constant: 4),
            healthProgressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            healthProgressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            healthProgressView.heightAnchor.constraint(equalToConstant: 6),
            
            // Profession row - icon left, text right
            professionIconImageView.topAnchor.constraint(equalTo: healthProgressView.bottomAnchor, constant: 12),
            professionIconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            professionIconImageView.widthAnchor.constraint(equalToConstant: 20),
            professionIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            professionLabel.centerYAnchor.constraint(equalTo: professionIconImageView.centerYAnchor),
            professionLabel.leadingAnchor.constraint(equalTo: professionIconImageView.trailingAnchor, constant: 8),
            professionLabel.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor, multiplier: 0.45),
            
            // Activity in the same row, but right-aligned
            activityIconImageView.centerYAnchor.constraint(equalTo: professionIconImageView.centerYAnchor),
            activityIconImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            activityIconImageView.widthAnchor.constraint(equalToConstant: 20),
            activityIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            activityLabel.centerYAnchor.constraint(equalTo: activityIconImageView.centerYAnchor),
            activityLabel.trailingAnchor.constraint(equalTo: activityIconImageView.leadingAnchor, constant: -8),
            activityLabel.leadingAnchor.constraint(greaterThanOrEqualTo: professionLabel.trailingAnchor, constant: 8)
        ])
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap() {
            let now = Date()
            let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
            
            if timeSinceLastTap < 0.3 { // Double tap threshold
                // Double tap - investigate
            animateTap(scale: 0.95)
                VibrationService.shared.regularTap()
                onTap() // Call onTap first to center the view
                onAction(.investigate(npc))
            } else {
                // Single tap - select
            animateTap(scale: 0.98)
                VibrationService.shared.lightTap()
                onTap()
            }
            lastTapTime = now
    }
    
    private func animateTap(scale: CGFloat) {
        UIView.animate(withDuration: 0.1, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.containerView.transform = .identity
            }
        }
    }
    
    // MARK: - Update Methods
    func updateNPC(npc: NPC, isSelected: Bool, isDisabled: Bool, showCurrentActivity: Bool, showResistance: Bool) {
        // Cancel existing observations
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        self.npc = npc
        self.isSelected = isSelected
        self.isDisabled = isDisabled
        self.showCurrentActivity = showCurrentActivity 
        self.showResistance = showResistance
        
        // Setup new observations
        setupNPCObservation()
        
        // Simply call updateUI() to refresh all UI components
        updateUI()
    }
    
    private func setupNPCObservation() {
        // Observe bloodMeter changes
        npc.bloodMeter.$currentBlood
            .dropFirst() // Skip initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
            
        // Observe isUnknown status changes
        npc.$isUnknown
            .dropFirst() // Skip initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
            
        // Observe current activity changes
        npc.$currentActivity
            .dropFirst() // Skip initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
            
        // Observe relationship changes
        npc.playerRelationship.$value
            .dropFirst() // Skip initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
            
        // Observe isAlive changes (via bloodMeter)
        npc.bloodMeter.$currentBlood
            .dropFirst() // Skip initial value
            .filter { $0 <= 0 } // Only react when blood reaches 0 (death)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
    }
    
    private func updateUI() {
        // Animate UI changes for smooth transitions
        UIView.animate(withDuration: 0.3) {
            // Update visibility based on unknown state
            self.unknownIcon.alpha = self.npc.isUnknown ? 1.0 : 0.0
            
            // Handle unknown NPC case - hide details
            if self.npc.isUnknown {
                self.hideAllDetailsForUnknown()
            } else {
                self.showDetailsForKnownNPC()
                
                // Update NPC information
                self.npcGenderImageView.image = UIImage(systemName: self.npc.sex == .female ? "figure.stand.dress" : "figure.wave")
                self.npcGenderImageView.tintColor = self.npc.isVampire ? UIColor(Theme.primaryColor) : UIColor(Theme.textColor)
                self.npcNameLabel.text = self.npc.name
                self.npcAgeLabel.text = "Age \(self.npc.age)"
                
                // Show either resistance or relationship info
                if self.showResistance {
                    self.updateResistanceInfo()
                                } else {
                    self.updateRelationshipInfo()
                }
                
                // Update health information with smooth progress bar transition
                self.healthValueLabel.text = String(format: "%.1f%%", self.npc.bloodMeter.currentBlood)
                self.healthProgressView.setProgress(Float(self.npc.bloodMeter.currentBlood / 100.0), animated: true)
                
                // Update profession and activity information
                self.updateProfessionAndActivity()
            }
            
            // Update opacity based on alive and disabled state
            self.view.alpha = self.npc.isAlive ? (self.isDisabled ? 0.5 : 1.0) : 0.7
            
            // Highlight if selected
            self.updateSelectedState()
        }
        
        // Update user interaction state (not animated)
        view.isUserInteractionEnabled = !isDisabled
        
        // Set NPC image with crossfade
        UIView.transition(with: npcImageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            if self.npc.isUnknown {
                self.npcImageView.image = UIImage(named: self.npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")
            } else {
                self.npcImageView.image = UIImage(named: "npc\(self.npc.id.description)") ?? UIImage(named: self.npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")
            }
        }, completion: nil)
        
        // Update desired victim indicator
        updateDesiredVictimIndicator()
        
        // Update gradient in background with animation
        if let gradientLayer = backgroundView.layer.sublayers?.first as? CAGradientLayer {
            let colorAnimation = CABasicAnimation(keyPath: "colors")
            colorAnimation.fromValue = gradientLayer.colors
            colorAnimation.toValue = [
                UIColor.black.withAlphaComponent(0.8).cgColor,
                convertSwiftUIColorToUIColor(self.npc.profession.color).withAlphaComponent(0.05).cgColor
            ]
            colorAnimation.duration = 0.3
            colorAnimation.fillMode = .forwards
            colorAnimation.isRemovedOnCompletion = false
            gradientLayer.add(colorAnimation, forKey: "colorsAnimation")
            
            gradientLayer.colors = [
                UIColor.black.withAlphaComponent(0.8).cgColor,
                convertSwiftUIColorToUIColor(self.npc.profession.color).withAlphaComponent(0.05).cgColor
            ]
            gradientLayer.frame = backgroundView.bounds
        }
        
        // Force layout update
        view.setNeedsLayout()
    }
    
    private func hideAllDetailsForUnknown() {
        UIView.animate(withDuration: 0.3) {
            self.npcGenderImageView.alpha = 0
            self.npcNameLabel.alpha = 0
            self.npcAgeLabel.alpha = 0
            self.relationshipLabel.alpha = 0
            self.relationshipValueLabel.alpha = 0
            self.relationshipProgressView.alpha = 0
            self.resistanceLabel.alpha = 0
            self.resistanceValueLabel.alpha = 0
            self.resistanceProgressView.alpha = 0
            self.healthLabel.alpha = 0
            self.healthValueLabel.alpha = 0
            self.healthProgressView.alpha = 0
            self.professionIconImageView.alpha = 0
            self.professionLabel.alpha = 0
            self.activityIconImageView.alpha = 0
            self.activityLabel.alpha = 0
        }
    }
    
    private func showDetailsForKnownNPC() {
        UIView.animate(withDuration: 0.3) {
            // Basic info always visible for known NPCs
            self.npcGenderImageView.alpha = 1
            self.npcNameLabel.alpha = 1
            self.npcAgeLabel.alpha = 1
            self.healthLabel.alpha = 1
            self.healthValueLabel.alpha = 1
            self.healthProgressView.alpha = 1
            
            // Show profession only if NPC is alive
            let showProfession = self.npc.isAlive
            self.professionIconImageView.alpha = showProfession ? 1 : 0
            self.professionLabel.alpha = showProfession ? 1 : 0
            
            // Show activity based on setting and aliveness
            let shouldShowActivity = self.showCurrentActivity && self.npc.isAlive
            self.activityIconImageView.alpha = shouldShowActivity ? 1 : 0
            self.activityLabel.alpha = shouldShowActivity ? 1 : 0
        }
    }
    
    private func updateDesiredVictimIndicator() {
        let player = GameStateService.shared.getPlayer()!
        let isDesiredVictim = !npc.isUnknown && player.desiredVictim.isDesiredVictim(npc: npc)
        
        // Animate the visibility change
        UIView.animate(withDuration: 0.3) {
            self.desiredVictimView.alpha = isDesiredVictim ? 1.0 : 0.0
        }
    }
    
    private func updateRelationshipInfo() {
        UIView.animate(withDuration: 0.3) {
            // Hide resistance UI
            self.resistanceLabel.alpha = 0
            self.resistanceValueLabel.alpha = 0
            self.resistanceProgressView.alpha = 0
            
            // Show relationship UI
            self.relationshipLabel.alpha = 1
            self.relationshipValueLabel.alpha = 1
            self.relationshipProgressView.alpha = 1
            
            // Update relationship text and progress
            let relationshipValue = self.npc.playerRelationship.value
            self.relationshipValueLabel.text = relationshipValue < 0 ? "-\(abs(relationshipValue))%" : "\(relationshipValue)%"
            self.relationshipValueLabel.textColor = relationshipValue < 0 ? UIColor(Theme.bloodProgressColor) : UIColor.green
        }
        
        // Animate progress change
        UIView.animate(withDuration: 0.5) {
            let relationshipValue = self.npc.playerRelationship.value
            self.relationshipProgressView.progressTintColor = relationshipValue < 0 ? UIColor.red : UIColor.green
            self.relationshipProgressView.setProgress(Float(Float(abs(relationshipValue)) / 100.0), animated: true)
        }
    }
    
    private func updateResistanceInfo() {
        UIView.animate(withDuration: 0.3) {
            // Hide relationship UI
            self.relationshipLabel.alpha = 0
            self.relationshipValueLabel.alpha = 0
            self.relationshipProgressView.alpha = 0
            
            // Show resistance UI
            self.resistanceLabel.alpha = 1
            self.resistanceValueLabel.alpha = 1
            self.resistanceProgressView.alpha = 1
            
            // Update resistance text and progress
            let resistanceValue = VampireGazeSystem.shared.calculateNPCResistance(npc: self.npc)
            self.resistanceValueLabel.text = String(format: "%.1f%%", resistanceValue)
            self.resistanceValueLabel.textColor = self.getRelationshipColor()
        }
        
        // Animate progress change
        UIView.animate(withDuration: 0.5) {
            let resistanceValue = VampireGazeSystem.shared.calculateNPCResistance(npc: self.npc)
            self.resistanceProgressView.setProgress(Float(resistanceValue / 100.0), animated: true)
        }
    }
    
    private func updateProfessionAndActivity() {
        // Animate UI updates
        UIView.animate(withDuration: 0.3) {
            // Update profession
            let professionIconName = self.npc.profession.icon
            self.professionIconImageView.image = UIImage(systemName: professionIconName)
            self.professionIconImageView.tintColor = self.convertSwiftUIColorToUIColor(self.npc.profession.color)
            self.professionLabel.text = self.npc.profession.rawValue.capitalized
            self.professionLabel.textColor = UIColor(Theme.textColor) // Always white text for better visibility
            
            // Ensure text truncates properly with ellipsis if too long
            self.professionLabel.lineBreakMode = .byTruncatingTail
            self.activityLabel.lineBreakMode = .byTruncatingTail
            
            // Show/hide profession based on aliveness
            let showProfession = self.npc.isAlive
            self.professionIconImageView.alpha = showProfession ? 1.0 : 0.0
            self.professionLabel.alpha = showProfession ? 1.0 : 0.0
            
            // Show/hide activity based on setting and aliveness
            let shouldShowActivity = self.showCurrentActivity && self.npc.isAlive
            self.activityIconImageView.alpha = shouldShowActivity ? 1.0 : 0.0
            self.activityLabel.alpha = shouldShowActivity ? 1.0 : 0.0
            
            if shouldShowActivity {
                let activityIconName = self.npc.isAlive ? self.npc.currentActivity.icon : "xmark.circle.fill"
                self.activityIconImageView.image = UIImage(systemName: activityIconName)
                self.activityIconImageView.tintColor = self.npc.isAlive ? 
                    self.convertSwiftUIColorToUIColor(self.npc.currentActivity.color) : UIColor(Theme.bloodProgressColor)
                self.activityLabel.text = self.npc.isAlive ? self.npc.currentActivity.description.capitalized : "Dead"
                self.activityLabel.textColor = UIColor(Theme.textColor) // Always white text for activity too
            }
        }
    }
    
    private func updateSelectedState() {
        if isSelected {
            // Simple, subtle selection indicator without any border
            let highlightOverlay = UIView()
            highlightOverlay.frame = containerView.bounds
            highlightOverlay.backgroundColor = UIColor.white.withAlphaComponent(0.0) // Start with transparent
            highlightOverlay.layer.cornerRadius = 12
            highlightOverlay.tag = 999
            
            // Remove any existing highlight overlays before adding a new one
            containerView.subviews.forEach { view in
                if view.tag == 999 {
                    view.removeFromSuperview()
                }
            }
            
            containerView.insertSubview(highlightOverlay, at: 1)
            
            // Animate the highlight effect
            UIView.animate(withDuration: 0.3) {
                highlightOverlay.backgroundColor = UIColor.white.withAlphaComponent(0.05)
            }
        } else {
            // Find any existing highlight overlays
            let overlays = containerView.subviews.filter { $0.tag == 999 }
            
            // Animate fade out before removing
            UIView.animate(withDuration: 0.2, animations: {
                overlays.forEach { $0.alpha = 0 }
            }, completion: { _ in
                // Remove highlight overlay when animation completes
                overlays.forEach { $0.removeFromSuperview() }
            })
        }
    }
    
    private func getRelationshipColor() -> UIColor {
        if npc.playerRelationship.value < 0 {
            return UIColor(Theme.bloodProgressColor)
        } else {
            return UIColor.green
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update gradient layer frame
        if let gradientLayer = backgroundView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = backgroundView.bounds
        }
        
        // Add shadow to container - exactly matching PlayerWidget
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 1, height: 1)
        containerView.layer.shadowRadius = 15
        containerView.layer.shadowOpacity = 1.0
        containerView.layer.masksToBounds = false
    }
    
    // Helper method to convert SwiftUI Color to UIKit UIColor
    private func convertSwiftUIColorToUIColor(_ color: Color) -> UIColor {
        // Use modern system colors for better appearance
        if color == .red { return UIColor.systemRed }
        if color == .blue { return UIColor.systemBlue }
        if color == .green { return UIColor.systemGreen }
        if color == .yellow { return UIColor.systemYellow }
        if color == .orange { return UIColor.systemOrange }
        if color == .purple { return UIColor.systemPurple }
        if color == .pink { return UIColor.systemPink }
        if color == .gray { return UIColor.systemGray }
        if color == .brown { 
            if #available(iOS 15.0, *) {
                return UIColor.systemBrown
            } else {
                return UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0) // Brown approximation
            }
        }
        if color == .cyan { return UIColor.systemCyan }
        if color == .mint { 
            if #available(iOS 15.0, *) {
                return UIColor.systemMint
            } else {
                return UIColor(red: 0, green: 0.8, blue: 0.6, alpha: 1.0) // Mint approximation
            }
        }
        if color == .teal { 
            if #available(iOS 15.0, *) {
                return UIColor.systemTeal
            } else {
                return UIColor(red: 0, green: 0.5, blue: 0.5, alpha: 1.0) // Teal approximation
            }
        }
        if color == .indigo {
            if #available(iOS 15.0, *) {
                return UIColor.systemIndigo
        } else {
                return UIColor(red: 0.3, green: 0, blue: 0.5, alpha: 1.0) // Indigo approximation
            }
        }
        
        // Default fallback - white
        return UIColor.white
    }
    
    deinit {
        // Cancel all subscriptions
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
