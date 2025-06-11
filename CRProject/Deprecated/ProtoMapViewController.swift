import UIKit

// UIView для отрисовки линий связей
class MapViewLinesView: UIView {
    var calculatedScenes: [CalculatedScene] = []
    var scenePoints: [Int: CGPoint] = [:] // Для быстрого доступа к точкам по ID

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false // Важно для прозрачности
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with scenes: [CalculatedScene]) {
        self.calculatedScenes = scenes
        self.scenePoints = Dictionary(uniqueKeysWithValues: scenes.map { ($0.scene.id, $0.point) })
        
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Начало)
        print("[MapViewLinesView] setup: Number of scenes: \(self.calculatedScenes.count), Number of scenePoints: \(self.scenePoints.count)")
        if !self.scenePoints.isEmpty && !self.calculatedScenes.isEmpty {
             if let firstSceneId = self.calculatedScenes.first?.scene.id, let firstPoint = self.scenePoints[firstSceneId] {
                print("[MapViewLinesView] setup: First point example ID \(firstSceneId) at \(firstPoint)")
            } else {
                print("[MapViewLinesView] setup: Could not get first scene ID or point for logging.")
            }
        } else {
            print("[MapViewLinesView] setup: scenePoints or calculatedScenes is empty.")
        }
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Конец)

        self.setNeedsDisplay() // Перерисовать при обновлении данных
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Начало)
        print("[MapViewLinesView] draw: called. Number of scenes: \(calculatedScenes.count). Rect: \(rect)")
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Конец)
        guard let context = UIGraphicsGetCurrentContext() else { 
            print("[MapViewLinesView] draw: Could not get graphics context!")
            return
        }

        // Рисуем связи родитель-потомок
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Начало)
        print("[MapViewLinesView] draw: Attempting to draw parent-child lines. Context: \(String(describing: context))")
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Конец)
        context.setStrokeColor(UIColor.gray.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1.0)
        for calcScene in calculatedScenes {
            let parentId = calcScene.scene.parentSceneId // parentSceneId это Int
            if parentId != 0, let parentPoint = scenePoints[parentId] { // Проверяем, что ID не 0 и точка существует
                context.move(to: parentPoint)
                context.addLine(to: calcScene.point)
                context.strokePath()
            }
        }

        // Рисуем хаб-связи
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Начало)
        print("[MapViewLinesView] draw: Attempting to draw hub lines. Context: \(String(describing: context))")
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Конец)
        context.setStrokeColor(UIColor.blue.withAlphaComponent(0.7).cgColor)
        context.setLineWidth(1.5)
        for calcScene in calculatedScenes {
            for hubId in calcScene.scene.hubSceneIds {
                if let hubPoint = scenePoints[hubId] {
                    context.move(to: calcScene.point)
                    context.addLine(to: hubPoint)
                    context.strokePath()
                }
            }
        }
        
    }
}

class ProtoMapViewController: UIViewController, UIScrollViewDelegate {
    private var scrollView: UIScrollView!
    private var contentView: UIView! // Контейнер для маркеров локаций
    private var linesView: MapViewLinesView! // View для отрисовки линий

    var calculatedScenes: [CalculatedScene] = []

    // Для центрирования контента
    private var contentWidth: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private let padding: CGFloat = 100 // Отступы вокруг контента

    init(calculatedScenes: [CalculatedScene]) {
        self.calculatedScenes = calculatedScenes
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray // Фон для самой карты

        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Начало)
        print("[ProtoMapVC] viewDidLoad: Number of calculated scenes received: \(calculatedScenes.count)")
        if calculatedScenes.isEmpty {
            print("[ProtoMapVC] WARNING: calculatedScenes is EMPTY!")
        } else {
            print("[ProtoMapVC] First 10 scenes (or fewer if less than 10):")
            for (index, calcScene) in calculatedScenes.enumerated().prefix(10) {
                print("  Scene \(index): ID \(calcScene.scene.id), Name: \(calcScene.scene.name), Point: \(calcScene.point)")
            }
            if calculatedScenes.count > 10 {
                print("  ... and \(calculatedScenes.count - 10) more scenes.")
            }
        }
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Конец)

        setupScrollView()
        setupContentViewAndLinesView()
        placeLocationMarkers()
        calculateContentSizeAndSetupScrollView()
    }

    private func setupScrollView() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 3.0
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.backgroundColor = .black // Фон области скролла
        view.addSubview(scrollView)
    }

    private func setupContentViewAndLinesView() {
        // ContentView будет иметь размер, достаточный для всех точек
        // Его frame будет рассчитан позже в calculateContentSizeAndSetupScrollView
        contentView = UIView()
        contentView.backgroundColor = .clear // Прозрачный, чтобы видеть фон scrollView
        scrollView.addSubview(contentView)

        linesView = MapViewLinesView()
        linesView.isUserInteractionEnabled = false // Не перехватывать события тача
        // Frame linesView будет такой же, как у contentView
        contentView.addSubview(linesView) // Линии рисуются внутри contentView
    }

    private func placeLocationMarkers() {
        guard !calculatedScenes.isEmpty else {
            print("[ProtoMapVC] placeLocationMarkers: calculatedScenes is empty, doing nothing.")
            return
        }

        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for calcScene in calculatedScenes {
            let point = calcScene.point
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)

            let markerLabel = UILabel()
            markerLabel.text = "\(calcScene.scene.name) (\(calcScene.scene.id))"
            markerLabel.font = UIFont.systemFont(ofSize: 10)
            markerLabel.textColor = .white
            markerLabel.backgroundColor = markerColor(for: calcScene.scene.sceneType)
            markerLabel.textAlignment = .center
            markerLabel.numberOfLines = 2
            markerLabel.layer.cornerRadius = 5
            markerLabel.layer.masksToBounds = true
            markerLabel.translatesAutoresizingMaskIntoConstraints = false
            markerLabel.sizeToFit() // Определяем размер до добавления, чтобы использовать для позиционирования
            
            // Позиционируем центр UILabel в точке
            markerLabel.frame.origin = CGPoint(x: point.x - markerLabel.frame.width / 2, 
                                              y: point.y - markerLabel.frame.height / 2)
            contentView.addSubview(markerLabel)
        }

        // Определяем общий размер контента
        contentWidth = (maxX - minX) + padding * 2
        contentHeight = (maxY - minY) + padding * 2
        
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Начало)
        print("[ProtoMapVC] placeLocationMarkers: Calculated minX: \(minX), maxX: \(maxX), minY: \(minY), maxY: \(maxY)")
        print("[ProtoMapVC] placeLocationMarkers: Calculated contentWidth: \(contentWidth), contentHeight: \(contentHeight)")
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Конец)
        
        // Смещаем все точки так, чтобы minX, minY стали padding/2
        // Это нужно, чтобы верхний левый маркер не был в 0,0 contentView, а имел отступ
        let offsetX = -minX + padding
        let offsetY = -minY + padding
        
        for subview in contentView.subviews {
            if subview is MapViewLinesView { continue } // Не двигаем сам linesView
            subview.frame.origin.x += offsetX
            subview.frame.origin.y += offsetY
        }
        
        // Обновляем точки в `calculatedScenes` и для `linesView` с учетом смещения
        var updatedScenePointsForLines: [Int: CGPoint] = [:]
        for i in 0..<calculatedScenes.count {
            var scene = calculatedScenes[i]
            let newPoint = CGPoint(x: scene.point.x + offsetX, y: scene.point.y + offsetY)
            // calculatedScenes[i].point = newPoint // CalculatedScene is a struct, need to replace
             calculatedScenes[i] = CalculatedScene(scene: scene.scene, point: newPoint)
            updatedScenePointsForLines[scene.scene.id] = newPoint
        }
        linesView.setup(with: calculatedScenes) // Передаем обновленные сцены с новыми точками
    }
    
    private func markerColor(for sceneType: SceneType) -> UIColor {
        // Простая логика цвета на основе типа сцены. Можно расширить.
        switch sceneType {
        case .tavern: return .brown
        case .cathedral: return .purple
        case .square: return .green
        case .district: return .orange
        case .house: return .cyan
        case .town: return .yellow.withAlphaComponent(0.7)
        default: return .lightGray
        }
    }

    private func calculateContentSizeAndSetupScrollView() {
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        linesView.frame = contentView.bounds // linesView занимает всю область contentView
        scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
        
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Начало)
        print("[ProtoMapVC] calculateContentSize: scrollView.bounds: \(scrollView.bounds)")
        print("[ProtoMapVC] calculateContentSize: contentWidth: \(contentWidth), contentHeight: \(contentHeight)")
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Конец)
        
        // Начальное масштабирование, чтобы весь контент был виден (если возможно)
        if contentWidth > 0 && contentHeight > 0 {
            let scaleWidth = scrollView.bounds.width / contentWidth
            let scaleHeight = scrollView.bounds.height / contentHeight
            let minScale = min(scaleWidth, scaleHeight, scrollView.maximumZoomScale) // Учитываем и max zoom
            
            // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Начало)
            print("[ProtoMapVC] calculateContentSize: scaleWidth: \(scaleWidth), scaleHeight: \(scaleHeight), minScale: \(minScale)")
            // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Конец)

            // ВОЗВРАЩАЕМ АВТОМАТИЧЕСКУЮ УСТАНОВКУ МАСШТАБА
            let finalScale = max(minScale, scrollView.minimumZoomScale)
            scrollView.setZoomScale(finalScale, animated: false)
            print("[ProtoMapVC] calculateContentSize: final zoomScale SET to: \(finalScale)")
            
            // Центрируем контент после начального масштабирования
            centerContent() 

            // ПРИНУДИТЕЛЬНО УСТАНАВЛИВАЕМ contentOffset В НАЧАЛО
            scrollView.contentOffset = .zero 
            print("[ProtoMapVC] DEBUG: Forced contentOffset to zero.")
        }
    }
    
    private func centerContent() {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width * scrollView.zoomScale) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height * scrollView.zoomScale) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }

    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent() // Перецентрируем контент при масштабировании
    }
} 
