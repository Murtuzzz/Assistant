import UIKit

protocol RadialActionMenuDelegate: AnyObject {
    func radialMenu(_ menu: RadialActionMenu, didSelectAction action: PlayerAction, amount: Int?, forPosition position: Position)
    func radialMenu(_ menu: RadialActionMenu, didRequestRemoval position: Position)
}

class RadialActionMenu: UIView {
    weak var delegate: RadialActionMenuDelegate?
    var position: Position
    private let centerButton = UIButton(type: .system)
    private let actionButtons: [UIButton]
    private let actions: [PlayerAction] = [.check, .fold, .raise, .bet, .call]
    private var isExpanded = false
    private let radius: CGFloat = 80
    private let buttonSize: CGFloat = 50
    var selectedAction: PlayerAction?
    var selectedAmount: Int?
    
    init(position: Position) {
        self.position = position
        self.actionButtons = actions.map { _ in UIButton(type: .system) }
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        // Center button
        centerButton.setTitle(position.displayName, for: .normal)
        centerButton.backgroundColor = .systemBlue
        centerButton.setTitleColor(.white, for: .normal)
        centerButton.layer.cornerRadius = buttonSize / 2
        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
        addSubview(centerButton)
        
        // Add long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        centerButton.addGestureRecognizer(longPressGesture)
        
        // Action buttons
        for (index, button) in actionButtons.enumerated() {
            button.setTitle(actions[index].displayName, for: .normal)
            button.backgroundColor = .systemGray5
            button.layer.cornerRadius = buttonSize / 2
            button.alpha = 0
            button.tag = index
            button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
            addSubview(button)
        }
        
        // Layout
        centerButton.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        centerButton.center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        for (index, button) in actionButtons.enumerated() {
            button.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
            button.center = centerButton.center
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        centerButton.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    @objc private func centerButtonTapped() {
        isExpanded.toggle()
        
        if isExpanded {
            expandMenu()
        } else {
            collapseMenu()
        }
    }
    
    private func expandMenu() {
        for (index, button) in actionButtons.enumerated() {
            let angle = (2 * .pi * CGFloat(index)) / CGFloat(actions.count)
            let x = centerButton.center.x + radius * cos(angle)
            let y = centerButton.center.y + radius * sin(angle)
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                button.center = CGPoint(x: x, y: y)
                button.alpha = 1
            }
        }
    }
    
    private func collapseMenu() {
        for button in actionButtons {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                button.center = self.centerButton.center
                button.alpha = 0
            }
        }
    }
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        let action = actions[sender.tag]
        
        if action == .raise || action == .bet || action == .call {
            showAmountInput(for: action)
        } else {
            delegate?.radialMenu(self, didSelectAction: action, amount: nil, forPosition: position)
            collapseMenu()
            isExpanded = false
        }
    }
    
    private func showAmountInput(for action: PlayerAction) {
        let alert = UIAlertController(title: "Введите сумму", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.keyboardType = .numberPad
            textField.placeholder = "Сумма"
        }
        
        let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self,
                  let amountText = alert.textFields?.first?.text,
                  let amount = Int(amountText) else { return }
            
            self.delegate?.radialMenu(self, didSelectAction: action, amount: amount, forPosition: self.position)
            self.collapseMenu()
            self.isExpanded = false
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
    
    func updateCenterButton(with action: PlayerAction, amount: Int?) {
        selectedAction = action
        selectedAmount = amount
        
        var title = action.displayName
        if let amount = amount {
            title += " \(amount)"
        }
        
        centerButton.setTitle(title, for: .normal)
        centerButton.backgroundColor = .systemGreen
    }
    
    func updatePosition(_ newPosition: Position) {
        position = newPosition
        centerButton.setTitle(newPosition.displayName, for: .normal)
        centerButton.backgroundColor = .systemBlue
        selectedAction = nil
        selectedAmount = nil
        
        // Сворачиваем меню, если оно было развернуто
        if isExpanded {
            collapseMenu()
            isExpanded = false
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // Показываем алерт с подтверждением удаления
            let alert = UIAlertController(
                title: "Удалить игрока?",
                message: "Вы уверены, что хотите удалить игрока на позиции \(position.displayName)?",
                preferredStyle: .alert
            )
            
            let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.radialMenu(self, didRequestRemoval: self.position)
            }
            
            let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
            
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let viewController = windowScene.windows.first?.rootViewController {
                viewController.present(alert, animated: true)
            }
        }
    }
    
    func setCenterButtonHighlight(_ highlighted: Bool) {
        if highlighted {
            centerButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.18)
            centerButton.layer.borderColor = UIColor.systemOrange.cgColor
            centerButton.layer.borderWidth = 3
        } else {
            centerButton.backgroundColor = .systemBlue
            centerButton.layer.borderWidth = 0
        }
    }
} 
