import UIKit

class PokerHandViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let apiService = PokerAPIService()
    
    // MARK: - UI Components
    private let holeCard1Picker = CardPickerView()
    private let holeCard2Picker = CardPickerView()
    private let communityCardButtons = [CommunityCardButton(), CommunityCardButton(), CommunityCardButton(), CommunityCardButton(), CommunityCardButton()]
    private let positionStack = UIStackView()
    private let stageStack = UIStackView()
    private let playerStacksStack = UIStackView()
    private let addStackButton = UIButton(type: .contactAdd)
    private let myStackTextField = UITextField()
    private let smallBlindTextField = UITextField()
    private let bigBlindTextField = UITextField()
    private let anteTextField = UITextField()
    private let potSizeTextField = UITextField()
    private let analyzeButton = UIButton(type: .system)
    private let recommendationLabel = UILabel()
    private let explanationLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    private var currentPosition: Position = .utg
    private var currentGameStage: GameStage = .preflop
    private var playerStackFields: [UITextField] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Покер Ассистент"
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Карманные карты
        holeCard1Picker.translatesAutoresizingMaskIntoConstraints = false
        holeCard2Picker.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(holeCard1Picker)
        contentView.addSubview(holeCard2Picker)
        
        // Общие карты (кнопки)
        for button in communityCardButtons {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.delegate = self
            contentView.addSubview(button)
        }
        
        // Позиция (горизонтальный stack)
        positionStack.axis = .horizontal
        positionStack.spacing = 8
        positionStack.distribution = .fillEqually
        positionStack.translatesAutoresizingMaskIntoConstraints = false
        for pos in Position.allCases {
            let btn = UIButton(type: .system)
            btn.setTitle(pos.displayName, for: .normal)
            btn.tag = Position.allCases.firstIndex(of: pos) ?? 0
            btn.addTarget(self, action: #selector(positionSelected(_:)), for: .touchUpInside)
            positionStack.addArrangedSubview(btn)
        }
        contentView.addSubview(positionStack)
        
        // Этап игры (горизонтальный stack)
        stageStack.axis = .horizontal
        stageStack.spacing = 8
        stageStack.distribution = .fillEqually
        stageStack.translatesAutoresizingMaskIntoConstraints = false
        for stage in GameStage.allCases {
            let btn = UIButton(type: .system)
            btn.setTitle(stage.rawValue, for: .normal)
            btn.tag = GameStage.allCases.firstIndex(of: stage) ?? 0
            btn.addTarget(self, action: #selector(stageSelected(_:)), for: .touchUpInside)
            stageStack.addArrangedSubview(btn)
        }
        contentView.addSubview(stageStack)
        
        // Стеки игроков (динамический stack)
        playerStacksStack.axis = .vertical
        playerStacksStack.spacing = 4
        playerStacksStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(playerStacksStack)
        addStackButton.addTarget(self, action: #selector(addPlayerStack), for: .touchUpInside)
        contentView.addSubview(addStackButton)
        addPlayerStack() // добавить первое поле
        
        // Мой стек
        myStackTextField.placeholder = "Мой стек"
        myStackTextField.borderStyle = .roundedRect
        myStackTextField.keyboardType = .numberPad
        myStackTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(myStackTextField)
        
        // Блайнды и анте
        smallBlindTextField.placeholder = "Малый блайнд"
        smallBlindTextField.borderStyle = .roundedRect
        smallBlindTextField.keyboardType = .numberPad
        smallBlindTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(smallBlindTextField)
        bigBlindTextField.placeholder = "Большой блайнд"
        bigBlindTextField.borderStyle = .roundedRect
        bigBlindTextField.keyboardType = .numberPad
        bigBlindTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bigBlindTextField)
        anteTextField.placeholder = "Анте"
        anteTextField.borderStyle = .roundedRect
        anteTextField.keyboardType = .numberPad
        anteTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(anteTextField)
        
        // Размер банка
        potSizeTextField.placeholder = "Размер банка"
        potSizeTextField.borderStyle = .roundedRect
        potSizeTextField.keyboardType = .numberPad
        potSizeTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(potSizeTextField)
        
        // Кнопка анализа
        analyzeButton.setTitle("Анализировать раздачу", for: .normal)
        analyzeButton.addTarget(self, action: #selector(analyzeButtonTapped), for: .touchUpInside)
        analyzeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(analyzeButton)
        
        // Лейблы результата
        recommendationLabel.numberOfLines = 0
        explanationLabel.numberOfLines = 0
        recommendationLabel.translatesAutoresizingMaskIntoConstraints = false
        explanationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recommendationLabel)
        contentView.addSubview(explanationLabel)
        
        // Индикатор загрузки
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        contentView.addSubview(activityIndicator)
        
        // Жест для скрытия клавиатуры
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Hole Cards (по половине экрана)
            holeCard1Picker.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            holeCard1Picker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            holeCard1Picker.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            holeCard1Picker.heightAnchor.constraint(equalToConstant: 160),
            
            holeCard2Picker.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            holeCard2Picker.leadingAnchor.constraint(equalTo: holeCard1Picker.trailingAnchor),
            holeCard2Picker.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            holeCard2Picker.heightAnchor.constraint(equalToConstant: 160),
            
            // Community Cards (в одну линию, кнопки)
            communityCardButtons[0].topAnchor.constraint(equalTo: holeCard1Picker.bottomAnchor, constant: 20),
            communityCardButtons[0].leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            communityCardButtons[0].widthAnchor.constraint(equalToConstant: 60),
            communityCardButtons[0].heightAnchor.constraint(equalToConstant: 60),
            
            communityCardButtons[1].topAnchor.constraint(equalTo: holeCard1Picker.bottomAnchor, constant: 20),
            communityCardButtons[1].leadingAnchor.constraint(equalTo: communityCardButtons[0].trailingAnchor, constant: 8),
            communityCardButtons[1].widthAnchor.constraint(equalToConstant: 60),
            communityCardButtons[1].heightAnchor.constraint(equalToConstant: 60),
            
            communityCardButtons[2].topAnchor.constraint(equalTo: holeCard1Picker.bottomAnchor, constant: 20),
            communityCardButtons[2].leadingAnchor.constraint(equalTo: communityCardButtons[1].trailingAnchor, constant: 8),
            communityCardButtons[2].widthAnchor.constraint(equalToConstant: 60),
            communityCardButtons[2].heightAnchor.constraint(equalToConstant: 60),
            
            communityCardButtons[3].topAnchor.constraint(equalTo: holeCard1Picker.bottomAnchor, constant: 20),
            communityCardButtons[3].leadingAnchor.constraint(equalTo: communityCardButtons[2].trailingAnchor, constant: 8),
            communityCardButtons[3].widthAnchor.constraint(equalToConstant: 60),
            communityCardButtons[3].heightAnchor.constraint(equalToConstant: 60),
            
            communityCardButtons[4].topAnchor.constraint(equalTo: holeCard1Picker.bottomAnchor, constant: 20),
            communityCardButtons[4].leadingAnchor.constraint(equalTo: communityCardButtons[3].trailingAnchor, constant: 8),
            communityCardButtons[4].widthAnchor.constraint(equalToConstant: 60),
            communityCardButtons[4].heightAnchor.constraint(equalToConstant: 60),
            
            // Position Stack
            positionStack.topAnchor.constraint(equalTo: communityCardButtons[0].bottomAnchor, constant: 20),
            positionStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            positionStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Stage Stack
            stageStack.topAnchor.constraint(equalTo: positionStack.bottomAnchor, constant: 16),
            stageStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stageStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Player Stacks Stack
            playerStacksStack.topAnchor.constraint(equalTo: stageStack.bottomAnchor, constant: 16),
            playerStacksStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            playerStacksStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // My Stack
            myStackTextField.topAnchor.constraint(equalTo: playerStacksStack.bottomAnchor, constant: 16),
            myStackTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            myStackTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Blinds and Ante
            smallBlindTextField.topAnchor.constraint(equalTo: myStackTextField.bottomAnchor, constant: 16),
            smallBlindTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            smallBlindTextField.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -10),
            
            bigBlindTextField.topAnchor.constraint(equalTo: myStackTextField.bottomAnchor, constant: 16),
            bigBlindTextField.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 10),
            bigBlindTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            anteTextField.topAnchor.constraint(equalTo: smallBlindTextField.bottomAnchor, constant: 16),
            anteTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            anteTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Pot Size
            potSizeTextField.topAnchor.constraint(equalTo: anteTextField.bottomAnchor, constant: 16),
            potSizeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            potSizeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Analyze Button
            analyzeButton.topAnchor.constraint(equalTo: potSizeTextField.bottomAnchor, constant: 24),
            analyzeButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            analyzeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: analyzeButton.bottomAnchor, constant: 20),
            
            // Recommendation Label
            recommendationLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            recommendationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            recommendationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Explanation Label
            explanationLabel.topAnchor.constraint(equalTo: recommendationLabel.bottomAnchor, constant: 16),
            explanationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            explanationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            explanationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func analyzeButtonTapped() {
        guard let hand = createPokerHandModel() else {
            showAlert(message: "Please fill in all required fields")
            return
        }
        
        activityIndicator.startAnimating()
        analyzeButton.isEnabled = false
        
        Task {
            do {
                let response = try await apiService.getRecommendation(for: hand)
                await MainActor.run {
                    recommendationLabel.text = "Recommendation: \(response.recommendation)"
                    explanationLabel.text = "Explanation: \(response.explanation)"
                    activityIndicator.stopAnimating()
                    analyzeButton.isEnabled = true
                }
            } catch {
                await MainActor.run {
                    showAlert(message: "Error: \(error.localizedDescription)")
                    activityIndicator.stopAnimating()
                    analyzeButton.isEnabled = true
                }
            }
        }
    }
    
    private func createPokerHandModel() -> PokerHandModel? {
        // Validate hole cards
        let holeCards = [holeCard1Picker.selectedCard, holeCard2Picker.selectedCard]
        if holeCards.contains(where: { $0.count != 2 }) {
            showAlert(message: "Пожалуйста, выберите две карманные карты")
            return nil
        }
        
        // Parse community cards
        let communityCards = communityCardButtons
            .filter { !$0.isHidden }
            .map { $0.currentCard }
            .filter { $0 != "-" }
        
        // Validate player stacks
        let stacksText = playerStackFields.compactMap { $0.text }.joined(separator: ",")
        guard !stacksText.isEmpty else {
            showAlert(message: "Пожалуйста, введите стеки игроков")
            return nil
        }
        
        let playerStacks = stacksText.split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        
        guard !playerStacks.isEmpty else {
            showAlert(message: "Пожалуйста, введите корректные стеки игроков")
            return nil
        }
        
        // Validate my stack
        guard let myStackText = myStackTextField.text,
              let myStack = Int(myStackText) else {
            showAlert(message: "Пожалуйста, введите корректный размер вашего стека")
            return nil
        }
        
        // Validate blinds
        guard let smallBlindText = smallBlindTextField.text,
              let smallBlind = Int(smallBlindText),
              let bigBlindText = bigBlindTextField.text,
              let bigBlind = Int(bigBlindText) else {
            showAlert(message: "Пожалуйста, введите корректные размеры блайндов")
            return nil
        }
        
        // Validate ante
        guard let anteText = anteTextField.text,
              let ante = Int(anteText) else {
            showAlert(message: "Пожалуйста, введите корректный размер анте")
            return nil
        }
        
        // Validate pot size
        guard let potSizeText = potSizeTextField.text,
              let potSize = Int(potSizeText) else {
            showAlert(message: "Пожалуйста, введите корректный размер банка")
            return nil
        }
        
        return PokerHandModel(
            holeCards: holeCards,
            communityCards: communityCards,
            position: currentPosition,
            playerStacks: playerStacks,
            myStack: myStack,
            blinds: Blinds(small: smallBlind, big: bigBlind),
            ante: ante,
            gameStage: currentGameStage,
            potSize: potSize
        )
    }
    
    private func parseCards(_ text: String) -> [String]? {
        let components = text.split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }
        
        // Validate card format (e.g., Ah, Kd, 7c)
        let cardRegex = "^[2-9TJQKA][hdcs]$"
        let isValid = components.allSatisfy { card in
            card.range(of: cardRegex, options: .regularExpression) != nil
        }
        
        return isValid ? components : nil
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func addPlayerStack() {
        let tf = UITextField()
        tf.placeholder = "Стек игрока"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.translatesAutoresizingMaskIntoConstraints = false
        playerStacksStack.addArrangedSubview(tf)
        playerStackFields.append(tf)
    }
    
    @objc private func positionSelected(_ sender: UIButton) {
        let idx = sender.tag
        currentPosition = Position.allCases[idx]
        for (i, btn) in positionStack.arrangedSubviews.enumerated() {
            (btn as? UIButton)?.backgroundColor = (i == idx) ? .systemBlue : .clear
            (btn as? UIButton)?.setTitleColor((i == idx) ? .white : .systemBlue, for: .normal)
        }
    }
    
    @objc private func stageSelected(_ sender: UIButton) {
        let idx = sender.tag
        currentGameStage = GameStage.allCases[idx]
        for (i, btn) in stageStack.arrangedSubviews.enumerated() {
            (btn as? UIButton)?.backgroundColor = (i == idx) ? .systemBlue : .clear
            (btn as? UIButton)?.setTitleColor((i == idx) ? .white : .systemBlue, for: .normal)
        }
        updateCommunityCardButtonsVisibility()
    }
    
    private func updateCommunityCardButtonsVisibility() {
        let count: Int
        switch currentGameStage {
        case .preflop: count = 0
        case .flop: count = 3
        case .turn: count = 4
        case .river: count = 5
        }
        for (i, button) in communityCardButtons.enumerated() {
            button.isHidden = i >= count
        }
    }
}

// MARK: - UITextFieldDelegate
extension PokerHandViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
}

// MARK: - CommunityCardButtonDelegate
extension PokerHandViewController: CommunityCardButtonDelegate {
    func communityCardButton(_ button: CommunityCardButton, didSelectCard card: String) {
        // Обновляем видимость кнопок в зависимости от стадии игры
        updateCommunityCardButtonsVisibility()
    }
} 