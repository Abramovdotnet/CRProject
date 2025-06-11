import UIKit
import SwiftUI
import Combine

// MARK: - UIKit Implementation
class EndGameViewController: UIViewController {
    private let statistics: StatisticsService = DependencyManager.shared.resolve()
    private var dismissHandler: (() -> Void)?
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let statsStackView = UIStackView()
    private let exitButton = UIButton(type: .system)
    
    init(dismissHandler: @escaping () -> Void) {
        self.dismissHandler = dismissHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func setupUI() {
        // Setup background - extend to edges
        view.backgroundColor = .black
        
        // Ensure the view extends under the safe area
        scrollView.backgroundColor = .black
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Setup content stack view
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        // Setup title
        titleLabel.text = "Game Over"
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .red
        contentStackView.addArrangedSubview(titleLabel)
        
        // Setup message
        messageLabel.text = "You discovered yourself. People caught you, burned, decapitated and buried into the ground."
        messageLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        messageLabel.textColor = .red
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(messageLabel)
        
        // Setup stats stack view
        statsStackView.axis = .vertical
        statsStackView.spacing = 15
        statsStackView.alignment = .center
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(statsStackView)
        
        // Add stat rows
        addStatRow(title: "Days Survived", value: statistics.daysSurvived)
        addStatRow(title: "Feedings", value: statistics.feedings)
        addStatRow(title: "Victims Drained", value: statistics.victimsDrained)
        addStatRow(title: "People Killed", value: statistics.peopleKilled)
        addStatRow(title: "Investigations", value: statistics.investigations)
        addStatRow(title: "People Seducted", value: statistics.peopleSeducted)
        addStatRow(title: "People Dominated", value: statistics.peopleDominated)
        addStatRow(title: "Barters Completed", value: statistics.bartersCompleted)
        addStatRow(title: "Bribes", value: statistics.bribes)
        addStatRow(title: "Smithing Recipes Unlocked", value: statistics.smithingRecipesUnlocked)
        addStatRow(title: "Alchemy Recipes Unlocked", value: statistics.alchemyRecipesUnlocked)
        addStatRow(title: "Properties Bought", value: statistics.propertiesBought)
        addStatRow(title: "Food Consumed", value: statistics.foodConsumed)
        addStatRow(title: "Friendships Created", value: statistics.friendshipsCreated)
        addStatRow(title: "Allies Created", value: statistics.alliesCreated)
        addStatRow(title: "Nights Spent With Someone", value: statistics.nightSpentsWithSomeone)
        addStatRow(title: "Disappearances", value: statistics.disappearances)
        
        // Setup exit button
        exitButton.setTitle("Exit", for: .normal)
        exitButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        exitButton.backgroundColor = .red
        exitButton.setTitleColor(.white, for: .normal)
        exitButton.layer.cornerRadius = 8
        exitButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        exitButton.addTarget(self, action: #selector(exitButtonTapped), for: .touchUpInside)
        contentStackView.addArrangedSubview(exitButton)
        
        // Add padding at the bottom to ensure scrolling works properly
        let bottomPadding = UIView()
        bottomPadding.heightAnchor.constraint(equalToConstant: 20).isActive = true
        contentStackView.addArrangedSubview(bottomPadding)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Scroll view fills the entire view - not just safe area
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Content stack view stretches to the width of the scroll view
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40), // Add more padding for status bar area
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Stats stack view should have a fixed width
            statsStackView.widthAnchor.constraint(equalToConstant: 280)
        ])
    }
    
    private func addStatRow(title: String, value: Int) {
        let rowView = UIView()
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .red
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        rowView.addSubview(titleLabel)
        
        let valueLabel = UILabel()
        valueLabel.text = "\(value)"
        valueLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        valueLabel.textColor = .red
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        rowView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            rowView.heightAnchor.constraint(greaterThanOrEqualToConstant: 30),
            rowView.widthAnchor.constraint(equalToConstant: 280),
            
            titleLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor)
        ])
        
        statsStackView.addArrangedSubview(rowView)
    }
    
    @objc private func exitButtonTapped() {
        dismissHandler?()
    }
}

// MARK: - SwiftUI Wrapper
struct EndGameViewUIKit: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> EndGameViewController {
        return EndGameViewController(dismissHandler: {
            // Reset to main scene
            let mainSceneView = MainSceneView(viewModel: MainSceneViewModel())
            dismiss()
        })
    }
    
    func updateUIViewController(_ uiViewController: EndGameViewController, context: Context) {
        // Updates if needed
    }
}

// MARK: - SwiftUI Preview
struct EndGameViewUIKit_Previews: PreviewProvider {
    static var previews: some View {
        EndGameViewUIKit()
            .edgesIgnoringSafeArea(.all) // Add this for the preview
    }
} 