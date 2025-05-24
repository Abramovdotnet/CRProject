import UIKit
import SwiftUI

class TimeBarView: UIView {
    private let hoursRange = 6
    private let fadeWidth: CGFloat = 40
    private let markerHeight: CGFloat = 16
    private let markerWidth: CGFloat = 3
    private let barHeight: CGFloat = 20
    private let hourLabelOffset: CGFloat = 20
    private let font = UIFont.systemFont(ofSize: 11, weight: .regular)
    private let fontCurrent = UIFont.systemFont(ofSize: 15, weight: .bold)
    private let topMargin: CGFloat = 60

    private var virtualHour: Double = 0 // для анимации и бесконечной шкалы
    private var animationStart: Double = 0
    private var animationEnd: Double = 0
    private var animationStartTime: CFTimeInterval = 0
    private var animationDuration: CFTimeInterval = 0.35
    private var displayLink: CADisplayLink?
    var barAlpha: CGFloat = 0 // для анимации появления
    private var appearStartTime: CFTimeInterval = 0
    private var appearDuration: CFTimeInterval = 0.5
    private var appearDisplayLink: CADisplayLink?
    private var cachedIconXs: [CGFloat] = []

    enum IconType { case sun, moon }
    struct IconAnim {
        var type: IconType
        var alpha: CGFloat
        var targetType: IconType
        var targetAlpha: CGFloat
        var animating: Bool
        var animStart: CFTimeInterval
    }
    private var iconAnims: [IconAnim] = [
        IconAnim(type: .sun, alpha: 1, targetType: .sun, targetAlpha: 1, animating: false, animStart: 0), // left
        IconAnim(type: .sun, alpha: 1, targetType: .sun, targetAlpha: 1, animating: false, animStart: 0), // center
        IconAnim(type: .sun, alpha: 1, targetType: .sun, targetAlpha: 1, animating: false, animStart: 0)  // right
    ]
    private var iconAnimDisplayLink: CADisplayLink?
    private let iconAnimDuration: CFTimeInterval = 0.35

    var currentHour: Int = 0 {
        didSet {
            animateToHour(currentHour)
            updateIconTypes(animated: true)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        virtualHour = Double(currentHour)
        updateIconTypes(animated: false)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func animateToHour(_ hour: Int) {
        print("[TimeBar] animateToHour: from \(virtualHour) to \(hour)")
        displayLink?.invalidate()
        animationStart = virtualHour
        let target = animationStart < Double(hour) ? Double(hour) : Double(hour) + 24
        animationEnd = target
        animationStartTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(handleAnimationStep))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func handleAnimationStep() {
        print("[TimeBar] handleAnimationStep: virtualHour = \(virtualHour), animationStart = \(animationStart), animationEnd = \(animationEnd)")
        let elapsed = CACurrentMediaTime() - animationStartTime
        let progress = min(1, elapsed / animationDuration)
        let eased = 0.5 - 0.5 * cos(.pi * progress) // easeInOut
        virtualHour = animationStart + (animationEnd - animationStart) * eased
        setNeedsDisplay()
        if progress >= 1 {
            virtualHour = animationEnd.truncatingRemainder(dividingBy: 24)
            displayLink?.invalidate()
            displayLink = nil
            setNeedsDisplay()
        }
    }

    func animateAppear() {
        barAlpha = 0
        setNeedsDisplay()
        appearDisplayLink?.invalidate()
        appearStartTime = CACurrentMediaTime()
        appearDisplayLink = CADisplayLink(target: self, selector: #selector(handleAppearStep))
        appearDisplayLink?.add(to: .main, forMode: .common)
    }

    @objc private func handleAppearStep() {
        let elapsed = CACurrentMediaTime() - appearStartTime
        let progress = min(1, elapsed / appearDuration)
        let eased = 0.5 - 0.5 * cos(.pi * progress)
        barAlpha = CGFloat(eased)
        setNeedsDisplay()
        if progress >= 1 {
            barAlpha = 1
            appearDisplayLink?.invalidate()
            appearDisplayLink = nil
            setNeedsDisplay()
        }
    }

    private func updateIconTypes(animated: Bool) {
        let center = Int(floor(virtualHour))
        let hours = (center - hoursRange ... center + hoursRange).map { ($0 + 24) % 24 }
        let positions = [0, hoursRange, hours.count-1]
        for (i, pos) in positions.enumerated() {
            let hour = hours[pos]
            let newType: IconType = (hour >= 20 || hour < 6) ? .moon : .sun
            if iconAnims[i].type != newType {
                iconAnims[i].targetType = newType
                iconAnims[i].targetAlpha = 1
                iconAnims[i].animating = true
                iconAnims[i].animStart = CACurrentMediaTime()
                iconAnimDisplayLink?.invalidate()
                iconAnimDisplayLink = CADisplayLink(target: self, selector: #selector(handleIconAnimStep))
                iconAnimDisplayLink?.add(to: .main, forMode: .common)
            } else if !animated {
                iconAnims[i].type = newType
                iconAnims[i].alpha = 1
                iconAnims[i].targetType = newType
                iconAnims[i].targetAlpha = 1
                iconAnims[i].animating = false
            }
        }
    }

    @objc private func handleIconAnimStep() {
        var anyAnimating = false
        for i in 0..<iconAnims.count {
            if iconAnims[i].animating {
                let elapsed = CACurrentMediaTime() - iconAnims[i].animStart
                let progress = min(1, elapsed / iconAnimDuration)
                let eased = 0.5 - 0.5 * cos(.pi * progress)
                iconAnims[i].alpha = CGFloat(1 - eased)
                if progress >= 1 {
                    iconAnims[i].type = iconAnims[i].targetType
                    iconAnims[i].alpha = iconAnims[i].targetAlpha
                    iconAnims[i].animating = false
                } else {
                    anyAnimating = true
                }
            }
        }
        setNeedsDisplay()
        if !anyAnimating {
            iconAnimDisplayLink?.invalidate()
            iconAnimDisplayLink = nil
        }
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let totalWidth = rect.width
        let centerX = totalWidth / 2
        let hourWidth = (totalWidth - 2 * fadeWidth) / CGFloat(hoursRange * 2)
        let center = virtualHour
        let hours = (Int(floor(center)) - hoursRange ... Int(floor(center)) + hoursRange)
        let barY = barHeight/2 + topMargin
        let offset = (virtualHour - floor(virtualHour)) * hourWidth
        let fadeCount = 2 // сколько часов с каждого края затухают
        var hourXs: [CGFloat] = []
        ctx.setFillColor(UIColor.white.withAlphaComponent(0.25 * barAlpha).cgColor)
        ctx.fill(CGRect(x: fadeWidth, y: barY, width: totalWidth-2*fadeWidth, height: 2))
        for (idx, hour) in hours.enumerated() {
            let x = centerX + CGFloat(idx - hoursRange) * hourWidth - CGFloat(offset)
            hourXs.append(x)
            let isCurrent = hour == Int(round(virtualHour))
            let isNight = ((hour % 24 + 24) % 24) >= 20 || ((hour % 24 + 24) % 24) < 6
            let barColor: UIColor = isNight ? UIColor.systemIndigo : UIColor.systemYellow
            var opacity: CGFloat = 1.0
            if idx == 0 {
                let frac = CGFloat(virtualHour - floor(virtualHour))
                opacity = frac
            } else if idx == hours.count - 1 {
                let frac = 1 - CGFloat(virtualHour - floor(virtualHour))
                opacity = frac
            } else if idx < fadeCount {
                opacity = CGFloat(idx + 1) / CGFloat(fadeCount + 1)
            } else if idx > hours.count - fadeCount - 1 {
                opacity = CGFloat(hours.count - idx) / CGFloat(fadeCount + 1)
            }
            let textColor: UIColor = isCurrent ? UIColor.systemYellow : UIColor.white.withAlphaComponent(opacity)
            ctx.setFillColor(barColor.withAlphaComponent(((isCurrent ? 1 : 0.5) * barAlpha * opacity)).cgColor)
            ctx.fill(CGRect(x: x-1, y: barY-7, width: 2, height: 14))
            let hourStr = "\(((hour % 24 + 24) % 24))"
            let attr: [NSAttributedString.Key: Any] = [
                .font: isCurrent ? fontCurrent : font,
                .foregroundColor: textColor.withAlphaComponent((isCurrent ? 1 : 0.95) * barAlpha)
            ]
            let size = hourStr.size(withAttributes: attr)
            hourStr.draw(at: CGPoint(x: x-size.width/2, y: barY-markerHeight-hourLabelOffset), withAttributes: attr)
        }
        // Кешируем x-координаты для иконок только если не идёт анимация
        let isAnimating = displayLink != nil
        if !isAnimating && hourXs.count > hoursRange {
            cachedIconXs = [hourXs.first!, hourXs[hoursRange], hourXs.last!]
        }
        let iconXs = cachedIconXs.isEmpty ? [hourXs.first!, hourXs[hoursRange], hourXs.last!] : cachedIconXs
        for i in 0..<3 {
            let iconType = iconAnims[i].type
            let iconAlpha = iconAnims[i].alpha * barAlpha
            let iconName = iconType == .moon ? "moon.fill" : "sun.max.fill"
            let iconConfig = UIImage.SymbolConfiguration(pointSize: i == 1 ? 22 : 18, weight: .bold)
            if let icon = UIImage(systemName: iconName, withConfiguration: iconConfig)?.withRenderingMode(.alwaysOriginal) {
                let iconRect = CGRect(x: iconXs[i]-10, y: barY-markerHeight-hourLabelOffset-28, width: 20, height: 20)
                let tint = iconType == .moon ? UIColor.systemIndigo : UIColor.systemYellow
                icon.withTintColor(tint.withAlphaComponent(iconAlpha), renderingMode: .alwaysOriginal).draw(in: iconRect)
            }
        }
    }
    private func opacityForIndex(idx: Int, total: Int, fade: Int) -> CGFloat {
        if idx < fade { return CGFloat(idx+1)/CGFloat(fade+1) }
        if idx >= total-fade { return CGFloat(total-idx)/CGFloat(fade+1) }
        return 1.0
    }
}

class HidingCellViewController: UIViewController {
    private let mainViewModel: MainSceneViewModel
    private let backgroundImageView = UIImageView()
    private let cellTitleLabel = UILabel()
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    private let timeBarView = TimeBarView()
    private let advanceTimeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Advance Time", for: .normal)
        button.titleLabel?.font = UIFont(name: "Optima-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
        return button
    }()
    private let leaveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Leave", for: .normal)
        button.titleLabel?.font = UIFont(name: "Optima-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
        return button
    }()
    private let dangerStatusView = UIView()
    private let dangerIconView = UIImageView()
    private let dangerLabel = UILabel()
    private let dangerStackView = UIStackView()
    private let buttonsStackView = UIStackView()
    private let leaveButtonStackView = UIStackView()
    private var didAppearOnce = false

    init(mainViewModel: MainSceneViewModel) {
        self.mainViewModel = mainViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupBackgroundImage()
        setupCellTitleLabel()
        setupTopWidget()
        setupTimeBar()
        setupAdvanceTimeButton()
        setupLeaveButton()
        setupDangerStatusView()
        setupButtonsStackView()
        setupLeaveButtonStackView()
        setupLayout()
        subscribeToTimeUpdates()
        // Отключаем свайп-назад
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        updateLeaveButtonVisibility(animated: false)
        dangerStatusView.alpha = 0
        updateDangerStatus(animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timeBarView.animateAppear()
        updateLeaveButtonVisibility(animated: true)
        UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseInOut], animations: {
            self.dangerStatusView.alpha = 1
        }, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Увеличиваю горизонтальный extraSpace
        let extraSpaceX: CGFloat = 200
        let extraSpaceY: CGFloat = 100
        backgroundImageView.frame = CGRect(
            x: -extraSpaceX / 2,
            y: -extraSpaceY / 2,
            width: view.bounds.width + extraSpaceX,
            height: view.bounds.height + extraSpaceY
        )
        view.sendSubviewToBack(backgroundImageView)
    }

    private func setupCellTitleLabel() {
        guard let scene = GameStateService.shared.currentScene else { return }
        cellTitleLabel.font = UIFont(name: "Optima-Bold", size: 26) ?? UIFont.systemFont(ofSize: 26, weight: .bold)
        cellTitleLabel.textColor = .white
        cellTitleLabel.textAlignment = .center
        cellTitleLabel.numberOfLines = 1
        cellTitleLabel.layer.shadowColor = UIColor.black.cgColor
        cellTitleLabel.layer.shadowRadius = 2
        cellTitleLabel.layer.shadowOpacity = 0.5
        cellTitleLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        cellTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let hiddenAt = GameStateService.shared.player?.hiddenAt ?? .none
        cellTitleLabel.text = "\(scene.name): \(hiddenAt.description)" 
        view.addSubview(cellTitleLabel)
    }

    private func setupBackgroundImage() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        let hiddenAt = GameStateService.shared.player?.hiddenAt ?? .none
        let assetName = hiddenAt != .none ? hiddenAt.rawValue : nil
        if let assetName = assetName, UIImage(named: assetName) != nil {
            backgroundImageView.image = UIImage(named: assetName)
        } else {
            backgroundImageView.image = UIImage(named: "gaze2")
        }
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
    }

    private func setupTopWidget() {
        topWidgetContainerView.translatesAutoresizingMaskIntoConstraints = false
        topWidgetContainerView.backgroundColor = .clear
        view.addSubview(topWidgetContainerView)

        let widgetVC = TopWidgetUIViewController(viewModel: mainViewModel)
        addChild(widgetVC)
        topWidgetContainerView.addSubview(widgetVC.view)
        widgetVC.view.translatesAutoresizingMaskIntoConstraints = false
        widgetVC.didMove(toParent: self)
        self.topWidgetViewController = widgetVC
    }

    private func setupTimeBar() {
        timeBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeBarView)
        NSLayoutConstraint.activate([
            timeBarView.topAnchor.constraint(equalTo: cellTitleLabel.bottomAnchor, constant: 24),
            timeBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timeBarView.widthAnchor.constraint(equalToConstant: 600),
            timeBarView.heightAnchor.constraint(equalToConstant: 56)
        ])
        timeBarView.currentHour = GameTimeService.shared.currentHour
    }

    private func setupAdvanceTimeButton() {
        advanceTimeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(advanceTimeButton)
        advanceTimeButton.addTarget(self, action: #selector(advanceTimeTapped), for: .touchUpInside)
    }

    private func setupLeaveButton() {
        leaveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(leaveButton)
        leaveButton.addTarget(self, action: #selector(leaveTapped), for: .touchUpInside)
        leaveButton.alpha = 0 // по умолчанию скрыта, появится по логике
    }

    private func setupDangerStatusView() {
        dangerStatusView.translatesAutoresizingMaskIntoConstraints = false
        dangerStatusView.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        dangerStatusView.layer.cornerRadius = 16
        dangerStatusView.layer.masksToBounds = true
        view.addSubview(dangerStatusView)

        dangerStackView.translatesAutoresizingMaskIntoConstraints = false
        dangerStackView.axis = .horizontal
        dangerStackView.spacing = 10
        dangerStackView.alignment = .center
        dangerStackView.distribution = .equalCentering
        dangerStatusView.addSubview(dangerStackView)

        dangerIconView.translatesAutoresizingMaskIntoConstraints = false
        dangerIconView.contentMode = .scaleAspectFit
        dangerStackView.addArrangedSubview(dangerIconView)

        dangerLabel.translatesAutoresizingMaskIntoConstraints = false
        dangerLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        dangerLabel.textColor = .white
        dangerLabel.textAlignment = .center
        dangerStackView.addArrangedSubview(dangerLabel)

        NSLayoutConstraint.activate([
            dangerStatusView.topAnchor.constraint(equalTo: timeBarView.bottomAnchor, constant: 18),
            dangerStatusView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dangerStatusView.heightAnchor.constraint(equalToConstant: 40),
            dangerStatusView.widthAnchor.constraint(lessThanOrEqualToConstant: 380),

            dangerStackView.centerXAnchor.constraint(equalTo: dangerStatusView.centerXAnchor),
            dangerStackView.centerYAnchor.constraint(equalTo: dangerStatusView.centerYAnchor),
            dangerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: dangerStatusView.leadingAnchor, constant: 16),
            dangerStackView.trailingAnchor.constraint(lessThanOrEqualTo: dangerStatusView.trailingAnchor, constant: -16),
            dangerStackView.heightAnchor.constraint(equalTo: dangerStatusView.heightAnchor)
        ])
    }

    private func setupButtonsStackView() {
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.axis = .vertical
        buttonsStackView.spacing = 18
        buttonsStackView.alignment = .center
        buttonsStackView.distribution = .equalCentering
        view.addSubview(buttonsStackView)
        buttonsStackView.addArrangedSubview(advanceTimeButton)
    }

    private func setupLeaveButtonStackView() {
        leaveButtonStackView.translatesAutoresizingMaskIntoConstraints = false
        leaveButtonStackView.axis = .vertical
        leaveButtonStackView.spacing = 0
        leaveButtonStackView.alignment = .center
        leaveButtonStackView.distribution = .equalCentering
        view.addSubview(leaveButtonStackView)
        leaveButtonStackView.addArrangedSubview(leaveButton)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cellTitleLabel.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 2),
            cellTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cellTitleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            cellTitleLabel.heightAnchor.constraint(equalToConstant: 22),

            topWidgetContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2),
            topWidgetContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topWidgetContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topWidgetContainerView.heightAnchor.constraint(equalToConstant: 35),

            topWidgetViewController!.view.topAnchor.constraint(equalTo: topWidgetContainerView.topAnchor, constant: 2),
            topWidgetViewController!.view.leadingAnchor.constraint(equalTo: topWidgetContainerView.leadingAnchor, constant: 2),
            topWidgetViewController!.view.trailingAnchor.constraint(equalTo: topWidgetContainerView.trailingAnchor, constant: -2),
            topWidgetViewController!.view.bottomAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: -2),

            timeBarView.topAnchor.constraint(equalTo: cellTitleLabel.bottomAnchor, constant: 24),
            timeBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timeBarView.widthAnchor.constraint(equalToConstant: 600),
            timeBarView.heightAnchor.constraint(equalToConstant: 56),

            dangerStatusView.topAnchor.constraint(equalTo: timeBarView.bottomAnchor, constant: 18),
            dangerStatusView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dangerStatusView.heightAnchor.constraint(equalToConstant: 40),
            dangerStatusView.widthAnchor.constraint(lessThanOrEqualToConstant: 380),

            buttonsStackView.topAnchor.constraint(equalTo: dangerStatusView.bottomAnchor, constant: 24),
            buttonsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 48),

            leaveButtonStackView.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 16),
            leaveButtonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            leaveButtonStackView.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func subscribeToTimeUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateTimeBar), name: .timeAdvanced, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTimeOrStateChanged), name: .timeAdvanced, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDangerStatusNotification), name: .timeAdvanced, object: nil)
    }

    @objc private func updateTimeBar() {
        timeBarView.currentHour = GameTimeService.shared.currentHour
    }

    @objc private func handleTimeOrStateChanged() {
        updateLeaveButtonVisibility(animated: true)
    }

    private func updateLeaveButtonVisibility(animated: Bool) {
        let shouldShow = GameStateService.shared.couldLeaveHideout()
        let targetAlpha: CGFloat = shouldShow ? 1.0 : 0.0
        if animated {
            UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseInOut], animations: {
                self.leaveButton.alpha = targetAlpha
            }, completion: nil)
        } else {
            leaveButton.alpha = targetAlpha
        }
        leaveButton.isUserInteractionEnabled = shouldShow
    }

    @objc private func advanceTimeTapped() {
        GameTimeService.shared.advanceTime()
    }

    @objc private func leaveTapped() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true // вернуть свайп после ухода
        GameStateService.shared.movePlayerThroughHideouts(to: .none)
        navigationController?.popViewController(animated: true)
    }

    private func updateDangerStatus(animated: Bool) {
        let count = GameStateService.shared.getAwakeNpcsCount()
        let (icon, color, text) = dangerStatusInfo(for: count)
        let font = UIFont(name: "Optima-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        let newText = text
        let newIcon = UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate)
        let newColor = color

        let label = self.dangerLabel
        let iconView = self.dangerIconView
        let stack = self.dangerStackView
        let container = self.dangerStatusView

        let targetWidth: CGFloat = {
            // Оцениваем ширину текста + иконки + паддинги
            let textWidth = (newText as NSString).size(withAttributes: [.font: font]).width
            let iconWidth: CGFloat = 28 + 10 // иконка + spacing
            let minWidth: CGFloat = 120
            let maxWidth: CGFloat = 380
            return min(max(textWidth + iconWidth + 32, minWidth), maxWidth)
        }()

        let updateBlock = {
            label.font = font
            label.text = newText
            label.textColor = newColor
            iconView.image = newIcon
            iconView.tintColor = newColor
        }

        if animated {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseIn], animations: {
                stack.alpha = 0
            }, completion: { _ in
                updateBlock()
                // Анимируем ширину контейнера
                if let widthConstraint = container.constraints.first(where: { $0.firstAttribute == .width }) {
                    widthConstraint.constant = targetWidth
                }
                UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseInOut], animations: {
                    container.layoutIfNeeded()
                }, completion: { _ in
                    UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut], animations: {
                        stack.alpha = 1
                    }, completion: nil)
                })
            })
        } else {
            updateBlock()
            if let widthConstraint = container.constraints.first(where: { $0.firstAttribute == .width }) {
                widthConstraint.constant = targetWidth
            }
            container.layoutIfNeeded()
            stack.alpha = 1
        }
    }

    private func dangerStatusInfo(for count: Int) -> (icon: String, color: UIColor, text: String) {
        if count == 0 {
            return ("checkmark.shield", UIColor.systemGreen, "All is calm")
        } else if count <= 2 {
            return ("eye", UIColor.systemYellow, "Some movement outside")
        } else if count <= 5 {
            return ("exclamationmark.triangle", UIColor.systemOrange, "Someone is clearly awake outside")
        } else {
            return ("exclamationmark.octagon.fill", UIColor.systemRed, "Very dangerous to go out!")
        }
    }

    @objc private func updateDangerStatusNotification() {
        updateDangerStatus(animated: true)
    }
}

struct HidingCellTimeBar: View {
    @ObservedObject var timeService = GameTimeService.shared
    let hoursRange: Int = 6 // Сколько часов показывать влево и вправо от текущего
    let barHeight: CGFloat = 32
    let markerHeight: CGFloat = 24
    let markerWidth: CGFloat = 4
    let hourLabelOffset: CGFloat = 28
    let fadeWidth: CGFloat = 40
    
    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let centerX = totalWidth / 2
            let hourWidth = (totalWidth - 2 * fadeWidth) / CGFloat(hoursRange * 2)
            let currentHour = timeService.currentHour
            let hours = (currentHour - hoursRange ... currentHour + hoursRange).map { ($0 + 24) % 24 }
            ZStack {
                // Линия времени
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 2)
                    .cornerRadius(1)
                    .position(x: centerX, y: barHeight / 2)
                // Часовые шкалы
                HStack(spacing: 0) {
                    ForEach(Array(hours.enumerated()), id: \.offset) { idx, hour in
                        VStack(spacing: 0) {
                            if idx == hoursRange {
                                // Центральный маркер
                                Rectangle()
                                    .fill(Color.accentColor)
                                    .frame(width: markerWidth, height: markerHeight)
                                    .cornerRadius(2)
                                    .shadow(color: .accentColor.opacity(0.5), radius: 6)
                                    .offset(y: -6)
                                Text("\(hour)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.accentColor)
                                    .offset(y: -hourLabelOffset)
                            } else {
                                Rectangle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 2, height: 14)
                                    .cornerRadius(1)
                                    .opacity(opacityForIndex(idx: idx, total: hours.count, fade: 3))
                                Text("\(hour)")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.7 * opacityForIndex(idx: idx, total: hours.count, fade: 3)))
                                    .offset(y: -hourLabelOffset + 8)
                            }
                            Spacer()
                        }
                        .frame(width: hourWidth)
                    }
                }
                .frame(width: totalWidth - 2 * fadeWidth, height: barHeight)
                .position(x: centerX, y: barHeight / 2)
            }
        }
        .frame(height: barHeight + 24)
    }
    
    // Плавное исчезновение шкал по краям
    func opacityForIndex(idx: Int, total: Int, fade: Int) -> Double {
        if idx < fade { return Double(idx + 1) / Double(fade + 1) }
        if idx >= total - fade { return Double(total - idx) / Double(fade + 1) }
        return 1.0
    }
}

struct HidingCellView: UIViewControllerRepresentable {
    var mainSceneViewModel: MainSceneViewModel

    func makeUIViewController(context: Context) -> HidingCellViewController {
        return HidingCellViewController(mainViewModel: mainSceneViewModel)
    }

    func updateUIViewController(_ uiViewController: HidingCellViewController, context: Context) {
        // Обновление при необходимости
    }

    // Вставляем шкалу времени поверх UIKit-вью
    @ViewBuilder
    var body: some View {
        ZStack {
            UIViewControllerWrapper(mainSceneViewModel: mainSceneViewModel)
            VStack {
                Spacer().frame(height: 70)
                HidingCellTimeBar()
                    .frame(height: 56)
                Spacer()
            }
        }
    }
}

// Вспомогательный враппер для интеграции UIViewController и SwiftUI
struct UIViewControllerWrapper: UIViewControllerRepresentable {
    var mainSceneViewModel: MainSceneViewModel
    func makeUIViewController(context: Context) -> HidingCellViewController {
        HidingCellViewController(mainViewModel: mainSceneViewModel)
    }
    func updateUIViewController(_ uiViewController: HidingCellViewController, context: Context) {}
} 
