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

protocol GameNode {
    var nodeNumberValue: Int? { get }
    var nodeSpecialItemType: SpecialItemType? { get }
}

extension NumberNode: GameNode {
    var nodeNumberValue: Int? { value }
    var nodeSpecialItemType: SpecialItemType? { nil }
}

extension SpecialItemNode: GameNode {
    var nodeNumberValue: Int? { nil }
    var nodeSpecialItemType: SpecialItemType? { itemType }
}

final class GameManager {
    private(set) var score: Int = 0
    private(set) var gameState: GameState = .playing

    // Evaluates the chain left-to-right and returns the running total.
    // NumberNode values are summed; SpecialItemNodes apply their modifier.
    // Heptagon sets a flag that negates the next NumberNode's value.
    func evaluate(_ nodes: [GameNode], stopOnExceed: Bool = true) -> Int {
        evaluateChain(nodes, stopOnExceed: stopOnExceed).total
    }

    func evaluate(_ nodes: [SKNode]) -> Int {
        evaluate(nodes.compactMap { $0 as? GameNode })
    }

    func validateCombination(_ nodes: [GameNode]) -> Bool {
        guard gameState == .playing else { return false }
        guard !nodes.isEmpty else { return false }
        let evaluation = evaluateChain(nodes, stopOnExceed: true)
        if evaluation.exceeded {
            gameState = .gameOver
            return false
        }
        return evaluation.total == 7
    }

    private func evaluateChain(_ nodes: [GameNode], stopOnExceed: Bool) -> (total: Int, exceeded: Bool) {
        var total = 0
        var negateNext = false

        for node in nodes {
            if let numberValue = node.nodeNumberValue {
                let contribution = negateNext ? -numberValue : numberValue
                total += contribution
                negateNext = false
            } else if let itemType = node.nodeSpecialItemType {
                switch itemType {
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

            if total > 7 && stopOnExceed {
                return (total, true)
            }
        }

        return (total, false)
    }

    // Submits the combination. Returns .success if total == 7 (score awarded),
    // .exceeded if total > 7 (game over triggered), or .invalid otherwise.
    @discardableResult
    func submitCombination(_ nodes: [SKNode]) -> CombinationResult {
        guard gameState == .playing, !nodes.isEmpty else { return .invalid }
        guard let gameNodes = convertToGameNodes(nodes) else { return .invalid }
        if validateCombination(gameNodes) {
            score += scoreForChain(gameNodes)
            return .success
        } else if gameState == .gameOver {
            return .exceeded
        }
        return .invalid
    }

    func reset() {
        score = 0
        gameState = .playing
    }

    private func scoreForChain(_ nodes: [GameNode]) -> Int {
        let multiplierCount = nodes
            .compactMap(\.nodeSpecialItemType)
            .filter { $0 == .multiplier }
            .count
        let bonus = multiplierCount > 0 ? multiplierCount * 2 : 1
        return 100 * nodes.count * bonus
    }

    private func convertToGameNodes(_ nodes: [SKNode]) -> [GameNode]? {
        let gameNodes = nodes.compactMap { $0 as? GameNode }
        guard gameNodes.count == nodes.count else {
            let invalidTypes = nodes
                .filter { !($0 is GameNode) }
                .map { String(describing: type(of: $0)) }
                .joined(separator: ", ")
            assertionFailure("submitCombination received non-GameNode nodes: \(invalidTypes)")
            return nil
        }
        return gameNodes
    }
}
