import SpriteKit

enum GameState: Equatable {
    case playing
    case paused
    case gameOver
}

enum CombinationResult: Equatable {
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
    static let initialLives = 3
    private static let highScoreKey = "superSevens_highScore"

    private(set) var score: Int = 0
    private(set) var gameState: GameState = .playing
    private(set) var highScore: Int
    private(set) var isNewHighScore: Bool = false
    private(set) var lives: Int

    /// Initialises the manager with the given number of lives.
    /// In production the default (`initialLives`) is used; tests may supply 1 to
    /// trigger a full game-over on the first exceed-7 event.
    /// The `SUPERSEVENS_UI_TEST_LIVES` environment variable overrides `lives` when
    /// set, allowing UI-test launch configurations to control the starting life count.
    init(lives: Int = Self.initialLives) {
        let uiTestLives = ProcessInfo.processInfo.environment["SUPERSEVENS_UI_TEST_LIVES"].flatMap(Int.init)
        self.lives = uiTestLives ?? lives
        highScore = UserDefaults.standard.integer(forKey: Self.highScoreKey)
    }

    func pause() {
        guard gameState == .playing else { return }
        gameState = .paused
    }

    func resume() {
        guard gameState == .paused else { return }
        gameState = .playing
    }

    // Evaluates the chain left-to-right and returns the running total.
    // NumberNode values are summed; SpecialItemNodes apply their modifier.
    // Heptagon sets a flag that negates the next NumberNode's value.
    private func evaluate(_ nodes: [GameNode], haltOnExceed: Bool) -> Int {
        evaluateChain(nodes, haltOnExceed: haltOnExceed).total
    }

    func evaluate(_ nodes: [SKNode]) -> Int {
        guard let gameNodes = convertToGameNodes(nodes) else { return 0 }
        return evaluate(gameNodes, haltOnExceed: true)
    }

    // Returns true only when the evaluated total is exactly 7.
    // If the running total exceeds 7 at any point, this returns false and sets game state to game over.
    func validateCombination(_ nodes: [GameNode]) -> Bool {
        guard gameState == .playing else { return false }
        guard !nodes.isEmpty else { return false }
        let evaluation = evaluateChain(nodes, haltOnExceed: true)
        if evaluation.exceeded {
            setGameOver()
            return false
        }
        return evaluation.total == 7
    }

    // Checks the running total of the given nodes mid-selection.
    // If the total exceeds 7, transitions to .gameOver immediately and returns true.
    @discardableResult
    func checkMidSelectionTotal(_ nodes: [SKNode]) -> Bool {
        guard gameState == .playing, !nodes.isEmpty else { return false }
        guard let gameNodes = convertToGameNodes(nodes) else { return false }
        let result = evaluateChain(gameNodes, haltOnExceed: true)
        if result.exceeded {
            setGameOver()
            return true
        }
        return false
    }

    private func evaluateChain(_ nodes: [GameNode], haltOnExceed: Bool) -> (total: Int, exceeded: Bool) {
        var total = 0
        var negateNext = false

        for node in nodes {
            // Exactly one of the two properties must be non-nil (XOR).
            assert(
                (node.nodeNumberValue != nil) != (node.nodeSpecialItemType != nil),
                "GameNode invariant violated: exactly one of nodeNumberValue or nodeSpecialItemType must be non-nil"
            )

            if let numberValue = node.nodeNumberValue {
                let contribution = negateNext ? -numberValue : numberValue
                total += contribution
                negateNext = false
            } else if let itemType = node.nodeSpecialItemType {
                switch itemType {
                case .star:
                    // Wildcard: sets the running total to exactly 7, regardless of current value.
                    total = 7
                case .multiplier:
                    total *= 2
                case .multiplierThree:
                    total *= 3
                case .minusOne:
                    total -= 1
                case .divisionByTwo:
                    total /= 2
                case .heptagon:
                    negateNext = true
                }
            }

            if total > 7 && haltOnExceed {
                return (total, true)
            }
        }

        return (total, false)
    }

    // Submits the combination. Returns .success if total == 7 (score awarded),
    // .exceeded if total > 7 (life lost, or game over if lives exhausted), or .invalid otherwise.
    @discardableResult
    func submitCombination(_ nodes: [SKNode]) -> CombinationResult {
        guard gameState == .playing, !nodes.isEmpty else { return .invalid }
        guard let gameNodes = convertToGameNodes(nodes) else { return .invalid }
        let previousLives = lives
        if validateCombination(gameNodes) {
            score += score(for: gameNodes)
            return .success
        } else if gameState == .gameOver || lives < previousLives {
            return .exceeded
        }
        return .invalid
    }

    func reset() {
        score = 0
        lives = Self.initialLives
        gameState = .playing
        isNewHighScore = false
    }

    private func setGameOver() {
        lives -= 1
        guard lives <= 0 else { return }
        isNewHighScore = score > highScore
        if isNewHighScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: Self.highScoreKey)
        }
        gameState = .gameOver
    }

    func score(for nodes: [GameNode]) -> Int {
        let multiplierBonus = nodes
            .compactMap(\.nodeSpecialItemType)
            .compactMap(\.scoreMultiplier)
            .reduce(1, *)
        return 100 * nodes.count * multiplierBonus
    }

    private func convertToGameNodes(_ nodes: [SKNode]) -> [GameNode]? {
        let gameNodes = nodes.compactMap { $0 as? GameNode }
        guard gameNodes.count == nodes.count else {
            let invalidTypes = nodes
                .filter { !($0 is GameNode) }
                .map { String(describing: type(of: $0)) }
                .joined(separator: ", ")
            assertionFailure("Received non-GameNode nodes: \(invalidTypes)")
            return nil
        }
        return gameNodes
    }
}
