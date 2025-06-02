import UIKit
import SwiftUI

class PopUpOverlayViewController: UIViewController {
    private var containerView: UIView!
    private var backgroundView: UIView!
    private var contentStackView: UIStackView!
    private var imageView: UIImageView!
    private var titleLabel: UILabel!
    private var detailsLabel: UILabel!
    private var buttonsStackView: UIStackView!
    
    private var currentPopUp: PopUpData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        observePopUpState()
    }
    
    private func setupViews() {
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        
        // Background overlay
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        backgroundView.alpha = 0
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        
        // Container for popup content
        containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.92)
        containerView.layer.cornerRadius = 18
        containerView.layer.shadowColor = UIColor.white.withAlphaComponent(0.4).cgColor
        containerView.layer.shadowRadius = 32
        containerView.layer.shadowOffset = CGSize(width: 0, height: 12)
        containerView.layer.shadowOpacity = 1.0
        containerView.alpha = 0
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Content stack view
        contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentStackView)
        
        // Image view
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(imageView)
        
        // Title label
        titleLabel = UILabel()
        titleLabel.font = UIFont(name: "Optima-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .light)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(titleLabel)
        
        // Details label
        detailsLabel = UILabel()
        detailsLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        detailsLabel.textColor = .white
        detailsLabel.textAlignment = .center
        detailsLabel.numberOfLines = 0
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(detailsLabel)
        
        // Buttons stack view
        buttonsStackView = UIStackView()
        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 16
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(buttonsStackView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Background view
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container view
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            
            // Content stack view
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            // Image view
            imageView.widthAnchor.constraint(equalToConstant: 48),
            imageView.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func observePopUpState() {
        // Observe PopUpState changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popUpStateChanged),
            name: NSNotification.Name("PopUpStateChanged"),
            object: nil
        )
    }
    
    @objc private func popUpStateChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updatePopUp()
        }
    }
    
    private func updatePopUp() {
        let popUpState = PopUpState.shared
        
        if let topPopUp = popUpState.stack.last {
            if currentPopUp?.id != topPopUp.id {
                currentPopUp = topPopUp
                showPopUp(topPopUp)
            }
        } else {
            hidePopUp()
        }
    }
    
    private func showPopUp(_ popUp: PopUpData) {
        view.isUserInteractionEnabled = true
        
        // Update content
        titleLabel.text = popUp.title
        
        if let details = popUp.details {
            detailsLabel.text = details
            detailsLabel.isHidden = false
        } else {
            detailsLabel.isHidden = true
        }
        
        // Update image
        if let image = popUp.image {
            switch image {
            case .system(let name, let color):
                let systemImage = UIImage(systemName: name)?.withConfiguration(
                    UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
                )
                imageView.image = systemImage
                imageView.tintColor = convertSwiftUIColorToUIColor(color)
                imageView.layer.shadowColor = convertSwiftUIColorToUIColor(color).withAlphaComponent(0.7).cgColor
                imageView.layer.shadowRadius = 8
                imageView.layer.shadowOffset = CGSize(width: 0, height: 4)
                imageView.layer.shadowOpacity = 1.0
                imageView.isHidden = false
            case .asset(let name):
                imageView.image = UIImage(named: name)
                imageView.tintColor = nil
                imageView.layer.shadowColor = UIColor.white.withAlphaComponent(0.5).cgColor
                imageView.layer.shadowRadius = 8
                imageView.layer.shadowOffset = CGSize(width: 0, height: 4)
                imageView.layer.shadowOpacity = 1.0
                imageView.layer.cornerRadius = 12
                imageView.clipsToBounds = false
                imageView.isHidden = false
            }
        } else {
            imageView.isHidden = true
        }
        
        // Update buttons
        updateButtons(for: popUp)
        
        // Animate in
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.backgroundView.alpha = 1
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    private func updateButtons(for popUp: PopUpData) {
        // Clear existing buttons
        buttonsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let popUpState = PopUpState.shared
        
        if popUpState.stack.count > 1 {
            let nextButton = createButton(title: "Next") { [weak self] in
                popUpState.next()
                self?.updatePopUp()
            }
            buttonsStackView.addArrangedSubview(nextButton)
        } else {
            let closeButton = createButton(title: "Close") { [weak self] in
                popUpState.closeTop()
                self?.updatePopUp()
            }
            buttonsStackView.addArrangedSubview(closeButton)
        }
    }
    
    private func createButton(title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.titleLabel?.font = UIFont(name: "Optima-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        
        return button
    }
    
    private func hidePopUp() {
        currentPopUp = nil
        view.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.backgroundView.alpha = 0
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: -20)
        }
    }
    
    private func convertSwiftUIColorToUIColor(_ color: SwiftUI.Color) -> UIColor {
        // Basic color conversion - можно расширить при необходимости
        switch color {
        case .red: return .systemRed
        case .blue: return .systemBlue
        case .green: return .systemGreen
        case .purple: return .systemPurple
        case .orange: return .systemOrange
        case .yellow: return .systemYellow
        case .pink: return .systemPink
        default: return .white
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 