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
}
