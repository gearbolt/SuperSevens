import SpriteKit

final class SpawnerManager {
    weak var scene: SKScene?
    var baseSpawnInterval: TimeInterval {
        didSet {
            Self.validate(baseSpawnInterval: baseSpawnInterval, minimumSpawnInterval: minimumSpawnInterval)
            baseSpawnIntervalReciprocal = 1.0 / baseSpawnInterval
        }
    }
    var minimumSpawnInterval: TimeInterval {
        didSet {
            Self.validate(baseSpawnInterval: baseSpawnInterval, minimumSpawnInterval: minimumSpawnInterval)
        }
    }
    var specialSpawnProbability: Double {
        didSet {
            Self.validate(specialSpawnProbability: specialSpawnProbability)
        }
    }

    private let spawnMargin: CGFloat = 36
    private let baseFallDuration: TimeInterval = 6
    private let spawnNodePrefix = "spawned_"
    private let offscreenRemovalY: CGFloat = -120
    private let minimumSpeedScale: TimeInterval = 0.6
    private let maxTimeReduction: TimeInterval = 0.55
    private let timeReductionRate: TimeInterval = 0.005
    private let maxScoreReduction: TimeInterval = 0.35
    private let scoreReductionRate: TimeInterval = 0.01
    private var baseSpawnIntervalReciprocal: TimeInterval
    private var lastSpawnTime: TimeInterval?
    private var spawnStartTime: TimeInterval?
    private var isSpawning = false

    init(
        scene: SKScene,
        baseSpawnInterval: TimeInterval = 1.2,
        minimumSpawnInterval: TimeInterval = 0.35,
        specialSpawnProbability: Double = 0.15
    ) {
        Self.validate(baseSpawnInterval: baseSpawnInterval, minimumSpawnInterval: minimumSpawnInterval)
        Self.validate(specialSpawnProbability: specialSpawnProbability)
        self.scene = scene
        self.baseSpawnInterval = baseSpawnInterval
        self.minimumSpawnInterval = minimumSpawnInterval
        self.specialSpawnProbability = specialSpawnProbability
        self.baseSpawnIntervalReciprocal = 1.0 / baseSpawnInterval
    }

    func startSpawning() {
        isSpawning = true
        lastSpawnTime = nil
        spawnStartTime = nil
    }

    func stopSpawning() {
        isSpawning = false
    }

    func update(currentTime: TimeInterval, score: Int) {
        guard isSpawning else { return }

        guard let previousSpawnTime = lastSpawnTime else {
            spawnStartTime = currentTime
            lastSpawnTime = currentTime
            return
        }

        let elapsedTime = currentTime - (spawnStartTime ?? currentTime)
        let interval = currentSpawnInterval(elapsedTime: elapsedTime, score: score)
        if currentTime - previousSpawnTime >= interval {
            lastSpawnTime = currentTime
            spawnItem(interval: interval)
        }
    }

    func removeTappedNodes(at point: CGPoint) -> Bool {
        guard let scene else { return false }

        let tappedSpawnedNodes = scene.nodes(at: point).filter { node in
            node.name?.hasPrefix(spawnNodePrefix) == true
        }

        guard tappedSpawnedNodes.isEmpty == false else { return false }
        tappedSpawnedNodes.forEach { node in
            node.removeAllActions()
            node.removeFromParent()
        }
        return true
    }

    func cleanupOutOfBoundsNodes() {
        guard let scene else { return }

        scene.children
            .filter { $0.name?.hasPrefix(spawnNodePrefix) == true && $0.position.y < offscreenRemovalY }
            .forEach { node in
                node.removeAllActions()
                node.removeFromParent()
            }
    }

    private func currentSpawnInterval(elapsedTime: TimeInterval, score: Int) -> TimeInterval {
        let timeReduction = min(maxTimeReduction, elapsedTime * timeReductionRate)
        let scoreReduction = min(maxScoreReduction, TimeInterval(score) * scoreReductionRate)
        return max(minimumSpawnInterval, baseSpawnInterval - timeReduction - scoreReduction)
    }

    private func spawnItem(interval: TimeInterval) {
        guard let scene else { return }
        precondition(scene.size.width >= spawnMargin * 2, "Scene width must be at least twice the spawn margin.")

        let minX = spawnMargin
        let maxX = scene.size.width - spawnMargin
        let x = CGFloat.random(in: minX...maxX)
        let y = scene.size.height + 80

        let node: SKNode
        if Double.random(in: 0...1) < specialSpawnProbability {
            let itemTypes = SpecialItemType.allCases
            let itemType = itemTypes.randomElement()!
            node = SpecialItemNode(itemType: itemType)
        } else {
            let value = Int.random(in: NumberNode.validRange)
            node = NumberNode(value: value)
        }

        node.name = "\(spawnNodePrefix)\(UUID().uuidString)"
        node.position = CGPoint(x: x, y: y)
        scene.addChild(node)

        let speedScale = max(minimumSpeedScale, interval * baseSpawnIntervalReciprocal)
        let duration = baseFallDuration * speedScale
        let moveDown = SKAction.moveTo(y: offscreenRemovalY, duration: duration)
        let cleanup = SKAction.removeFromParent()
        node.run(.sequence([moveDown, cleanup]))
    }

    private static func validate(baseSpawnInterval: TimeInterval, minimumSpawnInterval: TimeInterval) {
        precondition(baseSpawnInterval > 0, "baseSpawnInterval must be greater than zero.")
        precondition(minimumSpawnInterval > 0, "minimumSpawnInterval must be greater than zero.")
        precondition(
            minimumSpawnInterval <= baseSpawnInterval,
            "minimumSpawnInterval must be less than or equal to baseSpawnInterval."
        )
    }

    private static func validate(specialSpawnProbability: Double) {
        precondition(
            (0...1).contains(specialSpawnProbability),
            "specialSpawnProbability must be between 0 and 1."
        )
    }
}
