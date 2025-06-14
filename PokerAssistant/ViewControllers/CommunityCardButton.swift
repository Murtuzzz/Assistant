import UIKit

protocol CommunityCardButtonDelegate: AnyObject {
    func communityCardButton(_ button: CommunityCardButton, didSelectCard card: String)
}

class CommunityCardButton: UIButton {
    weak var delegate: CommunityCardButtonDelegate?
    private var selectedCard: String = "-"
    private let values = ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]
    private let suits = ["♠️", "♥️", "♦️", "♣️"]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .systemGray6
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
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(cardPickerVC, animated: true)
        }
    }
    
    func setCard(_ card: String) {
        selectedCard = card
        setTitle(card, for: .normal)
        delegate?.communityCardButton(self, didSelectCard: card)
    }
    
    var currentCard: String {
        return selectedCard
    }
}

// MARK: - CardPickerViewController
class CardPickerViewController: UIViewController {
    weak var delegate: CommunityCardButton?
    var selectedCard: String = "-"
    
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
            
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
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
            button.backgroundColor = .systemGray5
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