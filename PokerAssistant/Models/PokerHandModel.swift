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
            "pot_size": potSize
        ]
    }

    func toUserPrompt() -> String {
        let hole = holeCards.joined(separator: " ")
        let community = communityCards.isEmpty ? "-" : communityCards.joined(separator: " ")
        let stacks = playerStacks.map { String($0) }.joined(separator: ", ")
        let blinds = "Малый блайнд: \(blinds.small), Большой блайнд: \(blinds.big)"
        return "Карманные карты: \(hole), общие карты: \(community), позиция: \(position.displayName), стеки: \(stacks), мой стек: \(myStack), \(blinds), анте: \(ante), стадия: \(gameStage.rawValue), банк: \(potSize)"
    }
} 