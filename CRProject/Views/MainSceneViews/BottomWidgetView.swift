import SwiftUI
import UIKit
import Combine

// MARK: - Custom Simple Info View for Bottom Widget
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
    
    func configure(with items: [(icon: String, color: UIColor, text: String?)]) {
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
                let label = createLabel(text: text)
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

// MARK: - UIKit Implementation
class BottomWidgetUIViewController: UIViewController {
    // Main properties
    private var viewModel: MainSceneViewModel
    private var awarenessService = VampireNatureRevealService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Main container stack
    private let mainStackView = UIStackView()
    
    // Only location and victim info views (removed awareness info)
    private let locationInfoView = SimpleInfoView()
    private let victimInfoView = SimpleInfoView()
    // Money info view (новый элемент для правого угла)
    private let moneyInfoView = SimpleInfoView()
    
    // Animation constants
    private let animationDuration: TimeInterval = 0.3
    
    init(viewModel: MainSceneViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        updateAllWidgets()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Setup main stack view
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .horizontal
        mainStackView.alignment = .center
        mainStackView.spacing = 20  // Spacing для 3 элементов
        mainStackView.distribution = .fillEqually
        view.addSubview(mainStackView)
        
        // Add location and victim info views to stack
        mainStackView.addArrangedSubview(locationInfoView)
        mainStackView.addArrangedSubview(victimInfoView)
        // moneyInfoView не добавляем в stackView
        
        // Setup layout constraints
        NSLayoutConstraint.activate([
            mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
        // Добавляем moneyInfoView отдельно и закрепляем справа
        moneyInfoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(moneyInfoView)
        NSLayoutConstraint.activate([
            moneyInfoView.centerYAnchor.constraint(equalTo: mainStackView.centerYAnchor),
            moneyInfoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            moneyInfoView.heightAnchor.constraint(equalTo: mainStackView.heightAnchor),
            moneyInfoView.widthAnchor.constraint(lessThanOrEqualToConstant: 120)
        ])
        
        // Initially hide victim info view
        victimInfoView.alpha = 0.3
    }
    
    private func setupBindings() {
        // Subscribe to scene changes
        viewModel.$currentScene
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLocationInfo()
            }
            .store(in: &cancellables)
        
        // Subscribe to NPCs array changes
        viewModel.$npcs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLocationInfo()
            }
            .store(in: &cancellables)
        
        // Subscribe to desired victim changes
        if let player = viewModel.gameStateService.player {
            player.desiredVictim.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.updateDesiredVictimInfo()
                }
                .store(in: &cancellables)
        }
        
        // Subscribe to money changes
        viewModel.$playerCoinsValue
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMoneyInfo()
            }
            .store(in: &cancellables)
    }
    
    private func updateAllWidgets() {
        updateLocationInfo()
        updateDesiredVictimInfo()
        updateMoneyInfo()
    }
    
    private func updateLocationInfo() {
        guard let scene = viewModel.currentScene else {
            locationInfoView.configure(with: [
                (icon: "location", color: UIColor.systemGray, text: "Unknown")
            ])
            return
        }
        
        let npcCount = viewModel.npcs.count
        let locationName = scene.name
        let locationIcon = scene.sceneType.iconName
        
        // Get location color from SceneTypeColorProvider
        let locationColor: UIColor
        if let sceneType = viewModel.currentScene?.sceneType {
            locationColor = SceneTypeColorProvider.color(for: sceneType)
        } else {
            locationColor = UIColor.systemGray
        }
        
        locationInfoView.configure(with: [
            (icon: locationIcon, color: locationColor, text: locationName),
            (icon: "person.3.fill", color: UIColor.systemRed, text: "\(npcCount)")
        ])
        
        animateContainerVisibility(locationInfoView, show: true)
    }
    
    private func updateDesiredVictimInfo() {
        guard let player = viewModel.gameStateService.player else {
            victimInfoView.configure(with: [
                (icon: "target", color: UIColor.systemRed, text: "No criteria")
            ])
            animateContainerVisibility(victimInfoView, show: false)
            return
        }
        
        let desiredVictim = player.desiredVictim
        
        // Check if any criteria are set
        let hasCriteria = desiredVictim.desiredSex != nil || 
                         desiredVictim.desiredAgeRange != nil ||
                         desiredVictim.desiredProfession != nil ||
                         desiredVictim.desiredMorality != nil
        
        if hasCriteria {
            var items: [(icon: String, color: UIColor, text: String?)] = [
                (icon: "arrow.up.heart.fill", color: UIColor.systemRed, text: "Desires:")
            ]
            
            if let desiredSex = desiredVictim.desiredSex {
                let sexIcon = desiredSex == .female ? "figure.stand.dress" : "figure.wave"
                items.append((icon: sexIcon, color: UIColor.systemYellow, text: nil))
            }
            
            if let desiredProfession = desiredVictim.desiredProfession {
                let professionColor = convertSwiftUIColorToUIColor(desiredProfession.color)
                items.append((icon: desiredProfession.icon, color: professionColor, text: nil))
            }
            
            if let desiredMorality = desiredVictim.desiredMorality {
                let moralityColor = convertSwiftUIColorToUIColor(desiredMorality.color)
                items.append((icon: desiredMorality.icon, color: moralityColor, text: nil))
            }
            
            if let desiredAgeRange = desiredVictim.desiredAgeRange {
                items.append((icon: "", color: UIColor.systemYellow, text: "Age " + desiredAgeRange.rangeDescription))
            }
            
            victimInfoView.configure(with: items)
            animateContainerVisibility(victimInfoView, show: true)
        } else {
            victimInfoView.configure(with: [
                (icon: "target", color: UIColor.systemRed, text: "No criteria")
            ])
            animateContainerVisibility(victimInfoView, show: false)
        }
    }
    
    private func updateMoneyInfo() {
        let coinsValue = viewModel.playerCoinsValue
        
        moneyInfoView.configure(with: [
            (icon: "cedisign", color: UIColor.systemGreen, text: "\(coinsValue)")
        ])
        
        animateContainerVisibility(moneyInfoView, show: true)
    }
    
    private func animateContainerVisibility(_ container: UIView, show: Bool) {
        let targetAlpha: CGFloat = show ? 1.0 : 0.3
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut], animations: {
            container.alpha = targetAlpha
        }, completion: nil)
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

// MARK: - SwiftUI Wrapper
struct BottomWidgetViewRepresentable: UIViewControllerRepresentable {
    let viewModel: MainSceneViewModel
    
    func makeUIViewController(context: Context) -> BottomWidgetUIViewController {
        return BottomWidgetUIViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: BottomWidgetUIViewController, context: Context) {
        // Updates handled by Combine subscriptions
    }
}

// MARK: - SwiftUI View
struct BottomWidgetView: View {
    let viewModel: MainSceneViewModel
    
    var body: some View {
        BottomWidgetViewRepresentable(viewModel: viewModel)
    }
} 
