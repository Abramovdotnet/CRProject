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
        displayLink?.invalidate()
        animationStart = virtualHour
        let target = animationStart < Double(hour) ? Double(hour) : Double(hour) + 24
        animationEnd = target
        animationStartTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(handleAnimationStep))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func handleAnimationStep() {
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
        // --- Основная линия времени с тенью ---
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 8, color: UIColor.black.withAlphaComponent(0.22 * barAlpha).cgColor)
        ctx.setFillColor(UIColor.white.withAlphaComponent(0.18 * barAlpha).cgColor)
        ctx.fill(CGRect(x: fadeWidth, y: barY, width: totalWidth-2*fadeWidth, height: 2))
        ctx.restoreGState()
        // --- Часы ---
        var currentPulse: CGFloat = 1.0
        var currentHourX: CGFloat? = nil
        for (idx, hour) in hours.enumerated() {
            let x = centerX + CGFloat(idx - hoursRange) * hourWidth - CGFloat(offset)
            hourXs.append(x)
            let margin: CGFloat = 12
            if x < fadeWidth - margin || x > totalWidth - fadeWidth + margin {
                continue // не рисуем маркер и эффекты вне шкалы
            }
            let isCurrent = hour == Int(round(virtualHour))
            let isNight = ((hour % 24 + 24) % 24) >= 20 || ((hour % 24 + 24) % 24) < 6
            let isDawn = ((hour % 24 + 24) % 24) == 6
            let isDusk = ((hour % 24 + 24) % 24) == 20
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
            // --- Glow для текущего часа (пульсация) ---
            if isCurrent {
                currentPulse = 0.7 + 0.3 * CGFloat(sin(CACurrentMediaTime()*2))
                currentHourX = x
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 22, color: UIColor.systemYellow.withAlphaComponent(0.7 * barAlpha * currentPulse).cgColor)
                ctx.setFillColor(UIColor.systemYellow.withAlphaComponent(0.7 * barAlpha * currentPulse).cgColor)
                ctx.fillEllipse(in: CGRect(x: x-15, y: barY-20, width: 30, height: 30))
                ctx.restoreGState()
            }
            // --- Тень под маркерами ---
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 4, color: UIColor.black.withAlphaComponent(0.22 * barAlpha).cgColor)
            ctx.setFillColor(barColor.withAlphaComponent(((isCurrent ? 1 : 0.5) * barAlpha * opacity)).cgColor)
            ctx.fill(CGRect(x: x-1, y: barY-7, width: 2, height: 14))
            ctx.restoreGState()
            // --- Glow/тень под цифрами ---
            let hourStr = "\(((hour % 24 + 24) % 24))"
            let attr: [NSAttributedString.Key: Any] = [
                .font: isCurrent ? fontCurrent : font,
                .foregroundColor: textColor.withAlphaComponent((isCurrent ? 1 : 0.95) * barAlpha)
            ]
            let size = hourStr.size(withAttributes: attr)
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 6, color: UIColor.black.withAlphaComponent(0.45 * barAlpha).cgColor)
            hourStr.draw(at: CGPoint(x: x-size.width/2, y: barY-markerHeight-hourLabelOffset), withAttributes: attr)
            ctx.restoreGState()
            // --- Пламя/блик для дневных часов ---
            if !isNight && !isCurrent {
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 8, color: UIColor.systemYellow.withAlphaComponent(0.12 * opacity).cgColor)
                ctx.setFillColor(UIColor.systemYellow.withAlphaComponent(0.08 * opacity).cgColor)
                ctx.fillEllipse(in: CGRect(x: x-6, y: barY-10, width: 12, height: 12))
                ctx.restoreGState()
            }
            // --- Мерцание для ночных часов ---
            if isNight && !isCurrent {
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 8, color: UIColor.systemIndigo.withAlphaComponent(0.12 * opacity).cgColor)
                ctx.setFillColor(UIColor.systemIndigo.withAlphaComponent(0.08 * opacity).cgColor)
                ctx.fillEllipse(in: CGRect(x: x-6, y: barY-10, width: 12, height: 12))
                ctx.restoreGState()
            }
            ctx.setFillColor(barColor.withAlphaComponent(((isCurrent ? 1 : 0.5) * barAlpha * opacity)).cgColor)
            ctx.fill(CGRect(x: x-1, y: barY-7, width: 2, height: 14))
            // --- Подписи Night/Dawn/Day/Dusk с тенью и капсулой ---
            let isCurrentLabel = isCurrent && ((isDawn && hour % 24 == 6) || (isDusk && hour % 24 == 20) || (hour % 24 == 0) || (hour % 24 == 12))
            if isDawn {
                let dawnAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 12),
                    .foregroundColor: UIColor.yellow.withAlphaComponent(1.0)
                ]
                let dawnStr = "Dawn"
                let dawnSize = dawnStr.size(withAttributes: dawnAttr)
                if !isCurrentLabel {
                    let capsuleRect = CGRect(x: x-dawnSize.width/2-8, y: barY+18, width: dawnSize.width+16, height: dawnSize.height)
                    ctx.saveGState()
                    ctx.setFillColor(UIColor.black.withAlphaComponent(0.18).cgColor)
                    let capsulePath = UIBezierPath(roundedRect: capsuleRect, cornerRadius: dawnSize.height/2)
                    ctx.addPath(capsulePath.cgPath)
                    ctx.fillPath()
                    ctx.restoreGState()
                }
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 2, color: UIColor.black.withAlphaComponent(0.5).cgColor)
                dawnStr.draw(at: CGPoint(x: x-dawnSize.width/2, y: barY+18), withAttributes: dawnAttr)
                ctx.restoreGState()
            } else if isDusk {
                let duskAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 12),
                    .foregroundColor: UIColor.systemIndigo.withAlphaComponent(1.0)
                ]
                let duskStr = "Dusk"
                let duskSize = duskStr.size(withAttributes: duskAttr)
                if !isCurrentLabel {
                    let capsuleRect = CGRect(x: x-duskSize.width/2-8, y: barY+18, width: duskSize.width+16, height: duskSize.height)
                    ctx.saveGState()
                    ctx.setFillColor(UIColor.black.withAlphaComponent(0.18).cgColor)
                    let capsulePath = UIBezierPath(roundedRect: capsuleRect, cornerRadius: duskSize.height/2)
                    ctx.addPath(capsulePath.cgPath)
                    ctx.fillPath()
                    ctx.restoreGState()
                }
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 2, color: UIColor.black.withAlphaComponent(0.5).cgColor)
                duskStr.draw(at: CGPoint(x: x-duskSize.width/2, y: barY+18), withAttributes: duskAttr)
                ctx.restoreGState()
            } else if isNight && hour % 24 == 0 {
                let nightAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 12),
                    .foregroundColor: UIColor.systemTeal.withAlphaComponent(1.0)
                ]
                let nightStr = "Night"
                let nightSize = nightStr.size(withAttributes: nightAttr)
                if !isCurrentLabel {
                    let capsuleRect = CGRect(x: x-nightSize.width/2-8, y: barY+18, width: nightSize.width+16, height: nightSize.height)
                    ctx.saveGState()
                    ctx.setFillColor(UIColor.black.withAlphaComponent(0.18).cgColor)
                    let capsulePath = UIBezierPath(roundedRect: capsuleRect, cornerRadius: nightSize.height/2)
                    ctx.addPath(capsulePath.cgPath)
                    ctx.fillPath()
                    ctx.restoreGState()
                }
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 2, color: UIColor.black.withAlphaComponent(0.5).cgColor)
                nightStr.draw(at: CGPoint(x: x-nightSize.width/2, y: barY+18), withAttributes: nightAttr)
                ctx.restoreGState()
            } else if !isNight && hour % 24 == 12 {
                let dayAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 12),
                    .foregroundColor: UIColor.systemYellow.withAlphaComponent(1.0)
                ]
                let dayStr = "Day"
                let daySize = dayStr.size(withAttributes: dayAttr)
                if !isCurrentLabel {
                    let capsuleRect = CGRect(x: x-daySize.width/2-8, y: barY+18, width: daySize.width+16, height: daySize.height)
                    ctx.saveGState()
                    ctx.setFillColor(UIColor.black.withAlphaComponent(0.18).cgColor)
                    let capsulePath = UIBezierPath(roundedRect: capsuleRect, cornerRadius: daySize.height/2)
                    ctx.addPath(capsulePath.cgPath)
                    ctx.fillPath()
                    ctx.restoreGState()
                }
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 2, color: UIColor.black.withAlphaComponent(0.5).cgColor)
                dayStr.draw(at: CGPoint(x: x-daySize.width/2, y: barY+18), withAttributes: dayAttr)
                ctx.restoreGState()
            }
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
            let iconConfig = UIImage.SymbolConfiguration(pointSize: i == 1 ? 32 : 24, weight: .bold)
            if let icon = UIImage(systemName: iconName, withConfiguration: iconConfig)?.withRenderingMode(.alwaysOriginal) {
                let iconRect = CGRect(x: iconXs[i]-16, y: barY-markerHeight-hourLabelOffset-32, width: 32, height: 32)
                let tint = iconType == .moon ? UIColor.systemIndigo : UIColor.systemYellow
                // Glow для иконок
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 18, color: tint.withAlphaComponent(0.7 * iconAlpha).cgColor)
                icon.withTintColor(tint.withAlphaComponent(iconAlpha), renderingMode: .alwaysOriginal).draw(in: iconRect)
                ctx.restoreGState()
            }
        }
        // --- Клык-указатель ---
        let fangX = currentHourX ?? hourXs[hoursRange]
        let fangY = barY+8
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 8, color: UIColor.systemYellow.withAlphaComponent(0.7 * barAlpha * currentPulse).cgColor)
        ctx.setFillColor(UIColor.systemYellow.withAlphaComponent(0.85 * barAlpha * currentPulse).cgColor)
        let fangPath = UIBezierPath()
        fangPath.move(to: CGPoint(x: fangX, y: fangY))
        fangPath.addLine(to: CGPoint(x: fangX-6, y: fangY+18))
        fangPath.addQuadCurve(to: CGPoint(x: fangX+6, y: fangY+18), controlPoint: CGPoint(x: fangX, y: fangY+28))
        fangPath.addLine(to: CGPoint(x: fangX, y: fangY))
        fangPath.close()
        ctx.addPath(fangPath.cgPath)
        ctx.fillPath()
        ctx.restoreGState()
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
    private var dustEffectView: UIHostingController<DustEmitterView>? // Для эффекта пыли
    private let cellTitleLabel = UILabel()
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    private let timeBarView = TimeBarView()
    private let dangerStatusView = UIView()
    private let dangerIconView = UIImageView()
    private let dangerLabel = UILabel()
    private let dangerStackView = UIStackView()
    private var advanceTimeCircleButton: UIButton!
    private var leaveCircleButton: UIButton!
    private var didAppearOnce = false
    private let buttonSize: CGFloat = 40

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
        setupDustEffect()
        setupCellTitleLabel()
        setupTopWidget()
        setupTimeBar()
        setupDangerStatusView()
        setupCircleActionButtons()
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
        self.dangerStatusView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        self.dangerStatusView.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: []) {
            self.dangerStatusView.transform = .identity
            self.dangerStatusView.alpha = 1
        }
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
        // Dust effect должен быть над фоном, но под UI
        if let dustView = dustEffectView?.view {
            dustView.frame = view.bounds
            view.insertSubview(dustView, aboveSubview: backgroundImageView)
        }
        // Обновляем borderLayer для advanceTimeButton
        if let borderLayer = advanceTimeBorderLayer {
            borderLayer.frame = advanceTimeCircleButton.bounds
            borderLayer.path = UIBezierPath(roundedRect: advanceTimeCircleButton.bounds, cornerRadius: 12).cgPath
        }
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

    private func setupDustEffect() {
        let dustViewHostingController = UIHostingController(rootView: DustEmitterView())
        dustViewHostingController.view.backgroundColor = .clear
        dustViewHostingController.view.translatesAutoresizingMaskIntoConstraints = true // Для frame-based layout
        dustViewHostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addChild(dustViewHostingController)
        view.addSubview(dustViewHostingController.view)
        dustViewHostingController.didMove(toParent: self)
        self.dustEffectView = dustViewHostingController
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
            timeBarView.topAnchor.constraint(equalTo: cellTitleLabel.bottomAnchor, constant: 8),
            timeBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timeBarView.widthAnchor.constraint(equalToConstant: 600),
            timeBarView.heightAnchor.constraint(equalToConstant: 105)
        ])
        timeBarView.currentHour = GameTimeService.shared.currentHour
    }

    private func setupDangerStatusView() {
        dangerStatusView.translatesAutoresizingMaskIntoConstraints = false
        // Blur + внутренняя текстура + свечение
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = dangerStatusView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dangerStatusView.addSubview(blurView)
        // Текстура (например, semi-transparent pattern)
        let textureView = UIImageView(image: UIImage(named: "paperTexture")?.withRenderingMode(.alwaysTemplate))
        textureView.alpha = 0.18
        textureView.contentMode = .scaleAspectFill
        textureView.frame = dangerStatusView.bounds
        textureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dangerStatusView.addSubview(textureView)
        dangerStatusView.backgroundColor = UIColor(red: 0.18, green: 0.08, blue: 0.13, alpha: 0.5)
        dangerStatusView.layer.cornerRadius = 18
        dangerStatusView.layer.masksToBounds = true
        // Внутреннее свечение
        let glow = CALayer()
        glow.frame = dangerStatusView.bounds.insetBy(dx: -8, dy: -8)
        glow.backgroundColor = UIColor.clear.cgColor
        glow.shadowColor = UIColor.purple.withAlphaComponent(0.4).cgColor
        glow.shadowRadius = 16
        glow.shadowOpacity = 1
        glow.shadowOffset = .zero
        dangerStatusView.layer.insertSublayer(glow, at: 0)
        // Бордер
        dangerStatusView.layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.3).cgColor
        dangerStatusView.layer.borderWidth = 0.7
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
        // Свечение (тень) для dangerIconView
        dangerIconView.layer.shadowColor = UIColor.systemGreen.cgColor // по умолчанию, обновляется в updateDangerStatus
        dangerIconView.layer.shadowRadius = 14
        dangerIconView.layer.shadowOpacity = 0.95
        dangerIconView.layer.shadowOffset = .zero
        dangerIconView.layer.masksToBounds = false
        dangerIconView.layer.shadowPath = nil
        // Усиление свечения: прозрачный слой под иконкой
        let glowLayer = CALayer()
        glowLayer.backgroundColor = UIColor.clear.cgColor
        glowLayer.shadowColor = UIColor.systemGreen.cgColor
        glowLayer.shadowRadius = 22
        glowLayer.shadowOpacity = 0.7
        glowLayer.shadowOffset = .zero
        glowLayer.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        glowLayer.position = CGPoint(x: 16, y: 16)
        glowLayer.name = "dangerGlow"
        dangerIconView.layer.insertSublayer(glowLayer, at: 0)

        dangerLabel.translatesAutoresizingMaskIntoConstraints = false
        dangerLabel.font = UIFont(name: "Papyrus", size: 16) ?? UIFont(name: "Cochin", size: 16) ?? UIFont.systemFont(ofSize: 16)
        dangerLabel.textColor = .white
        dangerLabel.textAlignment = .center
        dangerLabel.layer.shadowColor = UIColor.black.cgColor
        dangerLabel.layer.shadowRadius = 2
        dangerLabel.layer.shadowOpacity = 0.7
        dangerLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
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

    private func setupCircleActionButtons() {
        // Advance Time
        advanceTimeCircleButton = UIButton(type: .custom)
        advanceTimeCircleButton.translatesAutoresizingMaskIntoConstraints = false
        let hourglassIcon = UIImage(systemName: "hourglass.bottomhalf.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold))?.withRenderingMode(.alwaysTemplate)
        advanceTimeCircleButton.setImage(hourglassIcon, for: .normal)
        advanceTimeCircleButton.tintColor = .white
        advanceTimeCircleButton.backgroundColor = UIColor(white: 0.08, alpha: 0.98)
        advanceTimeCircleButton.layer.cornerRadius = buttonSize / 2
        advanceTimeCircleButton.layer.masksToBounds = false
        // Glow
        let advGlow = CALayer()
        advGlow.frame = CGRect(x: -1, y: -1, width: buttonSize + 2, height: buttonSize + 2)
        advGlow.cornerRadius = (buttonSize + 2) / 2
        advGlow.backgroundColor = UIColor.white.withAlphaComponent(0.7).cgColor
        advGlow.shadowColor = UIColor.white.cgColor
        advGlow.shadowRadius = 8
        advGlow.shadowOpacity = 1.0
        advGlow.shadowOffset = .zero
        advGlow.opacity = 0.7
        advanceTimeCircleButton.layer.insertSublayer(advGlow, at: 0)
        advanceTimeCircleButton.addTarget(self, action: #selector(advanceTimeTapped), for: .touchUpInside)
        advanceTimeCircleButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        advanceTimeCircleButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        view.addSubview(advanceTimeCircleButton)
        // Leave
        leaveCircleButton = UIButton(type: .custom)
        leaveCircleButton.translatesAutoresizingMaskIntoConstraints = false
        let leaveIcon = UIImage(systemName: "arrow.uturn.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold))?.withRenderingMode(.alwaysTemplate)
        leaveCircleButton.setImage(leaveIcon, for: .normal)
        leaveCircleButton.tintColor = .white
        leaveCircleButton.backgroundColor = UIColor(white: 0.08, alpha: 0.98)
        leaveCircleButton.layer.cornerRadius = buttonSize / 2
        leaveCircleButton.layer.masksToBounds = false
        // Glow
        let leaveGlow = CALayer()
        leaveGlow.frame = CGRect(x: -1, y: -1, width: buttonSize + 2, height: buttonSize + 2)
        leaveGlow.cornerRadius = (buttonSize + 2) / 2
        leaveGlow.backgroundColor = UIColor.white.withAlphaComponent(0.7).cgColor
        leaveGlow.shadowColor = UIColor.white.cgColor
        leaveGlow.shadowRadius = 8
        leaveGlow.shadowOpacity = 1.0
        leaveGlow.shadowOffset = .zero
        leaveGlow.opacity = 0.7
        leaveCircleButton.layer.insertSublayer(leaveGlow, at: 0)
        leaveCircleButton.addTarget(self, action: #selector(leaveTapped), for: .touchUpInside)
        leaveCircleButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        leaveCircleButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        view.addSubview(leaveCircleButton)
        // Constraints
        NSLayoutConstraint.activate([
            advanceTimeCircleButton.centerYAnchor.constraint(equalTo: timeBarView.centerYAnchor),
            advanceTimeCircleButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 18),
            advanceTimeCircleButton.widthAnchor.constraint(equalToConstant: buttonSize),
            advanceTimeCircleButton.heightAnchor.constraint(equalToConstant: buttonSize),
            leaveCircleButton.centerYAnchor.constraint(equalTo: timeBarView.centerYAnchor),
            leaveCircleButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -18),
            leaveCircleButton.widthAnchor.constraint(equalToConstant: buttonSize),
            leaveCircleButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
        leaveCircleButton.alpha = 0 // по умолчанию скрыта, появится по логике
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

            timeBarView.topAnchor.constraint(equalTo: cellTitleLabel.bottomAnchor, constant: 8),
            timeBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timeBarView.widthAnchor.constraint(equalToConstant: 600),
            timeBarView.heightAnchor.constraint(equalToConstant: 105),

            dangerStatusView.topAnchor.constraint(equalTo: timeBarView.bottomAnchor, constant: 18),
            dangerStatusView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dangerStatusView.heightAnchor.constraint(equalToConstant: 40),
            dangerStatusView.widthAnchor.constraint(lessThanOrEqualToConstant: 380),

            advanceTimeCircleButton.centerYAnchor.constraint(equalTo: timeBarView.centerYAnchor),
            advanceTimeCircleButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 18),
            advanceTimeCircleButton.widthAnchor.constraint(equalToConstant: buttonSize),
            advanceTimeCircleButton.heightAnchor.constraint(equalToConstant: buttonSize),
            leaveCircleButton.centerYAnchor.constraint(equalTo: timeBarView.centerYAnchor),
            leaveCircleButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -18),
            leaveCircleButton.widthAnchor.constraint(equalToConstant: buttonSize),
            leaveCircleButton.heightAnchor.constraint(equalToConstant: buttonSize)
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
                self.leaveCircleButton.alpha = targetAlpha
            }, completion: nil)
        } else {
            leaveCircleButton.alpha = targetAlpha
        }
        leaveCircleButton.isUserInteractionEnabled = shouldShow
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
            iconView.layer.shadowColor = newColor.cgColor // обновляем цвет свечения
            // Обновляем цвет свечения у glowLayer
            if let glow = iconView.layer.sublayers?.first(where: { $0.name == "dangerGlow" }) {
                glow.shadowColor = newColor.cgColor
            }
            container.layer.borderColor = newColor.cgColor // цвет рамки = цвету статуса
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
            return ("moon.stars", UIColor.systemGreen, "You are safe... for now.")
        } else if count <= 2 {
            return ("eye", UIColor.systemYellow, "Some movement outside...")
        } else if count <= 5 {
            return ("flame", UIColor.systemOrange, "Someone is clearly awake outside")
        } else {
            return ("shield.lefthalf.filled", UIColor.systemRed, "Very dangerous to go out!")
        }
    }

    @objc private func updateDangerStatusNotification() {
        updateDangerStatus(animated: true)
    }

    // Анимация нажатия для кнопок
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.08) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.alpha = 0.85
        }
    }
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }

    // MARK: - Border обновление для advanceTimeButton
    private var advanceTimeBorderLayer: CAShapeLayer? {
        return advanceTimeCircleButton.layer.sublayers?.compactMap { $0 as? CAShapeLayer }.first(where: { $0.name == "roundedBorder" })
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
