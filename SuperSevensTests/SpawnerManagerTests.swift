import SpriteKit
import XCTest
@testable import SuperSevens

@MainActor
final class SpawnerManagerTests: XCTestCase {
    func testShouldSpawnSpecialUsesConfiguredProbabilityThreshold() {
        let scene = SKScene(size: CGSize(width: 390, height: 844))
        let manager = SpawnerManager(
            scene: scene,
            baseSpawnInterval: 1.2,
            minimumSpawnInterval: 0.35,
            specialSpawnProbability: 0.15
        )

        XCTAssertTrue(manager.shouldSpawnSpecial(randomValue: 0.149))
        XCTAssertFalse(manager.shouldSpawnSpecial(randomValue: 0.15))
        XCTAssertFalse(manager.shouldSpawnSpecial(randomValue: 0.5))
    }

    func testCurrentSpawnIntervalGetsFasterButNeverDropsBelowMinimum() {
        let scene = SKScene(size: CGSize(width: 390, height: 844))
        let manager = SpawnerManager(
            scene: scene,
            baseSpawnInterval: 1.2,
            minimumSpawnInterval: 0.35,
            specialSpawnProbability: 0.15
        )

        let initialInterval = manager.currentSpawnInterval(elapsedTime: 0, score: 0)
        let reducedInterval = manager.currentSpawnInterval(elapsedTime: 30, score: 20)
        let clampedInterval = manager.currentSpawnInterval(elapsedTime: 300, score: 500)

        XCTAssertEqual(initialInterval, 1.2, accuracy: 0.0001)
        XCTAssertLessThan(reducedInterval, initialInterval)
        XCTAssertEqual(clampedInterval, 0.35, accuracy: 0.0001)
    }

    func testRecycledNumberNodesAreReusedFromPool() {
        let scene = SKScene(size: CGSize(width: 390, height: 844))
        let manager = SpawnerManager(scene: scene)

        let originalNode = manager.dequeueNumberNode(value: 5)
        originalNode.name = SpawnerManager.spawnNodePrefix

        XCTAssertTrue(manager.recycle(originalNode))

        let reusedNode = manager.dequeueNumberNode(value: 5)

        XCTAssertTrue(originalNode === reusedNode)
        XCTAssertEqual(reusedNode.alpha, 1)
        XCTAssertEqual(reusedNode.xScale, 1)
        XCTAssertEqual(reusedNode.yScale, 1)
    }

    func testWeightedRandomSpecialItemTypeReturnsCorrectTypeForKnownRanges() {
        let scene = SKScene(size: CGSize(width: 390, height: 844))
        let manager = SpawnerManager(scene: scene)

        // Weights: multiplier=3, multiplierThree=1, star=1, heptagon=2, minusOne=3, divisionByTwo=2
        // Total weight = 12. Cumulative ranges (matching enum order):
        // .multiplier:     [0,  3)
        // .multiplierThree:[3,  4)
        // .star:           [4,  5)
        // .heptagon:       [5,  7)
        // .minusOne:       [7, 10)
        // .divisionByTwo: [10, 12)
        XCTAssertEqual(manager.weightedRandomSpecialItemType(randomValue: 0.0), .multiplier)
        XCTAssertEqual(manager.weightedRandomSpecialItemType(randomValue: 2.9), .multiplier)
        XCTAssertEqual(manager.weightedRandomSpecialItemType(randomValue: 3.0), .multiplierThree)
        XCTAssertEqual(manager.weightedRandomSpecialItemType(randomValue: 4.0), .star)
        XCTAssertEqual(manager.weightedRandomSpecialItemType(randomValue: 5.0), .heptagon)
        XCTAssertEqual(manager.weightedRandomSpecialItemType(randomValue: 7.0), .minusOne)
        XCTAssertEqual(manager.weightedRandomSpecialItemType(randomValue: 10.0), .divisionByTwo)
    }
}
