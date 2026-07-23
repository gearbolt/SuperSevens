import SpriteKit

final class SpawnerManager {
    weak var scene: SKScene?
    var baseSpawnInterval: TimeInterval
    var minimumSpawnInterval: TimeInterval
    var specialSpawnProbability: Double

    private let spawnMargin: CGFloat = 36
    private let baseFallDuration: TimeInterval = 6
    private let spawnNodePrefix = "spawned_"
    private var lastSpawnTime: TimeInterval = 0
    private var isSpawning = false

    init(
        scene: SKScene,
        baseSpawnInterval: TimeInterval = 1.2,
        minimumSpawnInterval: TimeInterval = 0.35,
        specialSpawnProbability: Double = 0.15
    ) {
        self.scene = scene
        self.baseSpawnInterval = baseSpawnInterval
        self.minimumSpawnInterval = minimumSpawnInterval
        self.specialSpawnProbability = specialSpawnProbability
    }

    func startSpawning() {
        isSpawning = true
        lastSpawnTime = 0
    }

    func stopSpawning() {
        isSpawning = false
    }

    func update(currentTime: TimeInterval, score: Int) {
        guard isSpawning else { return }

        if lastSpawnTime == 0 {
            lastSpawnTime = currentTime
            spawnItem(at: currentTime, score: score)
            return
        }

        let interval = currentSpawnInterval(currentTime: currentTime, score: score)
        if currentTime - lastSpawnTime >= interval {
            lastSpawnTime = currentTime
            spawnItem(at: currentTime, score: score)
        }
    }

    func removeTappedNode(at point: CGPoint) -> Bool {
        guard let scene else { return false }

        let tappedSpawnedNodes = scene.nodes(at: point).filter { node in
            node.name?.hasPrefix(spawnNodePrefix) == true
        }

        guard let node = tappedSpawnedNodes.first else { return false }
        node.removeAllActions()
        node.removeFromParent()
        return true
    }

    func cleanupOutOfBoundsNodes() {
        guard let scene else { return }
        let minY = -120.0

        scene.children
            .filter { $0.name?.hasPrefix(spawnNodePrefix) == true && $0.position.y < minY }
            .forEach { node in
                node.removeAllActions()
                node.removeFromParent()
            }
    }

    private func currentSpawnInterval(currentTime: TimeInterval, score: Int) -> TimeInterval {
        let timeReduction = min(0.55, currentTime * 0.005)
        let scoreReduction = min(0.35, Double(score) * 0.01)
        return max(minimumSpawnInterval, baseSpawnInterval - timeReduction - scoreReduction)
    }

    private func spawnItem(at currentTime: TimeInterval, score: Int) {
        guard let scene else { return }

        let maxX = max(spawnMargin, scene.size.width - spawnMargin)
        let x = CGFloat.random(in: spawnMargin...maxX)
        let y = scene.size.height + 80

        let node: SKNode
        if Double.random(in: 0...1) < specialSpawnProbability {
            let itemType = SpecialItemType.allCases.randomElement() ?? .star
            node = SpecialItemNode(itemType: itemType)
        } else {
            let value = Int.random(in: 1...6)
            node = NumberNode(value: value)
        }

        node.name = "\(spawnNodePrefix)\(UUID().uuidString)"
        node.position = CGPoint(x: x, y: y)
        scene.addChild(node)

        let speedScale = max(0.6, currentSpawnInterval(currentTime: currentTime, score: score) / baseSpawnInterval)
        let duration = baseFallDuration * speedScale
        let moveDown = SKAction.moveTo(y: -120, duration: duration)
        let cleanup = SKAction.removeFromParent()
        node.run(.sequence([moveDown, cleanup]))
    }
}
