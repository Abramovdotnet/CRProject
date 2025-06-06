//
//  NPCDetailWidget.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 06.06.2025.
//


import SwiftUI
import UIKit
import Combine

class NPCDetailWidget: UIView {
    private let stackView = UIStackView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    
    // Animation constants
    private let animationDuration: TimeInterval = 0.3
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Apply combat log style to the NPC detail widget (same as chat)
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        layer.cornerRadius = 12
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 0)
        clipsToBounds = false
        
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 2 // Reduced from 4
        stackView.distribution = .fill // Changed from default
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8), // Increased for styled container padding
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8), // Increased for styled container padding
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8), // Increased for styled container padding
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8) // Increased for styled container padding
        ])
    }
    
    func configure(with npc: NPC?) {
        // Clear existing views
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        guard let npc = npc else {
            // Show empty state
            let emptyLabel = createLabel(text: "No NPC selected")
            emptyLabel.textColor = UIColor.systemGray
            stackView.addArrangedSubview(emptyLabel)
            return
        }
        
        // 1. Avatar + Name row
        let nameRow = createNameRow(npc: npc)
        stackView.addArrangedSubview(nameRow)
        
        // 2. Age row
        let ageRow = createInfoRow(
            icon: "calendar",
            color: UIColor.systemBlue,
            text: "\(npc.age) years old"
        )
        stackView.addArrangedSubview(ageRow)
        
        // 3. Sex row
        let sexIcon = npc.sex == .female ? "figure.stand.dress" : "figure.wave"
        let sexRow = createInfoRow(
            icon: sexIcon,
            color: UIColor.systemYellow,
            text: npc.sex == .female ? "Female" : "Male"
        )
        stackView.addArrangedSubview(sexRow)
        
        // 4. Profession row
        let professionColor = convertSwiftUIColorToUIColor(npc.profession.color)
        let professionRow = createInfoRow(
            icon: npc.profession.icon,
            color: professionColor,
            text: npc.profession.rawValue.capitalized
        )
        stackView.addArrangedSubview(professionRow)
        
        // 5. Activity row
        let activityColor = convertSwiftUIColorToUIColor(npc.currentActivity.color)
        let activityRow = createInfoRow(
            icon: npc.currentActivity.icon,
            color: activityColor,
            text: npc.currentActivity.rawValue.capitalized
        )
        stackView.addArrangedSubview(activityRow)
        
        // 6. Morality row
        let moralityColor = convertSwiftUIColorToUIColor(npc.morality.color)
        let moralityRow = createInfoRow(
            icon: npc.morality.icon,
            color: moralityColor,
            text: npc.morality.rawValue.capitalized
        )
        stackView.addArrangedSubview(moralityRow)
        
        // 7. Motivation row
        let motivationColor = convertSwiftUIColorToUIColor(npc.motivation.color)
        let motivationRow = createInfoRow(
            icon: npc.motivation.icon,
            color: motivationColor,
            text: npc.motivation.rawValue.capitalized
        )
        stackView.addArrangedSubview(motivationRow)
    }
    
    private func createNameRow(npc: NPC) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Avatar
        let avatarImageView = UIImageView()
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 10 // Reduced from 12
        avatarImageView.backgroundColor = UIColor.systemGray4
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set avatar image based on NPC - используем правильную логику как в NPCCell
        let avatarImage: UIImage?
        if npc.isUnknown && !npc.isMob {
            avatarImage = UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")
        } else {
            avatarImage = UIImage(named: "npc\(npc.isMob ? npc.mobType.name : npc.id.description)") ?? 
                         UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")
        }
        avatarImageView.image = avatarImage
        
        // Name label
        let nameLabel = createLabel(text: npc.name)
        nameLabel.font = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12) // Изменено с 11 на 12
        
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 24), // Reduced from 30
            avatarImageView.heightAnchor.constraint(equalToConstant: 24), // Reduced from 30
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 6), // Reduced from 8
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            
            containerView.heightAnchor.constraint(equalToConstant: 28) // Reduced from 34
        ])
        
        return containerView
    }
    
    private func createInfoRow(icon: String, color: UIColor, text: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon with glow effect (smaller version)
        let iconView = createGlowingIconView(icon: icon, color: color, size: 16) // Reduced from 20
        
        // Text label
        let textLabel = createLabel(text: text)
        
        containerView.addSubview(iconView)
        containerView.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            textLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6), // Reduced from 8
            textLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 20) // Reduced from 24
        ])
        
        return containerView
    }
    
    // Создание светящейся иконки (меньшая версия для строк)
    private func createGlowingIconView(icon: String, color: UIColor, size: CGFloat) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = size / 2
        imageView.layer.borderWidth = 0
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowRadius = 1
        imageView.layer.shadowOpacity = 0.4
        imageView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        imageView.tintColor = color
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        
        // Create SF Symbol with smaller configuration
        let iconConfig = UIImage.SymbolConfiguration(pointSize: size * 0.4, weight: .medium)
        let symbolImage = UIImage(systemName: icon, withConfiguration: iconConfig)
        imageView.image = symbolImage
        
        // Glow для иконки (меньший размер)
        let glowView = UIImageView()
        glowView.contentMode = .scaleAspectFill
        glowView.alpha = 0.6
        glowView.isUserInteractionEnabled = false
        glowView.tag = 999
        glowView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(glowView)
        imageView.sendSubviewToBack(glowView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: size),
            imageView.heightAnchor.constraint(equalToConstant: size),
            
            containerView.widthAnchor.constraint(equalToConstant: size),
            containerView.heightAnchor.constraint(equalToConstant: size),
            
            // Glow view constraints
            glowView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            glowView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            glowView.widthAnchor.constraint(equalToConstant: size + 8),
            glowView.heightAnchor.constraint(equalToConstant: size + 8)
        ])
        
        // Generate glow image для меньшей иконки
        SimpleInfoView.getCachedGlowImage(size: CGSize(width: size + 8, height: size + 8), color: color) { glowImage in
            DispatchQueue.main.async {
                glowView.image = glowImage
            }
        }
        
        return containerView
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: "Optima", size: 12) ?? UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        return label
    }
    
    // Helper method to convert SwiftUI Color to UIColor
    private func convertSwiftUIColorToUIColor(_ color: Color) -> UIColor {
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
                return UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
            }
        }
        if color == .mint { 
            if #available(iOS 15.0, *) {
                return UIColor.systemMint
            } else {
                return UIColor(red: 0, green: 0.8, blue: 0.6, alpha: 1.0)
            }
        }
        return UIColor.white
    }
}