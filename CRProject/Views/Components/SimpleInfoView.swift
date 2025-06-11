//
//  SimpleInfoView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 06.06.2025.
//


import SwiftUI
import UIKit
import Combine

class SimpleInfoView: UIView {
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 6
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 2),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -2)
        ])
    }
    
    func configure(with items: [(icon: String, color: UIColor, text: String?)], font: UIFont? = nil) {
        // Clear existing views
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        for item in items {
            if !item.icon.isEmpty {
                let iconView = createGlowingIconView(icon: item.icon, color: item.color)
                stackView.addArrangedSubview(iconView)
            }
            
            if let text = item.text, !text.isEmpty {
                let label = createLabel(text: text, font: font)
                stackView.addArrangedSubview(label)
            }
        }
    }
    
    // Создание светящейся иконки точно как в TopWidgetView
    private func createGlowingIconView(icon: String, color: UIColor) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconSize: CGFloat = 28 // Точно как в TopWidgetView
        
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = iconSize / 2
        imageView.layer.borderWidth = 0
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowRadius = 2
        imageView.layer.shadowOpacity = 0.5
        imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        imageView.tintColor = color
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        
        // Create SF Symbol with proper configuration - точно как в TopWidgetView
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        let symbolImage = UIImage(systemName: icon, withConfiguration: iconConfig)
        imageView.image = symbolImage
        
        // Glow для иконки - добавляем как subview к иконке
        let glowView = UIImageView()
        glowView.contentMode = .scaleAspectFill
        glowView.alpha = 0.8
        glowView.isUserInteractionEnabled = false
        glowView.tag = 999
        glowView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(glowView)
        imageView.sendSubviewToBack(glowView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: iconSize),
            imageView.heightAnchor.constraint(equalToConstant: iconSize),
            
            containerView.widthAnchor.constraint(equalToConstant: iconSize),
            containerView.heightAnchor.constraint(equalToConstant: iconSize),
            
            // Glow view constraints
            glowView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            glowView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            glowView.widthAnchor.constraint(equalToConstant: iconSize + 12),
            glowView.heightAnchor.constraint(equalToConstant: iconSize + 12)
        ])
        
        // Generate glow image - точно как в TopWidgetView
        Self.getCachedGlowImage(size: CGSize(width: iconSize + 12, height: iconSize + 12), color: color) { glowImage in
            DispatchQueue.main.async {
                glowView.image = glowImage
            }
        }
        
        return containerView
    }
    
    private func createLabel(text: String, font: UIFont? = nil) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font ?? UIFont(name: "Optima", size: 12) ?? UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        return label
    }
    
    // MARK: - Glow Effect Methods (copied from TopWidgetView)
    
    // Static cache for glow images
    private static var glowImageCache: [String: UIImage] = [:]
    private static let cacheQueue = DispatchQueue(label: "glowImageCache", qos: .utility)
    
    // Кэшированная генерация radial alpha glow для иконок (теперь public static)
    static func getCachedGlowImage(size: CGSize, color: UIColor, completion: @escaping (UIImage?) -> Void) {
        // Создаем уникальный ключ на основе размера и компонентов цвета
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let cacheKey = String(format: "%.0fx%.0f_%.3f_%.3f_%.3f_%.3f", size.width, size.height, red, green, blue, alpha)
        
        // Проверяем кэш в основном потоке
        if let cachedImage = glowImageCache[cacheKey] {
            completion(cachedImage)
            return
        }
        
        // Генерируем изображение в фоновом потоке
        cacheQueue.async {
            let glowImage = makeRadialGlowImage(size: size, color: color)
            
            // Сохраняем в кэш
            if let image = glowImage {
                glowImageCache[cacheKey] = image
            }
            
            // Возвращаем результат
            completion(glowImage)
        }
    }
    
    // Оптимизированная генерация radial alpha glow для иконок (теперь public static)
    static func makeRadialGlowImage(size: CGSize, color: UIColor) -> UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        
        // Оптимизация: используем более эффективный способ создания градиента
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [color.withAlphaComponent(0.4).cgColor, color.withAlphaComponent(0.0).cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let radius = size.width * 0.5
        
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: .drawsAfterEndLocation)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.withRenderingMode(.alwaysOriginal)
    }
}
