import UIKit
import Combine

class ChatViewController: UIViewController {
    private let viewModel: ChatViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // UI Elements
    private let tableView = UITableView()
    private let headerInfoView = SimpleInfoView()
    
    init(viewModel: ChatViewModel = ChatViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apply combat log style to the chat view
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.8
        view.layer.shadowRadius = 8
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.clipsToBounds = false
        
        setupHeaderInfoView()
        setupTableView()
        setupObservers()
    }
    
    private func setupHeaderInfoView() {
        headerInfoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerInfoView)
        NSLayoutConstraint.activate([
            headerInfoView.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            headerInfoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            headerInfoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            headerInfoView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInsetAdjustmentBehavior = .never
        
        tableView.register(ChatMessageTableViewCell.self, forCellReuseIdentifier: ChatMessageTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerInfoView.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupObservers() {
        viewModel.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMessages()
            }
            .store(in: &cancellables)
    }
    
    private func updateMessages() {
        let wasAtBottom = isTableViewAtBottom()
        
        tableView.reloadData()
        
        // Auto-scroll to bottom if was already at bottom or if this is a new message
        if wasAtBottom || tableView.numberOfRows(inSection: 0) == 1 {
            scrollToBottom(animated: true)
        }
    }
    
    private func isTableViewAtBottom() -> Bool {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return true }
        
        let lastRow = tableView.numberOfRows(inSection: 0) - 1
        let lastIndexPath = IndexPath(row: lastRow, section: 0)
        
        return tableView.indexPathsForVisibleRows?.contains(lastIndexPath) ?? false
    }
    
    private func scrollToBottom(animated: Bool) {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return }
        
        let lastRow = tableView.numberOfRows(inSection: 0) - 1
        let lastIndexPath = IndexPath(row: lastRow, section: 0)
        
        tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
    }
    
    // MARK: - Public Methods
    
    func addMessage(message: String? = nil, type: MessageType) {
        viewModel.addMessage(message: message, type: type)
    }
    
    func addMessageWithIcon(
        message: String? = nil,
        type: MessageType,
        location: String? = nil,
        primaryNPC: NPC? = nil,
        player: Player? = nil,
        secondaryNPC: NPC? = nil,
        interactionType: NPCInteraction? = nil,
        hasSuccess: Bool = false,
        isSuccess: Bool? = nil,
        isDiscussion: Bool = false,
        messageLocation: String? = nil,
        rumorInteractionType: NPCInteraction? = nil,
        rumorPrimaryNPC: NPC? = nil,
        rumorSecondaryNPC: NPC? = nil
    ) {
        viewModel.addMessageWithIcon(
            message: message,
            type: type,
            location: location,
            primaryNPC: primaryNPC,
            player: player,
            secondaryNPC: secondaryNPC,
            interactionType: interactionType,
            hasSuccess: hasSuccess,
            isSuccess: isSuccess,
            isDiscussion: isDiscussion,
            messageLocation: messageLocation,
            rumorInteractionType: rumorInteractionType,
            rumorPrimaryNPC: rumorPrimaryNPC,
            rumorSecondaryNPC: rumorSecondaryNPC
        )
    }
    
    func clearChatHistory() {
        viewModel.clearChatHistory()
    }
    
    func updateHeaderInfo(locationName: String, locationIcon: String, locationColor: UIColor, npcCount: Int) {
        headerInfoView.configure(with: [
            (icon: locationIcon, color: locationColor, text: locationName),
            (icon: "person.3.fill", color: UIColor.systemRed, text: "\(npcCount)")
        ], font: UIFont(name: "Optima", size: 10) ?? UIFont.systemFont(ofSize: 10))
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageTableViewCell.identifier, for: indexPath) as? ChatMessageTableViewCell else {
            return UITableViewCell()
        }
        
        let message = viewModel.messages[indexPath.row]
        cell.configure(with: message, viewModel: viewModel)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 20
    }
} 