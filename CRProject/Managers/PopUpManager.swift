import SwiftUI
import UIKit

class PopUpManager: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var message: String = ""
    @Published var icon: String? = nil

    func show(message: String, icon: String? = nil, duration: Double = 2.0) {
        self.message = message
        self.icon = icon
        withAnimation {
            self.isPresented = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                self.isPresented = false
            }
        }
    }
}

class PopUpBannerView: UIView {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    var onClose: (() -> Void)?
    
    init(title: String, description: String, icon: UIImage? = nil) {
        super.init(frame: .zero)
        setupUI(title: title, description: description, icon: icon)
        layer.cornerRadius = 16
        layer.masksToBounds = true
        backgroundColor = UIColor(white: 0.13, alpha: 0.96)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        alpha = 0
    }
    
    private func setupUI(title: String, description: String, icon: UIImage?) {
        iconImageView.image = icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        iconImageView.isHidden = (icon == nil)
        
        titleLabel.text = title
        titleLabel.textColor = .white
        if let optima = UIFont(name: "Optima-Regular", size: 15) {
            titleLabel.font = UIFont(descriptor: optima.fontDescriptor.withSymbolicTraits(.traitBold) ?? optima.fontDescriptor, size: 15)
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        }
        titleLabel.numberOfLines = 1
        
        descriptionLabel.text = description
        descriptionLabel.textColor = .white
        if let optima = UIFont(name: "Optima-Regular", size: 13) {
            descriptionLabel.font = optima
        } else {
            descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        }
        descriptionLabel.numberOfLines = 2
        
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconImageView)
        addSubview(textStack)
        addSubview(closeButton)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: icon == nil ? 0 : 22),
            iconImageView.heightAnchor.constraint(equalToConstant: icon == nil ? 0 : 22),

            textStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),

            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 22),
            closeButton.heightAnchor.constraint(equalToConstant: 22),

            widthAnchor.constraint(equalToConstant: 320),
            heightAnchor.constraint(lessThanOrEqualToConstant: 80)
        ])
        if icon == nil {
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14).isActive = true
        } else {
            textStack.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8).isActive = true
        }
    }
    
    func show(in window: UIWindow, offsetY: CGFloat) {
        window.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        let topInset = window.safeAreaInsets.top
        let rightInset = window.safeAreaInsets.right
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: window.topAnchor, constant: 20 + topInset + offsetY),
            trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -16 - rightInset),
            widthAnchor.constraint(equalToConstant: 320)
        ])
        window.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }
    
    @objc private func closeTapped() {
        onClose?()
        dismiss()
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UIKitPopUpManager {
    static let shared = UIKitPopUpManager()
    private init() {}
    private var queue: [(String, String, UIImage?)] = []
    private var currentBanner: PopUpBannerView?
    private var bannerWindow: UIWindow?
    
    func show(title: String, description: String, icon: UIImage? = nil) {
        DispatchQueue.main.async {
            if self.currentBanner != nil {
                self.queue.append((title, description, icon))
            } else {
                self.showBanner(title: title, description: description, icon: icon)
            }
        }
    }
    
    private func showBanner(title: String, description: String, icon: UIImage?) {
        let banner = PopUpBannerView(title: title, description: description, icon: icon)
        banner.onClose = { [weak self, weak banner] in
            guard let self = self, let banner = banner else { return }
            self.currentBanner = nil
            banner.dismiss()
            self.showNextIfNeeded()
        }
        self.currentBanner = banner

        // --- Альтернативный способ: добавление в rootViewController ---
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
            let rootVC = windowScene.windows.first?.rootViewController else { return }

        rootVC.view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = true
        let topInset = rootVC.view.safeAreaInsets.top
        let rightInset = rootVC.view.safeAreaInsets.right
        banner.frame = CGRect(
            x: rootVC.view.bounds.width - 320 - 16 - rightInset,
            y: 20 + topInset,
            width: 320,
            height: 80
        )
        banner.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        UIView.animate(withDuration: 0.25) {
            banner.alpha = 1
        }
    }
    
    private func showNextIfNeeded() {
        if !queue.isEmpty {
            let (title, description, icon) = queue.removeFirst()
            showBanner(title: title, description: description, icon: icon)
        }
    }
} 
