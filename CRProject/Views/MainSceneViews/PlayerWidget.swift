//
//  PlayerWidget.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 23.04.2025.
//

import SwiftUICore
import SwiftUI
import UIKit
import Combine

// MARK: - SwiftUI Bridge
struct PlayerWidget: View {
    let player: Player

    var body: some View {
        PlayerWidgetUIViewControllerRepresentable(
            player: player
        )
        .frame(width: 180, height: 320) // Фиксированный размер виджета
    }
}

struct PlayerWidgetUIViewControllerRepresentable: UIViewControllerRepresentable {
    let player: Player
    
    func makeUIViewController(context: Context) -> PlayerWidgetUIViewController {
        return PlayerWidgetUIViewController(
            player: player
        )
    }
    
    func updateUIViewController(_ uiViewController: PlayerWidgetUIViewController, context: Context) {
        uiViewController.updatePlayer(
            player: player
        )
    }
}

// MARK: - UIKit Implementation
class PlayerWidgetUIViewController: UIViewController {
    // MARK: - Properties
    private var player: Player
    private var cancellables = Set<AnyCancellable>()
    
    // UI Components
    private let containerView = UIView()
    private let backgroundView = UIView()
    private let playerImageView = UIImageView()
    private let playerNameLabel = UILabel()
    private let playerAgeLabel = UILabel()
    private let playerGenderImageView = UIImageView()
    private let healthLabel = UILabel()
    private let healthValueLabel = UILabel()
    private let healthProgressView = UIProgressView(progressViewStyle: .default)
    private let jailLabel = UILabel()
    private let jailValueLabel = UILabel()
    private let jailProgressView = UIProgressView(progressViewStyle: .default)
    private let professionIconImageView = UIImageView()
    private let professionLabel = UILabel()
    private let activityIconImageView = UIImageView()
    private let activityLabel = UILabel()
    private let unknownIcon = UILabel()
    private let desiredVictimView = UIView()
    
    // MARK: - Initializers
    init(player: Player) {
        self.player = player
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupplayerObservation()
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
            convertSwiftUIColorToUIColor(player.profession.color).withAlphaComponent(0.05).cgColor
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
        
        // Setup player image view
        playerImageView.translatesAutoresizingMaskIntoConstraints = false
        playerImageView.contentMode = .scaleAspectFill
        playerImageView.clipsToBounds = true
        playerImageView.layer.cornerRadius = 8
        playerImageView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        playerImageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        playerImageView.layer.shadowRadius = 4
        playerImageView.layer.shadowOpacity = 1.0
        containerView.addSubview(playerImageView)
        
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
        
        // Setup player information labels
        playerGenderImageView.translatesAutoresizingMaskIntoConstraints = false
        playerGenderImageView.contentMode = .scaleAspectFit
        playerGenderImageView.tintColor = UIColor(Theme.primaryColor)
        containerView.addSubview(playerGenderImageView)
        
        playerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        playerNameLabel.textColor = UIColor(Theme.textColor)
        playerNameLabel.font = UIFont(name: "Optima", size: 12)
        playerNameLabel.adjustsFontSizeToFitWidth = false
        containerView.addSubview(playerNameLabel)
        
        playerAgeLabel.translatesAutoresizingMaskIntoConstraints = false
        playerAgeLabel.textColor = UIColor(Theme.textColor)
        playerAgeLabel.font = UIFont(name: "Optima", size: 12)
        playerAgeLabel.adjustsFontSizeToFitWidth = false
        playerAgeLabel.textAlignment = .right
        containerView.addSubview(playerAgeLabel)
        
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
        
        // Setup jail section
        jailLabel.translatesAutoresizingMaskIntoConstraints = false
        jailLabel.textColor = UIColor(Theme.textColor)
        jailLabel.font = UIFont(name: "Optima", size: 12)
        jailLabel.adjustsFontSizeToFitWidth = false
        jailLabel.text = "Jailed"
        jailLabel.isHidden = true
        containerView.addSubview(jailLabel)
        
        jailValueLabel.translatesAutoresizingMaskIntoConstraints = false
        jailValueLabel.textColor = UIColor.orange
        jailValueLabel.font = UIFont(name: "Optima", size: 12)
        jailValueLabel.adjustsFontSizeToFitWidth = false
        jailValueLabel.textAlignment = .right
        jailValueLabel.isHidden = true
        containerView.addSubview(jailValueLabel)
        
        jailProgressView.translatesAutoresizingMaskIntoConstraints = false
        jailProgressView.progressTintColor = UIColor.orange
        jailProgressView.trackTintColor = UIColor.black.withAlphaComponent(0.5)
        jailProgressView.layer.cornerRadius = 4
        jailProgressView.clipsToBounds = true
        jailProgressView.layer.borderWidth = 1
        jailProgressView.layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor
        jailProgressView.isHidden = true
        containerView.addSubview(jailProgressView)
        
        // Setup profession and activity section
        professionIconImageView.translatesAutoresizingMaskIntoConstraints = false
        professionIconImageView.contentMode = .scaleAspectFit
        professionIconImageView.tintColor = convertSwiftUIColorToUIColor(player.profession.color)
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
            
            // player image constraints
            playerImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            playerImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            playerImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            playerImageView.heightAnchor.constraint(equalToConstant: 180),
            
            // Unknown icon constraints
            unknownIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            unknownIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // player info constraints
            playerGenderImageView.topAnchor.constraint(equalTo: playerImageView.bottomAnchor, constant: 8),
            playerGenderImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            playerGenderImageView.widthAnchor.constraint(equalToConstant: 20),
            playerGenderImageView.heightAnchor.constraint(equalToConstant: 20),
            
            playerNameLabel.centerYAnchor.constraint(equalTo: playerGenderImageView.centerYAnchor),
            playerNameLabel.leadingAnchor.constraint(equalTo: playerGenderImageView.trailingAnchor, constant: 4),
            
            playerAgeLabel.centerYAnchor.constraint(equalTo: playerGenderImageView.centerYAnchor),
            playerAgeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            playerAgeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: playerNameLabel.trailingAnchor, constant: 4),
            
            // Health section constraints
            healthLabel.topAnchor.constraint(equalTo: playerGenderImageView.bottomAnchor, constant: 8),
            healthLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            
            healthValueLabel.centerYAnchor.constraint(equalTo: healthLabel.centerYAnchor),
            healthValueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            healthProgressView.topAnchor.constraint(equalTo: healthLabel.bottomAnchor, constant: 4),
            healthProgressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            healthProgressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            healthProgressView.heightAnchor.constraint(equalToConstant: 6),
            
            // Jail section constraints
            jailLabel.topAnchor.constraint(equalTo: healthProgressView.bottomAnchor, constant: 8),
            jailLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            
            jailValueLabel.centerYAnchor.constraint(equalTo: jailLabel.centerYAnchor),
            jailValueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            jailProgressView.topAnchor.constraint(equalTo: jailLabel.bottomAnchor, constant: 4),
            jailProgressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            jailProgressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            jailProgressView.heightAnchor.constraint(equalToConstant: 6),
            
            // Profession row - icon left, text right
            professionIconImageView.topAnchor.constraint(equalTo: jailProgressView.bottomAnchor, constant: 12),
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
    func updatePlayer(player: Player) {
        // Cancel existing observations
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        self.player = player
        
        // Setup new observations
        setupplayerObservation()
        
        // Simply call updateUI() to refresh all UI components
        updateUI()
    }
    
    private func setupplayerObservation() {
        // Observe bloodMeter changes
        player.bloodMeter.$currentBlood
            .dropFirst() // Skip initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
            
        // Observe arrest status changes
        player.$isArrested
            .dropFirst() // Skip initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
        
        player.$arrestTime
            .dropFirst() // Skip initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)
            
        // Observe isAlive changes (via bloodMeter)
        player.bloodMeter.$currentBlood
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
            self.unknownIcon.alpha = 0.0
            
            self.showDetailsForKnownplayer()
            
            // Update player information
            self.playerGenderImageView.image = UIImage(systemName: self.player.sex == .female ? "figure.stand.dress" : "figure.wave")
            self.playerGenderImageView.tintColor = UIColor(Theme.primaryColor)
            self.playerNameLabel.text = self.player.name
            self.playerAgeLabel.text = "Age \(self.player.age)"
            
            // Update health information with smooth progress bar transition
            self.healthValueLabel.text = String(format: "%.1f%%", self.player.bloodMeter.currentBlood)
            self.healthProgressView.setProgress(Float(self.player.bloodMeter.currentBlood / 100.0), animated: true)
            
            // Update jail status if player is arrested
            self.updateJailStatus()
            
            // Update profession and activity information
            self.updateProfessionAndActivity()
            
            // Highlight if selected
            self.updateSelectedState()
        }
        
        // Set player image with crossfade
        UIView.transition(with: playerImageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.playerImageView.image = UIImage(named: "player1")
        }, completion: nil)
        
        // Update gradient in background with animation
        if let gradientLayer = backgroundView.layer.sublayers?.first as? CAGradientLayer {
            let colorAnimation = CABasicAnimation(keyPath: "colors")
            colorAnimation.fromValue = gradientLayer.colors
            colorAnimation.toValue = [
                UIColor.black.withAlphaComponent(0.8).cgColor,
                convertSwiftUIColorToUIColor(self.player.profession.color).withAlphaComponent(0.05).cgColor
            ]
            colorAnimation.duration = 0.3
            colorAnimation.fillMode = .forwards
            colorAnimation.isRemovedOnCompletion = false
            gradientLayer.add(colorAnimation, forKey: "colorsAnimation")
            
            gradientLayer.colors = [
                UIColor.black.withAlphaComponent(0.8).cgColor,
                convertSwiftUIColorToUIColor(self.player.profession.color).withAlphaComponent(0.05).cgColor
            ]
            gradientLayer.frame = backgroundView.bounds
        }
        
        // Force layout update
        view.setNeedsLayout()
    }
    
    private func hideAllDetailsForUnknown() {
        UIView.animate(withDuration: 0.3) {
            self.playerGenderImageView.alpha = 0
            self.playerNameLabel.alpha = 0
            self.playerAgeLabel.alpha = 0
            self.healthLabel.alpha = 0
            self.healthValueLabel.alpha = 0
            self.healthProgressView.alpha = 0
            self.jailLabel.alpha = 0
            self.jailValueLabel.alpha = 0
            self.jailProgressView.alpha = 0
            self.professionIconImageView.alpha = 0
            self.professionLabel.alpha = 0
            self.activityIconImageView.alpha = 0
            self.activityLabel.alpha = 0
        }
    }
    
    private func showDetailsForKnownplayer() {
        UIView.animate(withDuration: 0.3) {
            // Basic info always visible for known players
            self.playerGenderImageView.alpha = 1
            self.playerNameLabel.alpha = 1
            self.playerAgeLabel.alpha = 1
            self.healthLabel.alpha = 1
            self.healthValueLabel.alpha = 1
            self.healthProgressView.alpha = 1
            
            // Jail info is conditionally visible
            let isJailed = self.player.isArrested && self.player.arrestTime > 0
            self.jailLabel.alpha = isJailed ? 1 : 0
            self.jailValueLabel.alpha = isJailed ? 1 : 0
            self.jailProgressView.alpha = isJailed ? 1 : 0
            
            // Show profession only if player is alive
            let showProfession = self.player.isAlive
            self.professionIconImageView.alpha = showProfession ? 1 : 0
            self.professionLabel.alpha = showProfession ? 1 : 0
            
            // Show activity based on setting and aliveness
            let shouldShowActivity = true
            self.activityIconImageView.alpha = shouldShowActivity ? 1 : 0
            self.activityLabel.alpha = shouldShowActivity ? 1 : 0
        }
    }
    
    private func updateProfessionAndActivity() {
        // Animate UI updates
        UIView.animate(withDuration: 0.3) {
            // Update profession
            let professionIconName = self.player.profession.icon
            self.professionIconImageView.image = UIImage(systemName: professionIconName)
            self.professionIconImageView.tintColor = self.convertSwiftUIColorToUIColor(self.player.profession.color)
            self.professionLabel.text = self.player.profession.rawValue.capitalized
            self.professionLabel.textColor = UIColor(Theme.textColor) // Always white text for better visibility
            
            // Ensure text truncates properly with ellipsis if too long
            self.professionLabel.lineBreakMode = .byTruncatingTail
            self.activityLabel.lineBreakMode = .byTruncatingTail
            
            // Show/hide profession based on aliveness
            let showProfession = self.player.isAlive
            self.professionIconImageView.alpha = showProfession ? 1.0 : 0.0
            self.professionLabel.alpha = showProfession ? 1.0 : 0.0
            
            // Show/hide activity based on setting and aliveness
            let shouldShowActivity = true
            self.activityIconImageView.alpha = shouldShowActivity ? 1.0 : 0.0
            self.activityLabel.alpha = shouldShowActivity ? 1.0 : 0.0
        }
    }
    
    private func updateSelectedState() {
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
    }
    
    private func updateJailStatus() {
        // Show jail status only if player is arrested and has arrest time
        let isJailed = player.isArrested && player.arrestTime > 0
        
        // Update visibility
        jailLabel.isHidden = !isJailed
        jailValueLabel.isHidden = !isJailed
        jailProgressView.isHidden = !isJailed
        
        if isJailed {
            // Calculate jail time percentage
            let maxJailTime = Double(StatisticsService.shared.timesArrested * 24)
            let currentJailTime = Double(player.arrestTime)
            let jailTimePercentage = min(100.0, (currentJailTime / maxJailTime) * 100.0)
            
            // Update UI
            jailValueLabel.text = String(format: "%.1f%%", jailTimePercentage)
            jailProgressView.setProgress(Float(jailTimePercentage / 100.0), animated: true)
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
