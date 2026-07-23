//
//  GameScene.swift
//  SuperSevens
//
//  Created by TGO on 7/20/26.
//

import SpriteKit

class GameScene: SKScene {
    private var gameManager = GameManager()
    private var spawnerManager: SpawnerManager?

    private var selectedNodes: [SKNode] = []
    private var lineNode: SKShapeNode?
    private weak var scoreLabel: SKLabelNode?
    private weak var runningTotalLabel: SKLabelNode?
    private weak var gameOverNode: SKNode?

    private static let spawnedPrefix = "spawned_"
    // Must match SpawnerManager.offscreenRemovalY so deselected nodes resume
    // falling to the same threshold used during initial spawn.
    private static let offscreenRemovalY: CGFloat = -120
    // Approximate total travel distance for spawned nodes (scene height + spawn
    // offset above screen + removal threshold below). Used to proportionally
    // scale resumed fall durations.
    private static let baseFallDuration: TimeInterval = 6.0

    override init(size: CGSize) {
        super.init(size: size)
        configureScene()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureScene()
    }

    private func configureScene() {
        backgroundColor = .black
        spawnerManager = SpawnerManager(scene: self, baseSpawnInterval: 1.2)
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupHUD()
        spawnerManager?.startSpawning()
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        spawnerManager?.stopSpawning()
    }

    override func update(_ currentTime: TimeInterval) {
        guard gameManager.gameState == .playing else { return }
        spawnerManager?.update(currentTime: currentTime, score: gameManager.score)
        spawnerManager?.cleanupOutOfBoundsNodes()
    }

    // MARK: - HUD

    private func setupHUD() {
        let scoreNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreNode.fontSize = 24
        scoreNode.fontColor = .white
        scoreNode.horizontalAlignmentMode = .left
        scoreNode.position = CGPoint(x: 20, y: size.height - 50)
        scoreNode.zPosition = 10
        scoreNode.text = "Score: 0"
        scoreNode.name = "scoreLabel"
        addChild(scoreNode)
        scoreLabel = scoreNode

        let totalNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        totalNode.fontSize = 22
        totalNode.fontColor = .yellow
        totalNode.horizontalAlignmentMode = .center
        totalNode.position = CGPoint(x: size.width / 2, y: 60)
        totalNode.zPosition = 10
        totalNode.name = "runningTotalLabel"
        addChild(totalNode)
        runningTotalLabel = totalNode
    }

    private func updateScoreLabel() {
        scoreLabel?.text = "Score: \(gameManager.score)"
    }

    private func updateRunningTotalLabel() {
        guard !selectedNodes.isEmpty else {
            runningTotalLabel?.text = ""
            return
        }
        let total = gameManager.evaluate(selectedNodes)
        runningTotalLabel?.text = "= \(total)"
        runningTotalLabel?.fontColor = total > 7 ? .red : (total == 7 ? .green : .yellow)
    }

    // MARK: - Game Over

    private func showGameOver() {
        spawnerManager?.stopSpawning()

        let overlay = SKNode()
        overlay.zPosition = 20
        overlay.name = "gameOverOverlay"

        let bg = SKShapeNode(rectOf: CGSize(width: 280, height: 170), cornerRadius: 16)
        bg.fillColor = SKColor(white: 0, alpha: 0.85)
        bg.strokeColor = .white
        bg.lineWidth = 2
        overlay.addChild(bg)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Game Over"
        titleLabel.fontSize = 36
        titleLabel.fontColor = .red
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 30)
        overlay.addChild(titleLabel)

        let finalScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        finalScoreLabel.text = "Score: \(gameManager.score)"
        finalScoreLabel.fontSize = 22
        finalScoreLabel.fontColor = .white
        finalScoreLabel.verticalAlignmentMode = .center
        finalScoreLabel.position = CGPoint(x: 0, y: -10)
        overlay.addChild(finalScoreLabel)

        let tapLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tapLabel.text = "Tap to play again"
        tapLabel.fontSize = 16
        tapLabel.fontColor = .lightGray
        tapLabel.verticalAlignmentMode = .center
        tapLabel.position = CGPoint(x: 0, y: -52)
        overlay.addChild(tapLabel)

        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(overlay)
        gameOverNode = overlay
    }

    private func restartGame() {
        gameOverNode?.removeFromParent()
        gameOverNode = nil
        children
            .filter { $0.name?.hasPrefix(GameScene.spawnedPrefix) == true }
            .forEach { $0.removeFromParent() }
        gameManager.reset()
        updateScoreLabel()
        spawnerManager?.startSpawning()
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if gameManager.gameState == .gameOver {
            restartGame()
            return
        }

        clearSelection(resumeNodes: true)
        addNodeToSelection(at: location)
        updateLine(to: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameManager.gameState == .playing else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        addNodeToSelection(at: location)
        updateLine(to: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameManager.gameState == .playing else { return }
        finalizeSelection()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        clearSelection(resumeNodes: true)
    }

    // MARK: - Selection

    private func nearestSpawnedAncestor(for node: SKNode) -> SKNode? {
        var currentNode: SKNode? = node
        while let candidate = currentNode {
            if candidate.name?.hasPrefix(GameScene.spawnedPrefix) == true {
                return candidate
            }
            currentNode = candidate.parent
        }
        return nil
    }

    private func addNodeToSelection(at point: CGPoint) {
        let candidateNodes = nodes(at: point)
            .compactMap(nearestSpawnedAncestor(for:))
        guard let node = candidateNodes.first(where: { !selectedNodes.contains($0) }) else { return }

        node.removeAllActions()
        selectedNodes.append(node)
        applyHighlight(node, selected: true)
        updateRunningTotalLabel()
    }

    private func finalizeSelection() {
        guard !selectedNodes.isEmpty else {
            clearSelection(resumeNodes: false)
            return
        }

        lineNode?.removeFromParent()
        lineNode = nil
        runningTotalLabel?.text = ""

        let captured = selectedNodes
        selectedNodes.removeAll()

        let result = gameManager.submitCombination(captured)
        switch result {
        case .success:
            animateSuccess(captured)
            updateScoreLabel()
        case .exceeded:
            animateFailure(captured)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showGameOver()
            }
        case .invalid:
            resumeAndUnhighlight(captured)
        }
    }

    private func clearSelection(resumeNodes: Bool) {
        lineNode?.removeFromParent()
        lineNode = nil
        runningTotalLabel?.text = ""
        if resumeNodes {
            resumeAndUnhighlight(selectedNodes)
        }
        selectedNodes.removeAll()
    }

    // Unhighlights nodes and restarts their fall from current position.
    private func resumeAndUnhighlight(_ nodes: [SKNode]) {
        nodes.forEach { node in
            applyHighlight(node, selected: false)
            let remainingY = node.position.y - GameScene.offscreenRemovalY
            guard remainingY > 0 else {
                node.removeFromParent()
                return
            }
            // Scale fall duration proportionally to remaining travel distance.
            // totalTravelY = scene height + spawn offset (80) + |offscreenRemovalY| (120).
            let totalTravelY = size.height + 80 + abs(GameScene.offscreenRemovalY)
            let duration = max(0.5, (remainingY / totalTravelY) * GameScene.baseFallDuration)
            let moveDown = SKAction.moveTo(y: GameScene.offscreenRemovalY, duration: duration)
            let cleanup = SKAction.removeFromParent()
            node.run(.sequence([moveDown, cleanup]))
        }
    }

    // MARK: - Line Drawing

    private func updateLine(to touchPoint: CGPoint) {
        lineNode?.removeFromParent()
        lineNode = nil
        guard !selectedNodes.isEmpty else { return }

        let path = CGMutablePath()
        path.move(to: selectedNodes[0].position)
        for node in selectedNodes.dropFirst() {
            path.addLine(to: node.position)
        }
        path.addLine(to: touchPoint)

        let line = SKShapeNode(path: path)
        line.strokeColor = lineStrokeColor()
        line.lineWidth = 3
        line.lineCap = .round
        line.lineJoin = .round
        line.zPosition = 5
        line.name = "selectionLine"
        addChild(line)
        lineNode = line
    }

    private func lineStrokeColor() -> SKColor {
        guard !selectedNodes.isEmpty else { return .white }
        let total = gameManager.evaluate(selectedNodes)
        if total > 7 { return .red }
        if total == 7 { return .green }
        return .white
    }

    // MARK: - Node Highlighting

    private func applyHighlight(_ node: SKNode, selected: Bool) {
        node.setScale(selected ? 1.25 : 1.0)
        if let shape = node as? SKShapeNode {
            shape.strokeColor = selected ? .yellow : .white
        }
    }

    // MARK: - Animations

    private func animateSuccess(_ nodes: [SKNode]) {
        nodes.forEach { node in
            let scaleUp = SKAction.scale(to: 1.6, duration: 0.1)
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let remove = SKAction.removeFromParent()
            node.run(.sequence([scaleUp, fadeOut, remove]))
        }
    }

    private func animateFailure(_ nodes: [SKNode]) {
        nodes.forEach { node in
            let redFlash = SKAction.run { (node as? SKShapeNode)?.fillColor = .red }
            let shake = SKAction.sequence([
                SKAction.moveBy(x: -8, y: 0, duration: 0.05),
                SKAction.moveBy(x: 16, y: 0, duration: 0.1),
                SKAction.moveBy(x: -8, y: 0, duration: 0.05)
            ])
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let remove = SKAction.removeFromParent()
            node.run(.sequence([redFlash, shake, fadeOut, remove]))
        }
    }
}
