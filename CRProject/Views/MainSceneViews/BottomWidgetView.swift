import SwiftUI
import UIKit
import Combine

// MARK: - Custom Simple Info View for Bottom Widget


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
        
        // Возвращаем victimInfoView в stackView
        mainStackView.addArrangedSubview(victimInfoView)
        
        // Setup layout constraints
        NSLayoutConstraint.activate([
            mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
        
        // Добавляем moneyInfoView отдельно и закрепляем справа
        moneyInfoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(moneyInfoView)
        NSLayoutConstraint.activate([
            moneyInfoView.centerYAnchor.constraint(equalTo: mainStackView.centerYAnchor),
            moneyInfoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            moneyInfoView.widthAnchor.constraint(lessThanOrEqualToConstant: 120)
        ])
    }
    
    private func setupBindings() {
        // Подписка на изменения желаемой жертвы
        if let player = viewModel.gameStateService.player {
            player.desiredVictim.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.updateDesiredVictimInfo()
                }
                .store(in: &cancellables)
        }
        // Подписка на деньги
        viewModel.$playerCoinsValue
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMoneyInfo()
            }
            .store(in: &cancellables)
    }
    
    private func updateAllWidgets() {
        updateDesiredVictimInfo()
        updateMoneyInfo()
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
