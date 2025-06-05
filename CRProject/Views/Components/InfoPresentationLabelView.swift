import UIKit
import SwiftUI

enum InfoPresentationItem {
    case symbol(String) // SF Symbol name
    case image(UIImage) // 30x30 image with corner radius 12
    case text(String)   // Text with Optima-Regular 14
    case professionIcon(String, UIColor) // SF Symbol with profession color and glow
    case activityIcon(String, UIColor) // SF Symbol with activity color and glow
}

class InfoPresentationLabelView: UIView {
    private let stackView = UIStackView()
    private var textColor: UIColor = .white
    
    // Static cache for glow images to avoid regenerating them
    private static var glowImageCache: [String: UIImage] = [:]
    private static let cacheQueue = DispatchQueue(label: "glowImageCache", qos: .utility)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Apply the same styling as chat window
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        layer.cornerRadius = 12
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 0)
        clipsToBounds = false
        
        // Setup stack view
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        // Setup constraints with padding like chat
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with items: [InfoPresentationItem], textColor: UIColor = .white) {
        self.textColor = textColor
        
        // Clear existing views
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        // Add items to stack view
        for item in items {
            let view = createView(for: item)
            stackView.addArrangedSubview(view)
        }
    }
    
    private func createView(for item: InfoPresentationItem) -> UIView {
        switch item {
        case .symbol(let symbolName):
            return createSymbolView(symbolName: symbolName)
        case .image(let image):
            return createImageView(image: image)
        case .text(let text):
            return createTextLabel(text: text)
        case .professionIcon(let symbolName, let color):
            return createGlowingIconView(symbolName: symbolName, color: color)
        case .activityIcon(let symbolName, let color):
            return createGlowingIconView(symbolName: symbolName, color: color)
        }
    }
    
    private func createGlowingIconView(symbolName: String, color: UIColor) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconSize: CGFloat = 28 // Точно как в NPCCharacterCell
        
        // Create main icon view - точно как в NPCCharacterCell
        let iconView = UIImageView()
        iconView.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
        iconView.contentMode = .center // Точно как в NPCCharacterCell
        iconView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = iconSize / 2
        iconView.layer.borderWidth = 0 // Убираем белую обводку
        iconView.layer.shadowColor = UIColor.black.cgColor
        iconView.layer.shadowRadius = 2 // Уменьшаем с 3 до 2
        iconView.layer.shadowOpacity = 0.5 // Уменьшаем с 0.8 до 0.5
        iconView.layer.shadowOffset = CGSize(width: 0, height: 1)
        iconView.alpha = 1.0
        iconView.tintColor = color
        containerView.addSubview(iconView)
        
        // Create SF Symbol with proper configuration - точно как в NPCCharacterCell
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 10) // Точно как в NPCCharacterCell
        let symbolImage = UIImage(systemName: symbolName, withConfiguration: iconConfig)
        iconView.image = symbolImage
        
        // Glow для иконки - добавляем как subview к иконке (без constraints) - точно как в NPCCharacterCell
        let glowView = UIImageView()
        glowView.contentMode = .scaleAspectFill
        glowView.alpha = 0.8
        glowView.isUserInteractionEnabled = false
        iconView.addSubview(glowView)
        iconView.sendSubviewToBack(glowView)
        
        // Устанавливаем размеры glow views напрямую (без constraints) - точно как в NPCCharacterCell
        let glowSize = iconSize + 12
        glowView.frame = CGRect(x: -6, y: -6, width: glowSize, height: glowSize)
        
        // Setup constraints только для container
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalToConstant: iconSize),
            containerView.heightAnchor.constraint(equalToConstant: iconSize)
        ])
        
        // Generate glow image asynchronously - точно как в NPCCharacterCell
        Self.getCachedGlowImage(size: CGSize(width: iconSize + 12, height: iconSize + 12), color: color) { glowImage in
            DispatchQueue.main.async {
                glowView.image = glowImage
            }
        }
        
        return containerView
    }
    
    private func createSymbolView(symbolName: String) -> UIView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = textColor
        
        // Create SF Symbol with proper configuration
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium, scale: .medium)
        let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfig)
        imageView.image = symbolImage
        
        // Set size constraints
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return imageView
    }
    
    private func createImageView(image: UIImage) -> UIView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set size to 30x30 as specified
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return imageView
    }
    
    private func createTextLabel(text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: "Optima-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10)
        label.textColor = textColor
        label.numberOfLines = 1
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        
        return label
    }
    
    // Convenience method for common use case: image + text
    func configureWithImageAndText(image: UIImage?, text: String, textColor: UIColor = .white) {
        var items: [InfoPresentationItem] = []
        
        if let image = image {
            items.append(.image(image))
        }
        
        items.append(.text(text))
        
        configure(with: items, textColor: textColor)
    }
    
    // Convenience method for symbol + text
    func configureWithSymbolAndText(symbolName: String, text: String, textColor: UIColor = .white) {
        let items: [InfoPresentationItem] = [
            .symbol(symbolName),
            .text(text)
        ]
        
        configure(with: items, textColor: textColor)
    }
    
    // New convenience method for NPC with profession and activity icons
    func configureWithNPCInfo(npc: NPC, textColor: UIColor = .white) {
        let professionColor = convertSwiftUIColorToUIColor(npc.profession.color)
        let activityColor = convertSwiftUIColorToUIColor(npc.currentActivity.color)
        
        let items: [InfoPresentationItem] = [
            .professionIcon(npc.profession.icon, professionColor),
            .text(npc.name),
            .activityIcon(npc.currentActivity.icon, activityColor)
        ]
        
        configure(with: items, textColor: textColor)
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
    
    // MARK: - Glow Effect Methods (copied from NPCCharacterCell)
    
    // Кэшированная генерация radial alpha glow для иконок
    private static func getCachedGlowImage(size: CGSize, color: UIColor, completion: @escaping (UIImage?) -> Void) {
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
    
    // Оптимизированная генерация radial alpha glow для иконок
    private static func makeRadialGlowImage(size: CGSize, color: UIColor) -> UIImage? {
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
    
    // Method to clear cache if needed (for memory management)
    static func clearGlowImageCache() {
        cacheQueue.async {
            glowImageCache.removeAll()
        }
    }
} 