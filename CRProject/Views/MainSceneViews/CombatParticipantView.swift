import UIKit

enum CombatParticipantAlignment {
    case left, right, center
}

class CombatParticipantView: UIView {
    private let avatarImageView = UIImageView()
    private let avatarShadowContainer = UIView()
    private let professionIcon = UIImageView()
    private let combatIcon = UIImageView()
    let healthIndicator = CAShapeLayer()
    private let healthPercentageLabel = UILabel()
    private let selectionGlowLayer = CALayer()
    private let cardBackground = UIView()
    private let nameLabel = UILabel()
    
    private let iconSize: CGFloat = 22
    private let alignment: CombatParticipantAlignment
    
    init(alignment: CombatParticipantAlignment = .center) {
        self.alignment = alignment
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        self.alignment = .center
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // cardBackground
        cardBackground.backgroundColor = UIColor.clear
        cardBackground.layer.cornerRadius = 12
        cardBackground.layer.borderWidth = 0
        cardBackground.clipsToBounds = false
        cardBackground.layer.masksToBounds = false
        addSubview(cardBackground)
        cardBackground.translatesAutoresizingMaskIntoConstraints = false
        
        let newAvatarSize: CGFloat = 84
        let newAvatarRadius: CGFloat = newAvatarSize / 2
        let avatarY: CGFloat = 8
        let avatarX: CGFloat
        switch alignment {
        case .left:
            avatarX = 0
        case .right:
            avatarX = bounds.width - newAvatarSize
        case .center:
            avatarX = (bounds.width - newAvatarSize) / 2
        }
        // Используем Auto Layout для cardBackground
        switch alignment {
        case .left:
            NSLayoutConstraint.activate([
                cardBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
                cardBackground.topAnchor.constraint(equalTo: topAnchor),
                cardBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
                cardBackground.widthAnchor.constraint(equalToConstant: newAvatarSize)
            ])
        case .right:
            NSLayoutConstraint.activate([
                cardBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
                cardBackground.topAnchor.constraint(equalTo: topAnchor),
                cardBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
                cardBackground.widthAnchor.constraint(equalToConstant: newAvatarSize)
            ])
        case .center:
            NSLayoutConstraint.activate([
                cardBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
                cardBackground.topAnchor.constraint(equalTo: topAnchor),
                cardBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
                cardBackground.widthAnchor.constraint(equalToConstant: newAvatarSize)
            ])
        }
        
        // avatarShadowContainer
        avatarShadowContainer.translatesAutoresizingMaskIntoConstraints = false
        cardBackground.addSubview(avatarShadowContainer)
        NSLayoutConstraint.activate([
            avatarShadowContainer.topAnchor.constraint(equalTo: cardBackground.topAnchor, constant: avatarY),
            avatarShadowContainer.leadingAnchor.constraint(equalTo: cardBackground.leadingAnchor),
            avatarShadowContainer.widthAnchor.constraint(equalToConstant: newAvatarSize),
            avatarShadowContainer.heightAnchor.constraint(equalToConstant: newAvatarSize)
        ])
        avatarShadowContainer.layer.cornerRadius = newAvatarRadius
        avatarShadowContainer.layer.shadowColor = UIColor.black.cgColor
        avatarShadowContainer.layer.shadowRadius = 10
        avatarShadowContainer.layer.shadowOpacity = 0.8
        avatarShadowContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        avatarShadowContainer.backgroundColor = .clear
        avatarShadowContainer.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: newAvatarSize, height: newAvatarSize), cornerRadius: newAvatarRadius).cgPath
        
        // avatarImageView
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        cardBackground.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: cardBackground.topAnchor, constant: avatarY),
            avatarImageView.leadingAnchor.constraint(equalTo: cardBackground.leadingAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: newAvatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: newAvatarSize)
        ])
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = newAvatarRadius
        avatarImageView.layer.borderWidth = 1
        avatarImageView.layer.borderColor = UIColor.black.cgColor
        
        // selectionGlowLayer
        selectionGlowLayer.frame = CGRect(x: 0, y: avatarY, width: newAvatarSize, height: newAvatarSize)
        selectionGlowLayer.cornerRadius = newAvatarRadius
        selectionGlowLayer.shadowColor = UIColor.red.cgColor
        selectionGlowLayer.shadowRadius = 8
        selectionGlowLayer.shadowOpacity = 0
        selectionGlowLayer.shadowOffset = .zero
        cardBackground.layer.insertSublayer(selectionGlowLayer, below: avatarImageView.layer)
        
        // healthIndicator
        let healthIndicatorSize = newAvatarSize + 6
        healthIndicator.frame = CGRect(x: -3, y: avatarY - 3, width: healthIndicatorSize, height: healthIndicatorSize)
        healthIndicator.lineWidth = 3
        healthIndicator.fillColor = UIColor.clear.cgColor
        healthIndicator.strokeColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1).cgColor
        healthIndicator.lineCap = .round
        healthIndicator.opacity = 1.0
        healthIndicator.shadowColor = UIColor.red.cgColor
        healthIndicator.shadowRadius = 4
        healthIndicator.shadowOpacity = 0.8
        healthIndicator.shadowOffset = CGSize.zero
        cardBackground.layer.addSublayer(healthIndicator)
        
        let textFont = UIFont(name: "Optima", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .regular)
        
        // healthPercentageLabel
        healthPercentageLabel.translatesAutoresizingMaskIntoConstraints = false
        cardBackground.addSubview(healthPercentageLabel)
        NSLayoutConstraint.activate([
            healthPercentageLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 0),
            healthPercentageLabel.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            healthPercentageLabel.widthAnchor.constraint(equalToConstant: 40),
            healthPercentageLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
        healthPercentageLabel.font = textFont
        healthPercentageLabel.textColor = UIColor.white
        healthPercentageLabel.textAlignment = .center
        healthPercentageLabel.backgroundColor = UIColor.clear
        healthPercentageLabel.clipsToBounds = false
        healthPercentageLabel.layer.shadowColor = UIColor.black.cgColor
        healthPercentageLabel.layer.shadowRadius = 2
        healthPercentageLabel.layer.shadowOpacity = 1
        healthPercentageLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        // professionIcon (слева)
        professionIcon.translatesAutoresizingMaskIntoConstraints = false
        cardBackground.addSubview(professionIcon)
        NSLayoutConstraint.activate([
            professionIcon.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor, constant: -10),
            professionIcon.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: -8),
            professionIcon.widthAnchor.constraint(equalToConstant: iconSize),
            professionIcon.heightAnchor.constraint(equalToConstant: iconSize)
        ])
        professionIcon.contentMode = .scaleAspectFit
        professionIcon.backgroundColor = UIColor.clear
        professionIcon.clipsToBounds = false
        professionIcon.layer.shadowColor = UIColor.black.cgColor
        professionIcon.layer.shadowRadius = 2
        professionIcon.layer.shadowOpacity = 1
        professionIcon.layer.shadowOffset = CGSize(width: 0, height: 1)
        professionIcon.layer.cornerRadius = iconSize / 2
        professionIcon.layer.borderWidth = 0.5
        professionIcon.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        professionIcon.layer.backgroundColor = UIColor.black.withAlphaComponent(0.7).cgColor
        professionIcon.alpha = 1.0
        professionIcon.layer.shadowColor = UIColor.black.cgColor
        professionIcon.layer.shadowRadius = 3
        professionIcon.layer.shadowOpacity = 0.6
        professionIcon.layer.shadowOffset = CGSize.zero
        
        // combatIcon (справа)
        combatIcon.translatesAutoresizingMaskIntoConstraints = false
        cardBackground.addSubview(combatIcon)
        NSLayoutConstraint.activate([
            combatIcon.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            combatIcon.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: -8),
            combatIcon.widthAnchor.constraint(equalToConstant: iconSize),
            combatIcon.heightAnchor.constraint(equalToConstant: iconSize)
        ])
        combatIcon.contentMode = .scaleAspectFit
        combatIcon.backgroundColor = UIColor.clear
        combatIcon.clipsToBounds = false
        combatIcon.layer.shadowColor = UIColor.black.cgColor
        combatIcon.layer.shadowRadius = 2
        combatIcon.layer.shadowOpacity = 1
        combatIcon.layer.shadowOffset = CGSize(width: 0, height: 1)
        combatIcon.layer.cornerRadius = iconSize / 2
        combatIcon.layer.borderWidth = 0.5
        combatIcon.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        combatIcon.layer.backgroundColor = UIColor.black.withAlphaComponent(0.7).cgColor
        combatIcon.alpha = 1.0
        combatIcon.layer.shadowColor = UIColor.black.cgColor
        combatIcon.layer.shadowRadius = 3
        combatIcon.layer.shadowOpacity = 0.6
        combatIcon.layer.shadowOffset = CGSize.zero
        
        // nameLabel (под аватаром)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardBackground.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 22),
            nameLabel.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            nameLabel.widthAnchor.constraint(equalTo: cardBackground.widthAnchor),
            nameLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
        nameLabel.font = UIFont(name: "Optima-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13)
        nameLabel.textColor = UIColor.white
        nameLabel.textAlignment = .center
        nameLabel.backgroundColor = UIColor.clear
        nameLabel.layer.shadowColor = UIColor.black.cgColor
        nameLabel.layer.shadowRadius = 2
        nameLabel.layer.shadowOpacity = 1
        nameLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
    }
    
    func configure(with participant: CombatParticipant, isSelected: Bool, isDisabled: Bool) {
        let animationDuration: TimeInterval = 0.2
        UIView.animate(withDuration: animationDuration) {
            self.cardBackground.layer.borderColor = UIColor.clear.cgColor
            self.cardBackground.layer.borderWidth = 0
        }
        avatarShadowContainer.layer.shadowOpacity = isSelected ? 0.8 : 0.8
        let imageName: String
        if participant.isPlayer {
            imageName = "player1"
        } else {
            imageName = "npc\(participant.id)"
        }
        let newImage = UIImage(named: imageName) ?? UIImage(named: "defaultMalePlaceholder")
        if avatarImageView.image != newImage {
            UIView.transition(with: avatarImageView, duration: animationDuration, options: .transitionCrossDissolve, animations: {
                self.avatarImageView.image = newImage
            }, completion: nil)
        }
        UIView.animate(withDuration: animationDuration) {
            self.avatarImageView.layer.borderWidth = isSelected ? 0 : 1
            self.avatarImageView.layer.borderColor = UIColor.black.cgColor
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        healthIndicator.opacity = 1.0
        healthIndicator.shadowOpacity = isSelected ? 0.8 : 0.0
        let center = CGPoint(x: healthIndicator.bounds.midX, y: healthIndicator.bounds.midY)
        let radius = healthIndicator.bounds.width / 2 - 2
        let startAngle = -CGFloat.pi / 2
        let percent = max(0, min(1, CGFloat(participant.health) / 100.0))
        let endAngle = startAngle + 2 * .pi * percent
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        healthIndicator.path = path.cgPath
        CATransaction.commit()
        professionIcon.image = UIImage(systemName: participant.profession.icon)
        professionIcon.tintColor = UIColor.systemGray
        let combatIconName = participant.isPlayer ? "shield.fill" : "sword"
        let combatIconImage = UIImage(systemName: combatIconName)
        combatIcon.image = combatIconImage
        combatIcon.tintColor = participant.isPlayer ? UIColor.systemBlue : UIColor.systemRed
        nameLabel.text = participant.name
        let healthValue = Int(participant.health)
        let healthText = "\(healthValue)%"
        if healthPercentageLabel.text != healthText {
            UIView.transition(with: healthPercentageLabel, duration: animationDuration, options: .transitionCrossDissolve, animations: {
                self.healthPercentageLabel.text = healthText
            }, completion: nil)
        }
        healthPercentageLabel.isHidden = false
        UIView.animate(withDuration: animationDuration) {
            if participant.health < 30 {
                self.healthPercentageLabel.textColor = UIColor.red
            } else if participant.health < 60 {
                self.healthPercentageLabel.textColor = UIColor.orange
            } else {
                self.healthPercentageLabel.textColor = UIColor.white
            }
        }
        UIView.animate(withDuration: animationDuration) {
            self.cardBackground.alpha = isDisabled ? 0.5 : 1.0
        }
        UIView.animate(withDuration: animationDuration) {
            self.selectionGlowLayer.shadowOpacity = isSelected ? 0.7 : 0
        }
    }
} 
