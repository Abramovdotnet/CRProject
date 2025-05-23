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
        ctx.setFillColor(UIColor.white.withAlphaComponent(0.25 * barAlpha).cgColor)
        ctx.fill(CGRect(x: fadeWidth, y: barY, width: totalWidth-2*fadeWidth, height: 2))
        let fadeGradient = CGGradient(colorsSpace: nil, colors: [UIColor.clear.cgColor, UIColor.white.withAlphaComponent(0.25 * barAlpha).cgColor] as CFArray, locations: [0,1])!
        ctx.saveGState()
        ctx.clip(to: CGRect(x: 0, y: 0, width: fadeWidth, height: barY+20))
        ctx.drawLinearGradient(fadeGradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: fadeWidth, y: 0), options: [])
        ctx.restoreGState()
        ctx.saveGState()
        ctx.clip(to: CGRect(x: totalWidth-fadeWidth, y: 0, width: fadeWidth, height: barY+20))
        ctx.drawLinearGradient(fadeGradient, start: CGPoint(x: totalWidth, y: 0), end: CGPoint(x: totalWidth-fadeWidth, y: 0), options: [])
        ctx.restoreGState()
        for (idx, hour) in hours.enumerated() {
            let x = centerX + CGFloat(idx - hoursRange) * hourWidth - CGFloat(offset)
            let isCurrent = hour == Int(round(virtualHour))
            let isNight = ((hour % 24 + 24) % 24) >= 20 || ((hour % 24 + 24) % 24) < 6
            let barColor: UIColor = isNight ? UIColor.systemIndigo : UIColor.systemYellow
            let textColor: UIColor = isCurrent ? UIColor.systemYellow : UIColor.white
            ctx.setFillColor(barColor.withAlphaComponent((isCurrent ? 1 : 0.5) * barAlpha).cgColor)
            ctx.fill(CGRect(x: x-1, y: barY-7, width: 2, height: 14))
            let hourStr = "\(((hour % 24 + 24) % 24))"
            let attr: [NSAttributedString.Key: Any] = [
                .font: isCurrent ? fontCurrent : font,
                .foregroundColor: textColor.withAlphaComponent((isCurrent ? 1 : 0.95) * barAlpha)
            ]
            let size = hourStr.size(withAttributes: attr)
            hourStr.draw(at: CGPoint(x: x-size.width/2, y: barY-markerHeight-hourLabelOffset), withAttributes: attr)
        }
        let iconPositions: [CGFloat] = [fadeWidth + hourWidth/2, centerX, totalWidth-fadeWidth-hourWidth/2]
        for i in 0..<3 {
            let iconType = iconAnims[i].type
            let iconAlpha = iconAnims[i].alpha * barAlpha
            let iconName = iconType == .moon ? "moon.fill" : "sun.max.fill"
            let iconConfig = UIImage.SymbolConfiguration(pointSize: i == 1 ? 22 : 18, weight: .bold)
            if let icon = UIImage(systemName: iconName, withConfiguration: iconConfig)?.withRenderingMode(.alwaysOriginal) {
                let iconRect = CGRect(x: iconPositions[i]-12, y: barY-markerHeight-hourLabelOffset-22, width: 24, height: 24)
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
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    private let timeBarView = TimeBarView()
    private let advanceTimeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Advance Time", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemGray.withAlphaComponent(0.7)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
        return button
    }()

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
        setupTopWidget()
        setupTimeBar()
        setupAdvanceTimeButton()
        setupLayout()
        subscribeToTimeUpdates()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timeBarView.animateAppear()
    }

    private func setupBackgroundImage() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        let hiddenAt = GameStateService.shared.player?.hiddenAt ?? .none
        let imageName = hiddenAt != .none ? hiddenAt.rawValue : "hiding_default"
        backgroundImageView.image = UIImage(named: imageName)
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
            timeBarView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 16),
            timeBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            timeBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            timeBarView.heightAnchor.constraint(equalToConstant: 56)
        ])
        timeBarView.currentHour = GameTimeService.shared.currentHour
    }

    private func setupAdvanceTimeButton() {
        advanceTimeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(advanceTimeButton)
        NSLayoutConstraint.activate([
            advanceTimeButton.topAnchor.constraint(equalTo: timeBarView.bottomAnchor, constant: 18),
            advanceTimeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        advanceTimeButton.addTarget(self, action: #selector(advanceTimeTapped), for: .touchUpInside)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            topWidgetContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2),
            topWidgetContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topWidgetContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topWidgetContainerView.heightAnchor.constraint(equalToConstant: 35),

            topWidgetViewController!.view.topAnchor.constraint(equalTo: topWidgetContainerView.topAnchor, constant: 2),
            topWidgetViewController!.view.leadingAnchor.constraint(equalTo: topWidgetContainerView.leadingAnchor, constant: 2),
            topWidgetViewController!.view.trailingAnchor.constraint(equalTo: topWidgetContainerView.trailingAnchor, constant: -2),
            topWidgetViewController!.view.bottomAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: -2)
        ])
    }

    private func subscribeToTimeUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateTimeBar), name: .timeAdvanced, object: nil)
    }

    @objc private func updateTimeBar() {
        timeBarView.currentHour = GameTimeService.shared.currentHour
    }

    @objc private func advanceTimeTapped() {
        GameTimeService.shared.advanceTime()
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
                // Fade по краям
                HStack(spacing: 0) {
                    LinearGradient(gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.25)]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: fadeWidth, height: barHeight)
                    Spacer()
                    LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.25), Color.clear]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: fadeWidth, height: barHeight)
                }
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
