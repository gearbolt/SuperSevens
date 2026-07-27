import SpriteKit

@MainActor
final class SpawnerManager {
    static let spawnNodePrefix = "spawned_"
    static let offscreenRemovalY: CGFloat = -120
    static let spawnYOffset: CGFloat = 80

    static func totalTravelDistance(forSceneHeight sceneHeight: CGFloat) -> CGFloat {
        sceneHeight + spawnYOffset + abs(offscreenRemovalY)
    }

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
    private let minimumSpeedScale: TimeInterval = 0.6
    private let maxTimeReduction: TimeInterval = 0.55
    private let timeReductionRate: TimeInterval = 0.005
    private let maxScoreReduction: TimeInterval = 0.35
    private let scoreReductionRate: TimeInterval = 0.01
    private var baseSpawnIntervalReciprocal: TimeInterval
    private var lastSpawnTime: TimeInterval?
    private var spawnStartTime: TimeInterval?
    private var isSpawning = false
    private var nextSpawnedNodeID: UInt64 = 0
    private var pooledNumberNodes: [Int: [NumberNode]] = [:]
    private var pooledSpecialItemNodes: [SpecialItemType: [SpecialItemNode]] = [:]

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
            node.name?.hasPrefix(Self.spawnNodePrefix) == true
        }

        guard tappedSpawnedNodes.isEmpty == false else { return false }
        recycleSpawnedNodes(tappedSpawnedNodes)
        return true
    }

    func cleanupOutOfBoundsNodes() {
        guard let scene else { return }

        scene.children
            .filter {
                $0.name?.hasPrefix(Self.spawnNodePrefix) == true &&
                $0.position.y < Self.offscreenRemovalY
            }
            //.forEach(recycle)
            .forEach { node in _ = recycle(node)
            }
    }

    func currentSpawnInterval(elapsedTime: TimeInterval, score: Int) -> TimeInterval {
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
        let y = scene.size.height + Self.spawnYOffset

        let node: SKNode
        if shouldSpawnSpecial(randomValue: Double.random(in: 0...1)) {
            let totalWeight = SpecialItemType.allCases.reduce(0.0) { $0 + $1.spawnWeight }
            let itemType = weightedRandomSpecialItemType(randomValue: Double.random(in: 0..<totalWeight))
            node = dequeueSpecialItemNode(itemType: itemType)
        } else {
            node = dequeueNumberNode(value: Int.random(in: NumberNode.validRange))
        }

        prepareSpawnedNode(node, position: CGPoint(x: x, y: y))
        scene.addChild(node)
        SoundManager.shared.playNodeSpawn()

        let speedScale = max(minimumSpeedScale, interval * baseSpawnIntervalReciprocal)
        let duration = baseFallDuration * speedScale
        let moveDown = SKAction.moveTo(y: Self.offscreenRemovalY, duration: duration)
        let cleanup = recycleAction(for: node)
        node.run(.sequence([moveDown, cleanup]))
    }

    func shouldSpawnSpecial(randomValue: Double) -> Bool {
        randomValue < specialSpawnProbability
    }

    /// Selects a `SpecialItemType` using weighted probabilities based on each type's `spawnWeight`.
    /// - Parameter randomValue: A value in `[0, totalWeight)` used to make the selection deterministic in tests.
    func weightedRandomSpecialItemType(randomValue: Double) -> SpecialItemType {
        let types = SpecialItemType.allCases
        var cumulative = 0.0
        for itemType in types {
            cumulative += itemType.spawnWeight
            if randomValue < cumulative {
                return itemType
            }
        }
        return types.last!
    }

    func dequeueNumberNode(value: Int) -> NumberNode {
        var pooledNodes = pooledNumberNodes[value] ?? []
        let node = pooledNodes.popLast() ?? NumberNode(value: value)
        pooledNumberNodes[value] = pooledNodes
        node.prepareForReuse()
        return node
    }

    func dequeueSpecialItemNode(itemType: SpecialItemType) -> SpecialItemNode {
        var pooledNodes = pooledSpecialItemNodes[itemType] ?? []
        let node = pooledNodes.popLast() ?? SpecialItemNode(itemType: itemType)
        pooledSpecialItemNodes[itemType] = pooledNodes
        node.prepareForReuse()
        return node
    }

    @discardableResult
    func recycle(_ node: SKNode?) -> Bool {
        guard let node else { return false }
        guard node.name?.hasPrefix(Self.spawnNodePrefix) == true else { return false }

        switch node {
        case let numberNode as NumberNode:
            numberNode.removeAllActions()
            numberNode.removeFromParent()
            pooledNumberNodes[numberNode.value, default: []].append(numberNode)
            return true
        case let specialNode as SpecialItemNode:
            specialNode.removeAllActions()
            specialNode.removeFromParent()
            pooledSpecialItemNodes[specialNode.itemType, default: []].append(specialNode)
            return true
        default:
            return false
        }
    }

    //func recycleSpawnedNodes(_ nodes: [SKNode]) {
      //  nodes.forEach(recycle)
    //}

    func recycleSpawnedNodes(_ nodes: [SKNode]) {
        nodes.forEach { node in
            _ = recycle(node)
        }
    }
    
    func recycleAction(for node: SKNode) -> SKAction {
        SKAction.run { [weak self, weak node] in
            self?.recycle(node)
        }
    }

    func prepareSpawnedNode(_ node: SKNode, position: CGPoint) {
        node.removeAllActions()
        node.alpha = 1
        node.xScale = 1
        node.yScale = 1
        node.zRotation = 0
        node.name = nextSpawnNodeName()
        node.position = position
    }

    private func nextSpawnNodeName() -> String {
        defer { nextSpawnedNodeID += 1 }
        return "\(Self.spawnNodePrefix)\(nextSpawnedNodeID)"
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
