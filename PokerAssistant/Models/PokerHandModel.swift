import Foundation

enum Position: String, CaseIterable, Codable {
    case utg = "UTG"
    case mp = "MP"
    case co = "CO"
    case btn = "BTN"
    case sb = "SB"
    case bb = "BB"
    
    var displayName: String {
        switch self {
        case .utg: return "Под пистолетом"
        case .mp: return "Средняя позиция"
        case .co: return "Кат-офф"
        case .btn: return "Батон"
        case .sb: return "Малый блайнд"
        case .bb: return "Большой блайнд"
        }
    }
    
    // Получить доступные позиции для определенного количества игроков
    static func availablePositions(for playerCount: Int) -> [Position] {
        switch playerCount {
        case 2:
            return [.sb, .bb] // Heads-up: только блайнды
        case 3:
            return [.btn, .sb, .bb] // Трое: батон + блайнды
        case 4:
            return [.co, .btn, .sb, .bb] // Четверо: кат-офф + батон + блайнды
        case 5:
            return [.mp, .co, .btn, .sb, .bb] // Пятеро: средняя + кат-офф + батон + блайнды
        case 6:
            return [.utg, .mp, .co, .btn, .sb, .bb] // Шестеро: все позиции
        default:
            return [.utg, .mp, .co, .btn, .sb, .bb] // По умолчанию все позиции
        }
    }
    
    // Получить позицию по индексу относительно батона (0 = батон)
    static func positionRelativeToButton(index: Int, playerCount: Int) -> Position {
        let positions = availablePositions(for: playerCount)
        // Индекс 0 = батон, 1 = малый блайнд, 2 = большой блайнд, и т.д.
        let adjustedIndex = index % positions.count
        return positions[adjustedIndex]
    }
    
    // Получить следующую позицию по часовой стрелке
    func nextPosition(for playerCount: Int) -> Position {
        let positions = Position.availablePositions(for: playerCount)
        guard let currentIndex = positions.firstIndex(of: self) else {
            return positions.first ?? .btn
        }
        let nextIndex = (currentIndex + 1) % positions.count
        return positions[nextIndex]
    }
    
    // Проверить, доступна ли позиция для данного количества игроков
    func isAvailable(for playerCount: Int) -> Bool {
        return Position.availablePositions(for: playerCount).contains(self)
    }
}

enum GameStage: String, CaseIterable, Codable {
    case preflop = "Префлоп"
    case flop = "Флоп"
    case turn = "Тёрн"
    case river = "Ривер"
}

struct Blinds: Codable {
    let small: Int
    let big: Int
}

enum PlayerAction: String, Codable, CaseIterable {
    case check = "Check"
    case fold = "Fold"
    case raise = "Raise"
    case bet = "Bet"
    case call = "Call"
    
    var displayName: String {
        switch self {
        case .check: return "Чек"
        case .fold: return "Фолд"
        case .raise: return "Рейз"
        case .bet: return "Бет"
        case .call: return "Колл"
        }
    }
}

struct PlayerActionInfo: Codable {
    let action: PlayerAction
    let amount: Int?
    let position: Position
}

struct PokerHandModel: Codable {
    var holeCards: [String]
    var communityCards: [String]
    var position: Position
    var playerStacks: [Int]
    var myStack: Int
    var blinds: Blinds
    var ante: Int
    var gameStage: GameStage
    var potSize: Int
    var playerActions: [PlayerActionInfo] = []
    
    var toJSON: [String: Any] {
        return [
            "hole_cards": holeCards,
            "community_cards": communityCards,
            "position": position.rawValue,
            "player_stacks": playerStacks,
            "my_stack": myStack,
            "blinds": ["small": blinds.small, "big": blinds.big],
            "ante": ante,
            "game_stage": gameStage.rawValue,
            "pot_size": potSize,
            "player_actions": playerActions.map { [
                "action": $0.action.rawValue,
                "amount": $0.amount as Any,
                "position": $0.position.rawValue
            ]}
        ]
    }

    func toUserPrompt() -> String {
        let hole = holeCards.joined(separator: " ")
        let community = communityCards.isEmpty ? "-" : communityCards.joined(separator: " ")
        let stacks = playerStacks.map { String($0) }.joined(separator: ", ")
        let blinds = "Малый блайнд: \(blinds.small), Большой блайнд: \(blinds.big)"
        let actions = playerActions.map { action in
            if let amount = action.amount {
                return "\(action.position.displayName): \(action.action.displayName) \(amount)"
            } else {
                return "\(action.position.displayName): \(action.action.displayName)"
            }
        }.joined(separator: ", ")
        return "Карманные карты: \(hole), общие карты: \(community), позиция: \(position.displayName), стеки: \(stacks), мой стек: \(myStack), \(blinds), анте: \(ante), стадия: \(gameStage.rawValue), банк: \(potSize), действия: \(actions)"
    }
} 