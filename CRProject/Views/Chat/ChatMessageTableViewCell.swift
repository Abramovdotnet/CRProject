import UIKit

class ChatMessageTableViewCell: UITableViewCell {
    static let identifier = "ChatMessageTableViewCell"
    
    private let messageLabel = UILabel()
    private let containerView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        // Setup container view for padding
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Setup message label
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.backgroundColor = .clear
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Container view with vertical padding
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 1),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1),
            
            // Message label fills container
            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    func configure(with message: ChatMessage, viewModel: ChatViewModel) {
        let isPlayer = message.player != nil
        let attributedString = viewModel.buildAttributedString(for: message, isPlayer: isPlayer)
        
        messageLabel.attributedText = attributedString
        
        // Add subtle appearance animation for new messages
        animateAppearance()
    }
    
    private func animateAppearance() {
        // Only animate if this is a newly added cell
        guard alpha < 1.0 || transform.ty > 0 else { return }
        
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 10)
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.2,
            options: [.curveEaseOut],
            animations: {
                self.alpha = 1
                self.transform = .identity
            },
            completion: nil
        )
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.attributedText = nil
        alpha = 1
        transform = .identity
    }
} 