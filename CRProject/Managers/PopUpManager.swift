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

// MARK: - Confirmation Dialog

class ConfirmationDialogView: UIView {
    private let titleLabel = UILabel()
    private var yesButton = ActionButtonSmallView()
    private var noButton = ActionButtonSmallView()
    private let overlayView = UIView()
    
    var onResult: ((Bool) -> Void)?
    
    init(title: String, yesText: String, noText: String) {
        super.init(frame: .zero)
        setupUI(title: title, yesText: yesText, noText: noText)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(title: String, yesText: String, noText: String) {
        // Overlay для затемнения фона
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        
        // Основной контейнер диалога
        let dialogContainer = UIView()
        dialogContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.95)
        dialogContainer.layer.cornerRadius = 16
        dialogContainer.layer.borderWidth = 2
        dialogContainer.layer.borderColor = UIColor.black.cgColor
        dialogContainer.layer.shadowColor = UIColor.black.cgColor
        dialogContainer.layer.shadowOpacity = 0.8
        dialogContainer.layer.shadowRadius = 12
        dialogContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        dialogContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Заголовок
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont(name: "Optima-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем тень к тексту
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.7
        titleLabel.layer.shadowRadius = 2
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        // Кнопки
        yesButton = ActionButtonSmallView(title: yesText, icon: "checkmark.circle.fill", color: .systemGreen) { [weak self] in
            self?.handleResult(true)
        }
        
        noButton = ActionButtonSmallView(title: noText, icon: "xmark.circle.fill", color: .systemRed) { [weak self] in
            self?.handleResult(false)
        }
        
        // Стек для кнопок
        let buttonStack = UIStackView(arrangedSubviews: [yesButton, noButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем элементы
        addSubview(overlayView)
        addSubview(dialogContainer)
        dialogContainer.addSubview(titleLabel)
        dialogContainer.addSubview(buttonStack)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Overlay на весь экран
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Диалог по центру
            dialogContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            dialogContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            dialogContainer.widthAnchor.constraint(equalToConstant: 350),
            dialogContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Заголовок
            titleLabel.topAnchor.constraint(equalTo: dialogContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: dialogContainer.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: dialogContainer.trailingAnchor, constant: -16),
            
            // Кнопки
            buttonStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            buttonStack.leadingAnchor.constraint(equalTo: dialogContainer.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: dialogContainer.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: dialogContainer.bottomAnchor, constant: -16)
        ])
        
        // Начальное состояние для анимации
        alpha = 0
        dialogContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
    }
    
    private func handleResult(_ result: Bool) {
        onResult?(result)
        dismiss()
    }
    
    func show(in window: UIWindow) {
        window.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: window.topAnchor),
            leadingAnchor.constraint(equalTo: window.leadingAnchor),
            trailingAnchor.constraint(equalTo: window.trailingAnchor),
            bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
        
        // Анимация появления
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseOut], animations: {
            self.alpha = 1
            if let dialogContainer = self.subviews.last {
                dialogContainer.transform = CGAffineTransform.identity
            }
        }, completion: nil)
    }
    
    private func dismiss() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            if let dialogContainer = self.subviews.last {
                dialogContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

class PopUpBannerView: UIView {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    var onClose: (() -> Void)?
    private var autoCloseTimer: Timer?
    
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
        
        // Запускаем таймер автоматического закрытия через 4 секунды
        startAutoCloseTimer()
    }
    
    private func startAutoCloseTimer() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            self?.autoClose()
        }
    }
    
    private func autoClose() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        
        // Принудительно выполняем автоматическое закрытие в главном потоке
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onClose?()
            self.forceAnimatedDismiss()
        }
    }
    
    private func forceAnimatedDismiss() {
        // Принудительная анимация закрытия независимо от контекста
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        
        // Сначала проверяем, что view еще в иерархии
        guard self.superview != nil else {
            self.removeFromSuperview()
            return
        }
        
        // Принудительно активируем слой для анимации
        self.layer.removeAllAnimations()
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState], animations: {
            self.alpha = 0
        }) { [weak self] completed in
            // Гарантируем удаление из иерархии независимо от результата анимации
            DispatchQueue.main.async {
                self?.removeFromSuperview()
            }
        }
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
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: [.curveEaseOut], animations: {
            self.alpha = 1
        })
    }
    
    @objc private func closeTapped() {
        // Отменяем автоматический таймер при ручном закрытии
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        onClose?()
        dismiss()
    }
    
    func dismiss() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        
        // Используем ту же надежную логику что и для автоматического закрытия
        DispatchQueue.main.async { [weak self] in
            self?.forceAnimatedDismiss()
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
    
    // MARK: - Confirmation Dialog
    
    func showConfirmation(title: String, yesText: String, noText: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                // Try multiple approaches to find the right window
                var targetWindow: UIWindow?
                
                // First try: Get the key window from connected scenes
                if let windowScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }) {
                    targetWindow = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
                }
                
                // Second try: Use the first available window
                if targetWindow == nil {
                    targetWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first
                }
                
                guard let window = targetWindow else {
                    continuation.resume(returning: false)
                    return
                }
                
                let dialog = ConfirmationDialogView(title: title, yesText: yesText, noText: noText)
                dialog.onResult = { result in
                    continuation.resume(returning: result)
                }
                dialog.show(in: window)
            }
        }
    }
    
    private func showBanner(title: String, description: String, icon: UIImage?) {
        let banner = PopUpBannerView(title: title, description: description, icon: icon)
        banner.onClose = { [weak self] in
            guard let self = self else { return }
            self.currentBanner = nil
            self.showNextIfNeeded()
        }
        self.currentBanner = banner

        // Try multiple approaches to find the right window/view to add the banner to
        DispatchQueue.main.async {
            // First try: Get the key window from connected scenes
            if let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {
                
                banner.show(in: window, offsetY: 0)
                return
            }
            
            // Second try: Use the first available window
            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first {
                banner.show(in: window, offsetY: 0)
                return
            }
            
            // Third try: Add to root view controller
            if let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
               let rootVC = windowScene.windows.first?.rootViewController {
                
                rootVC.view.addSubview(banner)
                banner.translatesAutoresizingMaskIntoConstraints = false
                let topInset = rootVC.view.safeAreaInsets.top
                let rightInset = rootVC.view.safeAreaInsets.right
                
                NSLayoutConstraint.activate([
                    banner.topAnchor.constraint(equalTo: rootVC.view.safeAreaLayoutGuide.topAnchor, constant: 20),
                    banner.trailingAnchor.constraint(equalTo: rootVC.view.trailingAnchor, constant: -16 - rightInset),
                    banner.widthAnchor.constraint(equalToConstant: 320)
                ])
                
                rootVC.view.layoutIfNeeded()
                
                // Используем ту же анимацию что и в методе show
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: [.curveEaseOut], animations: {
                    banner.alpha = 1
                })
            }
        }
    }
    
    private func showNextIfNeeded() {
        if !queue.isEmpty {
            let (title, description, icon) = queue.removeFirst()
            showBanner(title: title, description: description, icon: icon)
        }
    }
} 
