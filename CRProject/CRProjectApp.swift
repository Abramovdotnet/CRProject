import UIKit

@main
class CRProjectApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register services in the correct order
        let dependencyManager = DependencyManager.shared
        
        // Register core services first
        dependencyManager.register(LocationReader())
        dependencyManager.register(NPCReader())
        dependencyManager.register(StatisticsService())
        dependencyManager.register(GameTimeService())
        dependencyManager.register(GameEventsBusService())
        dependencyManager.register(CoinsManagementService())
        dependencyManager.register(NPCInteractionEventsService())
        
        // Then register other services
        dependencyManager.register(VampireNatureRevealService())
        dependencyManager.register(BloodManagementService())
        dependencyManager.register(FeedingService())
        dependencyManager.register(InvestigationService())
        dependencyManager.register(GameStateService(
            gameTime: dependencyManager.resolve(),
            vampireNatureRevealService: dependencyManager.resolve()
        ))
        dependencyManager.register(QuestService())
        
        VibrationService.shared.successVibration()
        
        // Setup window and root view controller
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        
        // Create main view controller
        let mainViewModel = MainSceneViewModel()
        let rootViewController = SceneViewController(mainViewModel: mainViewModel)
        
        // Create navigation controller for scene
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        rootViewController.customNavigationController = navigationController
        
        // Create container view controller that will hold scene and popup overlay
        let containerViewController = UIViewController()
        containerViewController.view.backgroundColor = .black
        
        // Add navigation controller as child
        containerViewController.addChild(navigationController)
        containerViewController.view.addSubview(navigationController.view)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationController.didMove(toParent: containerViewController)
        
        // Add popup overlay as child
        let popupOverlayViewController = PopUpOverlayViewController()
        containerViewController.addChild(popupOverlayViewController)
        containerViewController.view.addSubview(popupOverlayViewController.view)
        popupOverlayViewController.view.translatesAutoresizingMaskIntoConstraints = false
        popupOverlayViewController.didMove(toParent: containerViewController)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Scene view controller constraints
            navigationController.view.topAnchor.constraint(equalTo: containerViewController.view.topAnchor),
            navigationController.view.leadingAnchor.constraint(equalTo: containerViewController.view.leadingAnchor),
            navigationController.view.trailingAnchor.constraint(equalTo: containerViewController.view.trailingAnchor),
            navigationController.view.bottomAnchor.constraint(equalTo: containerViewController.view.bottomAnchor),
            
            // Popup overlay constraints
            popupOverlayViewController.view.topAnchor.constraint(equalTo: containerViewController.view.topAnchor),
            popupOverlayViewController.view.leadingAnchor.constraint(equalTo: containerViewController.view.leadingAnchor),
            popupOverlayViewController.view.trailingAnchor.constraint(equalTo: containerViewController.view.trailingAnchor),
            popupOverlayViewController.view.bottomAnchor.constraint(equalTo: containerViewController.view.bottomAnchor)
        ])
        
        window?.rootViewController = containerViewController
        window?.makeKeyAndVisible()
        
        return true
    }
}
