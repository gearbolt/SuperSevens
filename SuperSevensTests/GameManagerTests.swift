import XCTest
@testable import SuperSevens

final class GameManagerTests: XCTestCase {
    private struct MockNode: GameNode {
        let nodeNumberValue: Int?
        let nodeSpecialItemType: SpecialItemType?

        static func number(_ value: Int) -> MockNode {
            MockNode(nodeNumberValue: value, nodeSpecialItemType: nil)
        }

        static func item(_ type: SpecialItemType) -> MockNode {
            MockNode(nodeNumberValue: nil, nodeSpecialItemType: type)
        }
    }

    func testValidateCombinationSupportsPureAddition() {
        let manager = GameManager()

        let result = manager.validateCombination([
            MockNode.number(3),
            MockNode.number(4)
        ])

        XCTAssertTrue(result)
        XCTAssertEqual(manager.gameState, .playing)
    }

    func testValidateCombinationSupportsMultiplier() {
        let manager = GameManager()

        let result = manager.validateCombination([
            MockNode.number(2),
            MockNode.number(1),
            MockNode.item(.multiplier),
            MockNode.number(1)
        ])

        XCTAssertTrue(result)
    }

    func testValidateCombinationSupportsMultiplierThree() {
        let manager = GameManager()

        // 1 × 3 + 4 = 7
        let result = manager.validateCombination([
            MockNode.number(1),
            MockNode.item(.multiplierThree),
            MockNode.number(4)
        ])

        XCTAssertTrue(result)
    }

    func testValidateCombinationSupportsStar() {
        let manager = GameManager()

        let result = manager.validateCombination([
            MockNode.item(.star)
        ])

        XCTAssertTrue(result)
    }

    func testValidateCombinationSupportsStarAsWildcard() {
        let manager = GameManager()

        // Star acts as a wildcard, setting the total to exactly 7.
        let result = manager.validateCombination([
            MockNode.number(3),
            MockNode.item(.star)
        ])

        XCTAssertTrue(result)
    }

    func testValidateCombinationSupportsMinusOne() {
        let manager = GameManager()

        let result = manager.validateCombination([
            MockNode.number(4),
            MockNode.item(.minusOne),
            MockNode.number(4)
        ])

        XCTAssertTrue(result)
    }

    func testValidateCombinationSupportsHeptagonNegation() {
        let manager = GameManager()

        let result = manager.validateCombination([
            MockNode.number(6),
            MockNode.item(.heptagon),
            MockNode.number(1),
            MockNode.number(2)
        ])

        XCTAssertTrue(result)
    }

    func testValidateCombinationSupportsDivisionByTwo() {
        let manager = GameManager()

        let result = manager.validateCombination([
            MockNode.number(6),
            MockNode.item(.divisionByTwo),
            MockNode.number(4)
        ])

        XCTAssertTrue(result)
    }

    func testValidateCombinationSupportsModifierFirstOrdering() {
        let manager = GameManager()

        let result = manager.validateCombination([
            MockNode.item(.minusOne),
            MockNode.number(6),
            MockNode.number(2)
        ])

        XCTAssertTrue(result)
    }

    func testValidateCombinationTriggersGameOverWhenExceedsSevenMidCombination() {
        let manager = GameManager(lives: 1)

        let result = manager.validateCombination([
            MockNode.number(4),
            MockNode.number(4),
            MockNode.item(.minusOne)
        ])

        XCTAssertFalse(result)
        XCTAssertEqual(manager.gameState, .gameOver)
    }

    func testIsNewHighScoreIsFalseWhenGameOverWithZeroScore() {
        let key = "superSevens_highScore"
        UserDefaults.standard.removeObject(forKey: key)
        defer { UserDefaults.standard.removeObject(forKey: key) }

        let manager = GameManager(lives: 1)

        _ = manager.validateCombination([
            MockNode.number(4),
            MockNode.number(4)
        ])

        XCTAssertEqual(manager.gameState, .gameOver)
        XCTAssertFalse(manager.isNewHighScore)
    }

    func testResetClearsIsNewHighScore() {
        let manager = GameManager()
        _ = manager.validateCombination([MockNode.number(4), MockNode.number(4)])

        manager.reset()

        XCTAssertFalse(manager.isNewHighScore)
        XCTAssertEqual(manager.gameState, .playing)
    }

    func testHighScoreIsLoadedFromUserDefaults() {
        let key = "superSevens_highScore"
        UserDefaults.standard.set(999, forKey: key)
        defer { UserDefaults.standard.removeObject(forKey: key) }

        let manager = GameManager()

        XCTAssertEqual(manager.highScore, 999)
    }

    func testScoreCalculationUsesChainLengthWithoutMultiplierBonus() {
        let manager = GameManager()

        let score = manager.score(for: [
            MockNode.number(3),
            MockNode.number(4)
        ])

        XCTAssertEqual(score, 200)
    }

    func testScoreCalculationAppliesMultiplierBonusPerMultiplierNode() {
        let manager = GameManager()

        let score = manager.score(for: [
            MockNode.number(1),
            MockNode.item(.multiplier),
            MockNode.number(1),
            MockNode.item(.multiplier),
            MockNode.number(1)
        ])

        XCTAssertEqual(score, 2_000)
    }

    func testScoreCalculationAppliesMultiplierThreeBonus() {
        let manager = GameManager()

        // 3 nodes × ×3 bonus = 100 × 3 × 3 = 900
        let score = manager.score(for: [
            MockNode.number(1),
            MockNode.item(.multiplierThree),
            MockNode.number(6)
        ])

        XCTAssertEqual(score, 900)
    }

    func testSubmitCombinationAwardsCalculatedScore() {
        let manager = GameManager()
        let nodes: [SKNode] = [
            NumberNode(value: 3),
            NumberNode(value: 4)
        ]

        let result = manager.submitCombination(nodes)

        XCTAssertEqual(result, .success)
        XCTAssertEqual(manager.score, 200)
    }

    // MARK: - Lives tests

    func testExceedingSevenDecrementsLivesWithoutFullGameOver() {
        let manager = GameManager()

        let result = manager.validateCombination([MockNode.number(4), MockNode.number(4)])

        XCTAssertFalse(result)
        XCTAssertEqual(manager.lives, GameManager.initialLives - 1)
        XCTAssertEqual(manager.gameState, .playing)
    }

    func testGameOverIsTriggeredOnlyWhenAllLivesAreExhausted() {
        let manager = GameManager()
        for _ in 0..<GameManager.initialLives {
            _ = manager.validateCombination([MockNode.number(4), MockNode.number(4)])
        }

        XCTAssertEqual(manager.lives, 0)
        XCTAssertEqual(manager.gameState, .gameOver)
    }

    func testSubmitCombinationReturnsExceededWhenLivesRemainingAfterOverflow() {
        let manager = GameManager()
        let nodes: [SKNode] = [NumberNode(value: 4), NumberNode(value: 4)]

        let result = manager.submitCombination(nodes)

        XCTAssertEqual(result, .exceeded)
        XCTAssertEqual(manager.gameState, .playing)
    }

    func testResetRestoresLivesToInitialCount() {
        let manager = GameManager(lives: 1)
        _ = manager.validateCombination([MockNode.number(4), MockNode.number(4)])
        XCTAssertEqual(manager.gameState, .gameOver)

        manager.reset()

        XCTAssertEqual(manager.lives, GameManager.initialLives)
        XCTAssertEqual(manager.gameState, .playing)
    }

    // MARK: - Pause / resume tests

    func testPauseTransitionsStateToPaused() {
        let manager = GameManager()

        manager.pause()

        XCTAssertEqual(manager.gameState, .paused)
    }

    func testResumeRestoresPlayingStateAfterPause() {
        let manager = GameManager()
        manager.pause()

        manager.resume()

        XCTAssertEqual(manager.gameState, .playing)
    }

    func testResumeIsNoOpWhenAlreadyPlaying() {
        let manager = GameManager()

        manager.resume()  // Should be a no-op

        XCTAssertEqual(manager.gameState, .playing)
    }

    func testResumeIsNoOpWhenGameOver() {
        let manager = GameManager(lives: 1)
        _ = manager.validateCombination([MockNode.number(4), MockNode.number(4)])
        XCTAssertEqual(manager.gameState, .gameOver)

        manager.resume()  // Should be a no-op

        XCTAssertEqual(manager.gameState, .gameOver)
    }

    func testPauseIsIgnoredWhenNotPlaying() {
        let manager = GameManager(lives: 1)
        _ = manager.validateCombination([MockNode.number(4), MockNode.number(4)])
        XCTAssertEqual(manager.gameState, .gameOver)

        manager.pause()  // Should be a no-op

        XCTAssertEqual(manager.gameState, .gameOver)
    }
}
