import UIKit

protocol CommunityCardButtonDelegate: AnyObject {
    func communityCardButton(_ button: CommunityCardButton, didSelectCard card: String) -> Bool
    func getUnavailableCards(for button: CommunityCardButton) -> Set<String>
}

class CommunityCardButton: UIButton {
    weak var delegate: CommunityCardButtonDelegate?
    private var selectedCard: String = "-"
    private let values = ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]
    private let suits = ["♠️", "♥️", "♦️", "♣️"]
    var isHoleCard: Bool = false {
        didSet {
            backgroundColor = isHoleCard ? UIColor.systemBlue.withAlphaComponent(0.15) : .systemGray6
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = isHoleCard ? UIColor.systemBlue.withAlphaComponent(0.15) : .systemGray6
        layer.cornerRadius = 8
        titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        setTitle("-", for: .normal)
        setTitleColor(.label, for: .normal)
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    @objc private func buttonTapped() {
        let cardPickerVC = CardPickerViewController()
        cardPickerVC.modalPresentationStyle = .pageSheet
        if let sheet = cardPickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        cardPickerVC.selectedCard = selectedCard
        cardPickerVC.delegate = self
        
        // Получаем список недоступных карт от делегата
        if let delegate = delegate {
            cardPickerVC.unavailableCards = delegate.getUnavailableCards(for: self)
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(cardPickerVC, animated: true)
        }
    }
    
    func setCard(_ card: String) {
        let oldCard = selectedCard
        
        // Попытка установить новую карту
        if let delegate = delegate {
            if delegate.communityCardButton(self, didSelectCard: card) {
                // Делегат подтвердил выбор, устанавливаем карту
                selectedCard = card
                setTitle(card, for: .normal)
            } else {
                // Делегат отклонил выбор, возвращаем старую карту
                selectedCard = oldCard
                setTitle(oldCard, for: .normal)
            }
        } else {
            // Нет делегата, устанавливаем без проверки
            selectedCard = card
            setTitle(card, for: .normal)
        }
    }
    
    var currentCard: String {
        return selectedCard
    }
}

// MARK: - CardPickerViewController
class CardPickerViewController: UIViewController {
    weak var delegate: CommunityCardButton?
    var selectedCard: String = "-"
    var unavailableCards: Set<String> = []
    
    private let values = ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]
    private let suits = ["♠️", "♥️", "♦️", "♣️"]
    
    private let scrollView = UIScrollView()
    private let cardTable = UIStackView()
    private let containerView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Настройка контейнера
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Информационный лейбл
        let infoLabel = UILabel()
        infoLabel.text = "Выберите карту. Перечеркнутые карты уже используются."
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.textColor = .secondaryLabel
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(infoLabel)
        
        // Настройка ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = true
        containerView.addSubview(scrollView)
        
        // Настройка таблицы
        cardTable.axis = .vertical
        cardTable.spacing = 12
        cardTable.distribution = .fillEqually
        cardTable.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(cardTable)
        
        // Добавляем строки для каждой масти
        for suit in suits {
            let row = createCardRow(values: values.map { $0 + suit })
            cardTable.addArrangedSubview(row)
        }
        
        // Констрейнты
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            infoLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            scrollView.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            cardTable.topAnchor.constraint(equalTo: scrollView.topAnchor),
            cardTable.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            cardTable.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            cardTable.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            cardTable.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        // Добавляем кнопку закрытия
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Закрыть", for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func createCardRow(values: [String]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually
        
        for value in values {
            let button = UIButton(type: .system)
            button.setTitle(value, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
            
            // Проверяем доступность карты
            let isAvailable = !unavailableCards.contains(value)
            if isAvailable {
                button.backgroundColor = .systemGray5
                button.setTitleColor(.label, for: .normal)
                button.alpha = 1.0
                button.isEnabled = true
            } else {
                button.backgroundColor = .systemGray2
                button.setTitleColor(.systemGray, for: .normal)
                button.alpha = 0.5
                button.isEnabled = false
                
                // Добавляем визуальную индикацию недоступности
                button.layer.borderWidth = 2
                button.layer.borderColor = UIColor.systemRed.cgColor
                
                // Добавляем перечеркивание
                let strikeView = UIView()
                strikeView.backgroundColor = .systemRed
                strikeView.translatesAutoresizingMaskIntoConstraints = false
                button.addSubview(strikeView)
                
                NSLayoutConstraint.activate([
                    strikeView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                    strikeView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                    strikeView.widthAnchor.constraint(equalTo: button.widthAnchor, multiplier: 0.8),
                    strikeView.heightAnchor.constraint(equalToConstant: 3)
                ])
                
                // Поворачиваем полосу под углом
                strikeView.transform = CGAffineTransform(rotationAngle: .pi / 4)
            }
            
            button.layer.cornerRadius = 12
            button.addTarget(self, action: #selector(cardSelected(_:)), for: .touchUpInside)
            
            let buttonSize = 70
            button.widthAnchor.constraint(equalToConstant: CGFloat(buttonSize)).isActive = true
            button.heightAnchor.constraint(equalToConstant: CGFloat(buttonSize)).isActive = true
            
            row.addArrangedSubview(button)
        }
        
        return row
    }
    
    @objc private func cardSelected(_ sender: UIButton) {
        if let card = sender.title(for: .normal) {
            delegate?.setCard(card)
            dismiss(animated: true)
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
} 