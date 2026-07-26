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

    func testValidateCombinationSupportsStar() {
        let manager = GameManager()

        let result = manager.validateCombination([
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
        let manager = GameManager()

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

        let manager = GameManager()

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
}
