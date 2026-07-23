import SpriteKit

enum GameState {
    case playing
    case gameOver
}

enum CombinationResult {
    case success
    case exceeded
    case invalid
}

final class GameManager {
    private(set) var score: Int = 0
    private(set) var gameState: GameState = .playing

    // Evaluates the chain left-to-right and returns the running total.
    // NumberNode values are summed; SpecialItemNodes apply their modifier.
    // Heptagon sets a flag that negates the next NumberNode's value.
    func evaluate(_ nodes: [SKNode]) -> Int {
        var total = 0
        var negateNext = false

        for node in nodes {
            if let numberNode = node as? NumberNode {
                let contribution = negateNext ? -numberNode.value : numberNode.value
                total += contribution
                negateNext = false
            } else if let specialNode = node as? SpecialItemNode {
                switch specialNode.itemType {
                case .star:
                    total += 7
                case .multiplier:
                    total *= 2
                case .minusOne:
                    total -= 1
                case .divisionByTwo:
                    total /= 2
                case .heptagon:
                    negateNext = true
                }
            }
        }

        return total
    }

    // Submits the combination. Returns .success if total == 7 (score awarded),
    // .exceeded if total > 7 (game over triggered), or .invalid otherwise.
    @discardableResult
    func submitCombination(_ nodes: [SKNode]) -> CombinationResult {
        guard gameState == .playing, !nodes.isEmpty else { return .invalid }
        let total = evaluate(nodes)
        if total == 7 {
            score += scoreForChain(nodes)
            return .success
        } else if total > 7 {
            gameState = .gameOver
            return .exceeded
        }
        return .invalid
    }

    func reset() {
        score = 0
        gameState = .playing
    }

    private func scoreForChain(_ nodes: [SKNode]) -> Int {
        let multiplierCount = nodes.compactMap { $0 as? SpecialItemNode }
            .filter { $0.itemType == .multiplier }
            .count
        let bonus = multiplierCount > 0 ? multiplierCount * 2 : 1
        return 100 * nodes.count * bonus
    }
}
