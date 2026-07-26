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

    func testValidateCombinationSupportsMinusOne() {
        let manager = GameManager()

        let result = manager.validateCombination([
            MockNode.number(4),
            MockNode.item(.minusOne),
            MockNode.number(4)
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
}
