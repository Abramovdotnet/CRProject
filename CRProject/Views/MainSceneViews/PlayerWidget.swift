//
//  PlayerWidget.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 23.04.2025.
//

import SwiftUICore
import SwiftUI
import UIKit

// MARK: - SwiftUI Implementation
struct PlayerWidgetSwiftUI : View {
    let player: Player
 
    private let buttonWidth: CGFloat = 180

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.8),
                            Color(player.profession.color).opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .frame(width: buttonWidth, height: 320)
            
            // Content (Image and Text)
            VStack(alignment: .leading, spacing: 0) {
                // Image container with parallax
                ZStack {
                    Image("player1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: buttonWidth, height: 180)
                        .clipped() // Add clipping after the frame
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                }
                .frame(width: buttonWidth, height: 180)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: player.sex == .female ? "figure.stand.dress" : "figure.wave")
                            .font(Theme.bodyFont)
                            .foregroundColor(player.isVampire ? Theme.primaryColor : Theme.textColor)
                        Text(player.name)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                        Spacer()
                        Text("Age \(player.age)")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top) {
                            Text("Health")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textColor)
                            Spacer()
                            Text(String(format: "%.1f%%", player.bloodMeter.currentBlood))
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.bloodProgressColor)
                        }
                        
                        ProgressBar(value: Double(player.bloodMeter.currentBlood / 100), color: Theme.bloodProgressColor, height: 6)
                            .shadow(color: Theme.bloodProgressColor.opacity(0.3), radius: 2)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            }
            
            VStack(alignment: .trailing) {
                Spacer()
                VStack {
                    HStack {
                        Image(systemName: player.profession.icon)
                            .font(Theme.bodyFont)
                            .foregroundColor(player.profession.color)
                            .lineLimit(1)
                        Text("\(player.profession.rawValue)")
                            .font(Theme.bodyFont)
                            .foregroundColor(player.profession.color)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.bottom, 6)
            .padding(.top, 2)
            .padding(.horizontal, 8)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 2)
                .background(Color.white.opacity(0.05))
                .blur(radius: 0.5)
        }
        .frame(width: buttonWidth, height: 320)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .blur(radius: 2)
                .offset(y: 2)
        )
        .shadow(color: .black, radius: 15, x: 1, y: 1)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - SwiftUI Bridge (используется для интеграции UIKit с SwiftUI)
struct PlayerWidget: View {
    let player: Player
    
    var body: some View {
        PlayerWidgetUIViewControllerRepresentable(player: player)
            .frame(width: 180, height: 320) // Фиксированный размер виджета
    }
}

struct PlayerWidgetUIViewControllerRepresentable: UIViewControllerRepresentable {
    let player: Player
    
    func makeUIViewController(context: Context) -> PlayerWidgetUIViewController {
        return PlayerWidgetUIViewController(player: player)
    }
    
    func updateUIViewController(_ uiViewController: PlayerWidgetUIViewController, context: Context) {
        uiViewController.updatePlayer(player: player)
    }
}

// MARK: - UIKit Implementation
class PlayerWidgetUIViewController: UIViewController {
    // MARK: - Properties
    private var player: Player
    
    // UI Components
    private let containerView = UIView()
    private let backgroundView = UIView()
    private let playerImageView = UIImageView()
    private let playerNameLabel = UILabel()
    private let playerAgeLabel = UILabel()
    private let playerGenderImageView = UIImageView()
    private let healthLabel = UILabel()
    private let healthValueLabel = UILabel()
    private let healthProgressView = CustomHeightUIProgressView()
    private let professionIconImageView = UIImageView()
    private let professionLabel = UILabel()
    
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
        backgroundView.layer.borderWidth = 0.5
        backgroundView.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        
        // Создание градиента для фона
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.8).cgColor,
            UIColor(player.profession.color).withAlphaComponent(0.05).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.cornerRadius = 12
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        containerView.addSubview(backgroundView)
        
        // Добавляем черный полупрозрачный фон для всей карточки
        let infoBackgroundView = UIView()
        infoBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        infoBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        infoBackgroundView.layer.cornerRadius = 12
        containerView.addSubview(infoBackgroundView)
        
        // Setup player image view
        playerImageView.translatesAutoresizingMaskIntoConstraints = false
        playerImageView.contentMode = .scaleAspectFill
        playerImageView.image = UIImage(named: "player1")
        playerImageView.clipsToBounds = true
        playerImageView.layer.cornerRadius = 12
        playerImageView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        playerImageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        playerImageView.layer.shadowRadius = 4
        playerImageView.layer.shadowOpacity = 1.0
        containerView.addSubview(playerImageView)
        
        // Setup player information labels
        playerGenderImageView.translatesAutoresizingMaskIntoConstraints = false
        playerGenderImageView.contentMode = .scaleAspectFit
        playerGenderImageView.tintColor = player.isVampire ? 
            UIColor(Theme.primaryColor) : UIColor(Theme.textColor)
        containerView.addSubview(playerGenderImageView)
        
        playerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        playerNameLabel.textColor = UIColor(Theme.textColor)
        playerNameLabel.font = UIFont(name: "Optima", size: 12)
        containerView.addSubview(playerNameLabel)
        
        playerAgeLabel.translatesAutoresizingMaskIntoConstraints = false
        playerAgeLabel.textColor = UIColor(Theme.textColor)
        playerAgeLabel.font = UIFont(name: "Optima", size: 12)
        playerAgeLabel.textAlignment = .right
        containerView.addSubview(playerAgeLabel)
        
        // Setup health section
        healthLabel.translatesAutoresizingMaskIntoConstraints = false
        healthLabel.textColor = UIColor(Theme.textColor)
        healthLabel.font = UIFont(name: "Optima", size: 12)
        healthLabel.text = "Health"
        containerView.addSubview(healthLabel)
        
        healthValueLabel.translatesAutoresizingMaskIntoConstraints = false
        healthValueLabel.textColor = UIColor(Theme.bloodProgressColor)
        healthValueLabel.font = UIFont(name: "Optima", size: 12)
        healthValueLabel.textAlignment = .right
        containerView.addSubview(healthValueLabel)
        
        healthProgressView.translatesAutoresizingMaskIntoConstraints = false
        healthProgressView.progressTintColor = UIColor(Theme.bloodProgressColor)
        healthProgressView.trackTintColor = UIColor.black.withAlphaComponent(0.5)
        healthProgressView.layer.cornerRadius = 4
        healthProgressView.clipsToBounds = true
        healthProgressView.layer.borderWidth = 1
        healthProgressView.layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor
        healthProgressView.progress = Float(player.bloodMeter.currentBlood / 100)
        containerView.addSubview(healthProgressView)
        
        // Setup profession section
        professionIconImageView.translatesAutoresizingMaskIntoConstraints = false
        professionIconImageView.contentMode = .scaleAspectFit
        professionIconImageView.tintColor = UIColor(player.profession.color)
        containerView.addSubview(professionIconImageView)
        
        professionLabel.translatesAutoresizingMaskIntoConstraints = false
        professionLabel.textColor = UIColor(player.profession.color)
        professionLabel.font = UIFont(name: "Optima", size: 12)
        containerView.addSubview(professionLabel)
        
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
            
            // Player image constraints
            playerImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            playerImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            playerImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            playerImageView.heightAnchor.constraint(equalToConstant: 180),
            
            // Info background constraints
            infoBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
            infoBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            infoBackgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            infoBackgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Player info constraints
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
            healthLabel.topAnchor.constraint(equalTo: playerGenderImageView.bottomAnchor, constant: 12),
            healthLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            
            healthValueLabel.centerYAnchor.constraint(equalTo: healthLabel.centerYAnchor),
            healthValueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            healthProgressView.topAnchor.constraint(equalTo: healthLabel.bottomAnchor, constant: 4),
            healthProgressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            healthProgressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            healthProgressView.heightAnchor.constraint(equalToConstant: 6),
            
            // Profession section constraints
            professionIconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            professionIconImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            professionIconImageView.widthAnchor.constraint(equalToConstant: 20),
            professionIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            professionLabel.centerYAnchor.constraint(equalTo: professionIconImageView.centerYAnchor),
            professionLabel.leadingAnchor.constraint(equalTo: professionIconImageView.trailingAnchor, constant: 4),
            professionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8)
        ])
    }
    
    // MARK: - Update Methods
    func updatePlayer(player: Player) {
        self.player = player
        updateUI()
    }
    
    private func updateUI() {
        // Update player image
        playerImageView.image = UIImage(named: "player1")
        
        // Update player information
        playerGenderImageView.image = UIImage(systemName: player.sex == .female ? "figure.stand.dress" : "figure.wave")
        playerNameLabel.text = player.name
        playerAgeLabel.text = "Age \(player.age)"
        
        // Update health information
        healthValueLabel.text = String(format: "%.1f%%", player.bloodMeter.currentBlood)
        healthProgressView.progress = Float(player.bloodMeter.currentBlood / 100)
        
        // Update profession information
        professionIconImageView.image = UIImage(systemName: player.profession.icon)
        professionLabel.text = player.profession.rawValue
        
        // Update gradient in background
        if let gradientLayer = backgroundView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.colors = [
                UIColor.black.withAlphaComponent(0.8).cgColor,
                UIColor(player.profession.color).withAlphaComponent(0.05).cgColor
            ]
            gradientLayer.frame = backgroundView.bounds
        }
        
        // Resize layout if frame size changed
        view.setNeedsLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update gradient layer frame
        if let gradientLayer = backgroundView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = backgroundView.bounds
        }
        
        // Add shadow to container
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 1, height: 1)
        containerView.layer.shadowRadius = 15
        containerView.layer.shadowOpacity = 1.0
        containerView.layer.masksToBounds = false
    }
}
