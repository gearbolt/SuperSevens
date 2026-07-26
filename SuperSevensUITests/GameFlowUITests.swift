import XCTest

final class GameFlowUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTapSequenceFlowAwardsScoreForAValidSeven() {
        let app = XCUIApplication()
        app.launchEnvironment["SUPERSEVENS_UI_TEST_SCENARIO"] = "scoreSequence"
        app.launch()

        let gameView = app.otherElements["gameView"]
        XCTAssertTrue(gameView.waitForExistence(timeout: 5))

        performDrag(on: gameView, from: CGVector(dx: 0.35, dy: 0.55), to: CGVector(dx: 0.65, dy: 0.55))

        XCTAssertTrue(waitForAccessibilityValue(of: gameView, containing: "score=200"))
        XCTAssertTrue(waitForAccessibilityValue(of: gameView, containing: "state=playing"))
    }

    func testTapSequenceFlowTriggersGameOverWhenSelectionExceedsSeven() {
        let app = XCUIApplication()
        app.launchEnvironment["SUPERSEVENS_UI_TEST_SCENARIO"] = "gameOver"
        app.launch()

        let gameView = app.otherElements["gameView"]
        XCTAssertTrue(gameView.waitForExistence(timeout: 5))

        performDrag(on: gameView, from: CGVector(dx: 0.35, dy: 0.55), to: CGVector(dx: 0.65, dy: 0.55))

        XCTAssertTrue(waitForAccessibilityValue(of: gameView, containing: "state=gameOver"))
    }

    private func performDrag(on element: XCUIElement, from start: CGVector, to end: CGVector) {
        let startCoordinate = element.coordinate(withNormalizedOffset: start)
        let endCoordinate = element.coordinate(withNormalizedOffset: end)
        startCoordinate.press(forDuration: 0.05, thenDragTo: endCoordinate)
    }

    private func waitForAccessibilityValue(
        of element: XCUIElement,
        containing expectedText: String,
        timeout: TimeInterval = 5
    ) -> Bool {
        let predicate = NSPredicate(format: "value CONTAINS %@", expectedText)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
