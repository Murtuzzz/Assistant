import UIKit

class PokerHandViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let apiService = PokerAPIService()
    
    // MARK: - UI Components
    private let holeCard1Button = CommunityCardButton()
    private let holeCard2Button = CommunityCardButton()
    private let communityCardButtons = [CommunityCardButton(), CommunityCardButton(), CommunityCardButton(), CommunityCardButton(), CommunityCardButton()]
    private let positionStack = UIStackView()
    private let stageStack = UIStackView()
    private let playerStacksStack = UIStackView()
    //private let addStackButton = UIButton(type: .contactAdd)
    private let myStackTextField = UITextField()
    private let potSizeTextField = UITextField()
    private let analyzeButton = UIButton(type: .system)
    private let recommendationLabel = UILabel()
    private let explanationLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    private let playerActionsContainer = UIView()
    private let tableBackgroundView = UIView()
    private var radialMenus: [RadialActionMenu] = []
    private var playerActions: [PlayerActionInfo] = []
    
    private var currentPosition: Position = .utg
    private var currentGameStage: GameStage = .preflop
    private var playerStackFields: [UITextField] = []
    private var menuToStackField: [RadialActionMenu: UITextField] = [:]
    
    private let addPlayerButton = UIButton(type: .system)
    private let maxPlayers = 6 // Максимальное количество игроков
    
    private var smallBlind: Int = 0
    private var bigBlind: Int = 0
    
    // Глобальная валидация карт
    private var selectedCards: Set<String> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupPlayerActions()
        initializeSelectedCards()
        presentBlindsAlert()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMenuLayout()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Покер Ассистент"
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Карманные карты (как кнопки)
        holeCard1Button.translatesAutoresizingMaskIntoConstraints = false
        holeCard2Button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(holeCard1Button)
        contentView.addSubview(holeCard2Button)
        holeCard1Button.delegate = self
        holeCard2Button.delegate = self
        holeCard1Button.isHoleCard = true
        holeCard2Button.isHoleCard = true
        
        // Перемещаем community cards в контейнер игроков
        for button in communityCardButtons {
            button.translatesAutoresizingMaskIntoConstraints = false
            playerActionsContainer.addSubview(button)
        }
        
        // Позиция (горизонтальный stack) - будет обновляться при изменении количества игроков
        positionStack.axis = .horizontal
        positionStack.spacing = 8
        positionStack.distribution = .fillEqually
        positionStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(positionStack)
        updatePositionButtons()
        
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
//        addStackButton.addTarget(self, action: #selector(addPlayerStack), for: .touchUpInside)
//        contentView.addSubview(addStackButton)
        
        // Добавляем одно начальное поле для стека игрока
        addPlayerStack()
        
        // Мой стек
        myStackTextField.placeholder = "Мой стек"
        myStackTextField.borderStyle = .roundedRect
        myStackTextField.keyboardType = .numberPad
        myStackTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(myStackTextField)
        
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
        
        // Player Actions Container
        playerActionsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(playerActionsContainer)
        
        // Poker table background
        tableBackgroundView.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0) // насыщенный зелёный
        tableBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        tableBackgroundView.layer.borderWidth = 5
        tableBackgroundView.layer.borderColor = UIColor.systemBrown.cgColor
        playerActionsContainer.addSubview(tableBackgroundView)
        
        // Add Player Button
        addPlayerButton.setTitle("Добавить игрока", for: .normal)
        addPlayerButton.addTarget(self, action: #selector(addPlayerTapped), for: .touchUpInside)
        addPlayerButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(addPlayerButton)
        
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
            
            // Hole Cards (по половине экрана, как кнопки)
            holeCard1Button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            holeCard1Button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            holeCard1Button.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            holeCard1Button.heightAnchor.constraint(equalToConstant: 80),
            
            holeCard2Button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            holeCard2Button.leadingAnchor.constraint(equalTo: holeCard1Button.trailingAnchor),
            holeCard2Button.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            holeCard2Button.heightAnchor.constraint(equalToConstant: 80),
            
            // Position Stack
            positionStack.topAnchor.constraint(equalTo: holeCard1Button.bottomAnchor, constant: 20),
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
            
            // Pot Size
            potSizeTextField.topAnchor.constraint(equalTo: myStackTextField.bottomAnchor, constant: 16),
            potSizeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            potSizeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Player Actions Container
            playerActionsContainer.topAnchor.constraint(equalTo: potSizeTextField.bottomAnchor, constant: 16),
            playerActionsContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playerActionsContainer.heightAnchor.constraint(equalToConstant: 280),
            playerActionsContainer.widthAnchor.constraint(equalToConstant: 400),
            
            // Community Cards в центре
            communityCardButtons[0].centerXAnchor.constraint(equalTo: playerActionsContainer.centerXAnchor, constant: -80),
            communityCardButtons[0].centerYAnchor.constraint(equalTo: playerActionsContainer.centerYAnchor),
            
            // Pot Size
            potSizeTextField.topAnchor.constraint(equalTo: myStackTextField.bottomAnchor, constant: 16),
            potSizeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            potSizeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            communityCardButtons[1].centerXAnchor.constraint(equalTo: playerActionsContainer.centerXAnchor, constant: -40),
            communityCardButtons[1].centerYAnchor.constraint(equalTo: playerActionsContainer.centerYAnchor),
            
            communityCardButtons[2].centerXAnchor.constraint(equalTo: playerActionsContainer.centerXAnchor),
            communityCardButtons[2].centerYAnchor.constraint(equalTo: playerActionsContainer.centerYAnchor),
            
            communityCardButtons[3].centerXAnchor.constraint(equalTo: playerActionsContainer.centerXAnchor, constant: 40),
            communityCardButtons[3].centerYAnchor.constraint(equalTo: playerActionsContainer.centerYAnchor),
            
            communityCardButtons[4].centerXAnchor.constraint(equalTo: playerActionsContainer.centerXAnchor, constant: 80),
            communityCardButtons[4].centerYAnchor.constraint(equalTo: playerActionsContainer.centerYAnchor),
            
            // Add Player Button
            addPlayerButton.topAnchor.constraint(equalTo: playerActionsContainer.bottomAnchor, constant: 8),
            addPlayerButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Analyze Button
            analyzeButton.topAnchor.constraint(equalTo: addPlayerButton.bottomAnchor, constant: 24),
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
    
    private func setupPlayerActions() {
        // Clear existing menus
        radialMenus.forEach { $0.removeFromSuperview() }
        radialMenus.removeAll()
        
        // Создаем начальные меню для двух игроков (heads-up)
        let availablePositions = Position.availablePositions(for: 2)
        currentPosition = availablePositions.first ?? .sb
        
        let userMenu = RadialActionMenu(position: currentPosition)
        userMenu.delegate = self
        userMenu.translatesAutoresizingMaskIntoConstraints = false
        playerActionsContainer.addSubview(userMenu)
        radialMenus.append(userMenu)
        
        // Оппонент получает следующую позицию
        let nextPosition = availablePositions.count > 1 ? availablePositions[1] : availablePositions[0]
        let opponentMenu = RadialActionMenu(position: nextPosition)
        opponentMenu.delegate = self
        opponentMenu.translatesAutoresizingMaskIntoConstraints = false
        playerActionsContainer.addSubview(opponentMenu)
        radialMenus.append(opponentMenu)
        
        // Обновляем кнопки позиций
        updatePositionButtons()
        // Initial layout
        updateMenuLayout()
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
        let holeCards = [holeCard1Button.currentCard, holeCard2Button.currentCard]
        if holeCards.contains(where: { $0.count != 2 }) {
            showAlert(message: "Пожалуйста, выберите две карманные карты")
            return nil
        }
        
        // Дополнительная проверка на дубликаты карт
        let allCards = holeCards + communityCardButtons.map { $0.currentCard }.filter { $0 != "-" }
        let uniqueCards = Set(allCards)
        if allCards.count != uniqueCards.count {
            showAlert(message: "Обнаружены дублирующиеся карты! Проверьте выбранные карты.")
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
        
        // Validate pot size
        guard let potSizeText = potSizeTextField.text,
              let potSize = Int(potSizeText) else {
            showAlert(message: "Пожалуйста, введите корректный размер банка")
            return nil
        }
        
        // Collect player actions
        let playerActions = radialMenus.compactMap { menu -> PlayerActionInfo? in
            guard let action = menu.selectedAction else { return nil }
            return PlayerActionInfo(action: action, amount: menu.selectedAmount, position: menu.position)
        }
        
        return PokerHandModel(
            holeCards: holeCards,
            communityCards: communityCards,
            position: currentPosition,
            playerStacks: playerStacks,
            myStack: myStack,
            blinds: Blinds(small: smallBlind, big: bigBlind),
            ante: 0,
            gameStage: currentGameStage,
            potSize: potSize,
            playerActions: playerActions
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
        // Не связываем с меню, т.к. это поле для первого игрока (ваше)
    }
    
    private func updatePositionButtons() {
        // Удаляем старые кнопки
        positionStack.arrangedSubviews.forEach { view in
            positionStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        let playerCount = radialMenus.count
        let availablePositions = Position.availablePositions(for: playerCount)
        
        // Проверяем, доступна ли текущая позиция для нового количества игроков
        if !currentPosition.isAvailable(for: playerCount) {
            currentPosition = availablePositions.first ?? .btn
        }
        
        // Создаем кнопки для доступных позиций
        for (index, pos) in availablePositions.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(pos.displayName, for: .normal)
            btn.tag = index
            btn.addTarget(self, action: #selector(positionSelected(_:)), for: .touchUpInside)
            
            // Выделяем текущую позицию
            if pos == currentPosition {
                btn.backgroundColor = .systemBlue
                btn.setTitleColor(.white, for: .normal)
            } else {
                btn.backgroundColor = .clear
                btn.setTitleColor(.systemBlue, for: .normal)
            }
            
            positionStack.addArrangedSubview(btn)
        }
    }
    
    @objc private func positionSelected(_ sender: UIButton) {
        let idx = sender.tag
        let playerCount = radialMenus.count
        let availablePositions = Position.availablePositions(for: playerCount)
        guard idx < availablePositions.count else { return }
        currentPosition = availablePositions[idx]
        
        for (i, btn) in positionStack.arrangedSubviews.enumerated() {
            (btn as? UIButton)?.backgroundColor = (i == idx) ? .systemBlue : .clear
            (btn as? UIButton)?.setTitleColor((i == idx) ? .white : .systemBlue, for: .normal)
        }
        
        // Обновляем позиции у всех RadialActionMenu
        updateMenuPositions()
        updateMenuLayout()
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
    
    @objc private func addPlayerTapped() {
        guard radialMenus.count < maxPlayers else {
            showAlert(message: "Достигнуто максимальное количество игроков")
            return
        }
        
        // Определяем позицию для нового игрока
        let newPlayerCount = radialMenus.count + 1
        let availablePositions = Position.availablePositions(for: newPlayerCount)
        
        // Если текущая позиция недоступна для нового количества игроков, меняем её
        if !currentPosition.isAvailable(for: newPlayerCount) {
            currentPosition = availablePositions.first ?? .btn
        }
        
        // Позиция нового игрока будет назначена в updateMenuPositions
        let tempPosition = availablePositions.last ?? .bb
        
        // Создаем новое меню
        let menu = RadialActionMenu(position: tempPosition)
        menu.delegate = self
        menu.translatesAutoresizingMaskIntoConstraints = false
        playerActionsContainer.addSubview(menu)
        radialMenus.append(menu)
        
        // Добавляем новое поле для стека и связываем с меню
        let tf = UITextField()
        tf.placeholder = "Стек игрока"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.translatesAutoresizingMaskIntoConstraints = false
        playerStacksStack.addArrangedSubview(tf)
        playerStackFields.append(tf)
        menuToStackField[menu] = tf
        
        // Обновляем кнопки позиций и позиции игроков
        updatePositionButtons()
        updateMenuPositions()
        // Обновляем layout
        updateMenuLayout()
    }
    
    private func updateMenuLayout() {
        // Удаляем старые констрейнты
        radialMenus.forEach { $0.removeFromSuperview() }
        playerActionsContainer.subviews.forEach { $0.removeFromSuperview() }
        
        // Добавляем фон стола первым (под всеми)
        playerActionsContainer.addSubview(tableBackgroundView)
        
        // Добавляем меню обратно
        for (i, menu) in radialMenus.enumerated() {
            playerActionsContainer.addSubview(menu)
            // Первый (ваш) — выделяем только центральную кнопку
            if i == 0 {
                menu.setCenterButtonHighlight(true)
            } else {
                menu.setCenterButtonHighlight(false)
            }
        }
        
        // Добавляем community cards обратно
        for button in communityCardButtons {
            playerActionsContainer.addSubview(button)
        }
        
        // Центр круга
        let centerX = playerActionsContainer.bounds.width / 2
        let centerY = playerActionsContainer.bounds.height / 2
        let radius: CGFloat = 120 // Уменьшенный радиус
        
        // Размер и форма стола (овал)
        let tableWidth = radius * 2 + 120
        let tableHeight = radius * 1.3 + 100
        tableBackgroundView.frame = CGRect(
            x: centerX - tableWidth/2,
            y: centerY - tableHeight/2,
            width: tableWidth,
            height: tableHeight
        )
        tableBackgroundView.layer.cornerRadius = tableHeight/2
        tableBackgroundView.layer.masksToBounds = true
        
        // Обновляем констрейнты для кругового расположения
        for (index, menu) in radialMenus.enumerated() {
            let angle = (2 * .pi * CGFloat(index)) / CGFloat(radialMenus.count)
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            
            NSLayoutConstraint.activate([
                menu.widthAnchor.constraint(equalToConstant: 150), // Уменьшенный размер меню
                menu.heightAnchor.constraint(equalToConstant: 150), // Уменьшенный размер меню
                menu.centerXAnchor.constraint(equalTo: playerActionsContainer.leadingAnchor, constant: x),
                menu.centerYAnchor.constraint(equalTo: playerActionsContainer.topAnchor, constant: y)
            ])
        }
        
        // Обновляем констрейнты для community cards
        NSLayoutConstraint.activate([
            communityCardButtons[0].centerXAnchor.constraint(equalTo: playerActionsContainer.centerXAnchor, constant: -80),
            communityCardButtons[0].centerYAnchor.constraint(equalTo: playerActionsContainer.centerYAnchor),
            
            communityCardButtons[1].centerXAnchor.constraint(equalTo: playerActionsContainer.centerXAnchor, constant: -40),
            communityCardButtons[1].centerYAnchor.constraint(equalTo: playerActionsContainer.centerYAnchor),
            
            communityCardButtons[2].centerXAnchor.constraint(equalTo: playerActionsContainer.centerXAnchor),
            communityCardButtons[2].centerYAnchor.constraint(equalTo: playerActionsContainer.centerYAnchor),
            
            communityCardButtons[3].centerXAnchor.constraint(equalTo: playerActionsContainer.centerXAnchor, constant: 40),
            communityCardButtons[3].centerYAnchor.constraint(equalTo: playerActionsContainer.centerYAnchor),
            
            communityCardButtons[4].centerXAnchor.constraint(equalTo: playerActionsContainer.centerXAnchor, constant: 80),
            communityCardButtons[4].centerYAnchor.constraint(equalTo: playerActionsContainer.centerYAnchor)
        ])
        
        // Обновляем размер контейнера
        let containerSize = radius * 2 + 150 // Диаметр + размер меню
        playerActionsContainer.widthAnchor.constraint(equalToConstant: containerSize).isActive = true
        playerActionsContainer.heightAnchor.constraint(equalToConstant: containerSize).isActive = true
    }
    
    private func updateMenuPositions() {
        let playerCount = radialMenus.count
        let availablePositions = Position.availablePositions(for: playerCount)
        
        // Первый игрок (вы) — выбранная позиция
        if !radialMenus.isEmpty {
            radialMenus[0].updatePosition(currentPosition)
        }
        
        // Остальные игроки — следующие позиции по кругу
        guard let currentIndex = availablePositions.firstIndex(of: currentPosition) else { return }
        
        for i in 1..<radialMenus.count {
            let positionIndex = (currentIndex + i) % availablePositions.count
            let position = availablePositions[positionIndex]
            radialMenus[i].updatePosition(position)
        }
    }
    
    private func presentBlindsAlert() {
        let alert = UIAlertController(title: "Введите блайнды", message: "Укажите размеры малого и большого блайнда", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Малый блайнд"
            textField.keyboardType = .numberPad
        }
        alert.addTextField { textField in
            textField.placeholder = "Большой блайнд"
            textField.keyboardType = .numberPad
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let smallText = alert.textFields?[0].text ?? ""
            let bigText = alert.textFields?[1].text ?? ""
            if let small = Int(smallText), let big = Int(bigText), small > 0, big > 0 {
                self.smallBlind = small
                self.bigBlind = big
            } else {
                self.showAlert(message: "Пожалуйста, введите корректные значения блайндов")
                self.presentBlindsAlert()
            }
        }
        alert.addAction(okAction)
        alert.preferredAction = okAction
        present(alert, animated: true)
    }
    
    // MARK: - Card Validation
    private func isCardAvailable(_ card: String) -> Bool {
        return !selectedCards.contains(card) && card != "-"
    }
    
    private func addSelectedCard(_ card: String, for button: CommunityCardButton) -> Bool {
        // Удаляем предыдущую карту этой кнопки, если была
        let previousCard = button.currentCard
        if previousCard != "-" {
            selectedCards.remove(previousCard)
        }
        
        // Проверяем доступность новой карты
        if card == "-" {
            return true // Разрешаем сброс карты
        }
        
        if selectedCards.contains(card) {
            // Карта уже выбрана, показываем ошибку
            let location = findCardLocation(card)
            showAlert(message: "Карта \(card) уже выбрана в \(location)!")
            return false
        }
        
        // Добавляем новую карту
        selectedCards.insert(card)
        return true
    }
    
    private func removeSelectedCard(_ card: String) {
        selectedCards.remove(card)
    }
    
    private func updateAllCardButtons() {
        // Обновляем доступность карт во всех кнопках
        // Это потребует модификации CommunityCardButton для поддержки disabled состояний
    }
    
    private func initializeSelectedCards() {
        // Инициализируем список выбранных карт начальными значениями
        selectedCards.removeAll()
        
        // Добавляем карты из hole cards, если они установлены
        let holeCard1 = holeCard1Button.currentCard
        let holeCard2 = holeCard2Button.currentCard
        
        if holeCard1 != "-" {
            selectedCards.insert(holeCard1)
        }
        if holeCard2 != "-" {
            selectedCards.insert(holeCard2)
        }
        
        // Добавляем карты из community cards, если они установлены
        for button in communityCardButtons {
            let card = button.currentCard
            if card != "-" {
                selectedCards.insert(card)
            }
        }
    }
    
    private func findCardLocation(_ card: String) -> String {
        // Проверяем hole cards
        if holeCard1Button.currentCard == card {
            return "первой карте в руке"
        }
        if holeCard2Button.currentCard == card {
            return "второй карте в руке"
        }
        
        // Проверяем community cards
        for (index, button) in communityCardButtons.enumerated() {
            if button.currentCard == card {
                switch index {
                case 0: return "первой общей карте"
                case 1: return "второй общей карте"
                case 2: return "третьей общей карте"
                case 3: return "четвертой общей карте"
                case 4: return "пятой общей карте"
                default: return "общих картах"
                }
            }
        }
        
        return "другом месте"
    }
    
    private func resetAllCards() {
        // Очищаем список выбранных карт
        selectedCards.removeAll()
        
        // Сбрасываем hole cards
        holeCard1Button.setCard("-")
        holeCard2Button.setCard("-")
        
        // Сбрасываем community cards
        for button in communityCardButtons {
            button.setCard("-")
        }
    }
    
    // Дополнительная валидация при анализе
    private func validateAllCards() -> Bool {
        let allCards = [holeCard1Button.currentCard, holeCard2Button.currentCard] +
                      communityCardButtons.map { $0.currentCard }
        
        let nonEmptyCards = allCards.filter { $0 != "-" }
        let uniqueCards = Set(nonEmptyCards)
        
        return nonEmptyCards.count == uniqueCards.count
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
    func communityCardButton(_ button: CommunityCardButton, didSelectCard card: String) -> Bool {
        // Проверяем валидность выбранной карты
        if addSelectedCard(card, for: button) {
            // Карта прошла валидацию, обновляем интерфейс
            if communityCardButtons.contains(button) {
                updateCommunityCardButtonsVisibility()
            }
            return true
        } else {
            // Валидация не прошла, возвращаем предыдущую карту
            return false
        }
    }
    
    func getUnavailableCards(for button: CommunityCardButton) -> Set<String> {
        // Возвращаем все выбранные карты, кроме карты текущей кнопки
        var unavailable = selectedCards
        let currentCard = button.currentCard
        if currentCard != "-" {
            unavailable.remove(currentCard)
        }
        return unavailable
    }
}

// MARK: - RadialActionMenuDelegate
extension PokerHandViewController: RadialActionMenuDelegate {
    func radialMenu(_ menu: RadialActionMenu, didSelectAction action: PlayerAction, amount: Int?, forPosition position: Position) {
        let actionInfo = PlayerActionInfo(action: action, amount: amount, position: position)
        
        // Remove any existing action for this position
        playerActions.removeAll { $0.position == position }
        
        // Add the new action
        playerActions.append(actionInfo)
        
        // Update the center button to show the selected action
        menu.updateCenterButton(with: action, amount: amount)
    }
    
    func radialMenu(_ menu: RadialActionMenu, didRequestRemoval position: Position) {
        // Удаляем меню
        if let index = radialMenus.firstIndex(where: { $0 === menu }) {
            radialMenus.remove(at: index)
            menu.removeFromSuperview()
            
            // Удаляем действие этого игрока
            playerActions.removeAll { $0.position == position }
            
            // Удаляем соответствующий стек
            if let tf = menuToStackField[menu], let tfIndex = playerStackFields.firstIndex(of: tf) {
                playerStackFields.remove(at: tfIndex)
                tf.removeFromSuperview()
                menuToStackField.removeValue(forKey: menu)
            }
            
            // Обновляем кнопки позиций и позиции оставшихся игроков
            updatePositionButtons()
            updateMenuPositions()
            // Обновляем layout
            updateMenuLayout()
        }
    }
} 
