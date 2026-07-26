//
//  GameScene.swift
//  SuperSevens
//
//  Created by TGO on 7/20/26.
//

import SpriteKit

@MainActor
class GameScene: SKScene {
    private enum UITestScenario: String {
        case disabled
        case scoreSequence
        case gameOver

        static func currentProcessScenario() -> UITestScenario {
            let processInfo = ProcessInfo.processInfo
            if let rawValue = processInfo.environment["SUPERSEVENS_UI_TEST_SCENARIO"] {
                return UITestScenario(rawValue: rawValue) ?? .disabled
            }
            if let argumentIndex = processInfo.arguments.firstIndex(of: "-uiTestScenario"),
               processInfo.arguments.indices.contains(argumentIndex + 1) {
                return UITestScenario(rawValue: processInfo.arguments[argumentIndex + 1]) ?? .disabled
            }
            return .disabled
        }

        var isEnabled: Bool {
            self != .disabled
        }
    }

    private enum AccessibilityValueFormatter {
        static func value(stateDescription: String, score: Int, selectionCount: Int, runningTotal: String) -> String {
            "state=\(stateDescription); score=\(score); selection=\(selectionCount); total=\(runningTotal)"
        }
    }

    private static let minimumTapTargetSize: CGFloat = 44

    private var gameManager = GameManager()
    private var spawnerManager: SpawnerManager?
    private let uiTestScenario = UITestScenario.currentProcessScenario()

    private var selectedNodes: [SKNode] = []
    private var lineNode: SKShapeNode?
    private var activeTouch: UITouch?
    private weak var hudNode: HUDNode?
    private weak var gameOverNode: SKNode?
    private weak var muteLabel: SKLabelNode?

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
        updateAccessibilityState()
        if uiTestScenario.isEnabled {
            configureUITestScenario()
            return
        }
        SoundManager.shared.playBackgroundMusic()
        spawnerManager?.startSpawning()
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        spawnerManager?.stopSpawning()
        SoundManager.shared.stopBackgroundMusic()
    }

    override func update(_ currentTime: TimeInterval) {
        guard gameManager.gameState == .playing else { return }
        spawnerManager?.update(currentTime: currentTime, score: gameManager.score)
        spawnerManager?.cleanupOutOfBoundsNodes()
    }

    // MARK: - HUD

    private func setupHUD() {
        let hud = HUDNode(sceneSize: size)
        addChild(hud)
        hudNode = hud

        let muteNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        muteNode.fontSize = 18
        muteNode.fontColor = .white
        muteNode.horizontalAlignmentMode = .right
        muteNode.position = CGPoint(x: size.width - 20, y: size.height - 50)
        muteNode.zPosition = 10
        muteNode.name = "muteToggleLabel"
        addChild(muteNode)
        muteLabel = muteNode
        updateMuteLabel()
        updateAccessibilityState()
    }

    private func updateScoreLabel() {
        hudNode?.updateScore(gameManager.score)
        updateAccessibilityState()
    }

    private func updateRunningTotalLabel() {
        guard !selectedNodes.isEmpty else {
            hudNode?.updateRunningTotal(nil)
            updateAccessibilityState()
            return
        }
        let total = gameManager.evaluate(selectedNodes)
        hudNode?.updateRunningTotal(total)
        updateAccessibilityState()
    }

    // MARK: - Game Over

    private func showGameOver() {
        spawnerManager?.stopSpawning()
        SoundManager.shared.stopBackgroundMusic()
        let overlay = GameOverNode(
            score: gameManager.score,
            highScore: gameManager.highScore,
            isNewHighScore: gameManager.isNewHighScore
        )
        overlay.zPosition = 20
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(overlay)
        gameOverNode = overlay
        updateAccessibilityState()
    }

    private func handleGameOverTap(at location: CGPoint) {
        var candidate: SKNode? = atPoint(location)
        while let node = candidate {
            switch node.name {
            case GameOverNode.playAgainButtonName:
                restartGame()
                return
            case GameOverNode.mainMenuButtonName:
                restartWithTransition()
                return
            default:
                candidate = node.parent
            }
        }
    }

    private func restartWithTransition() {
        guard let view else { return }
        let freshScene = GameScene(size: size)
        freshScene.scaleMode = scaleMode
        view.presentScene(freshScene, transition: .crossFade(withDuration: 0.5))
    }

    private func restartGame() {
        gameOverNode?.removeFromParent()
        gameOverNode = nil
        lineNode?.removeFromParent()
        lineNode = nil
        selectedNodes.removeAll()
        activeTouch = nil
        children
            .filter { $0.name?.hasPrefix(SpawnerManager.spawnNodePrefix) == true }
            .forEach { node in
                if spawnerManager?.recycle(node) != true {
                    node.removeFromParent()
                }
            }
        gameManager.reset()
        updateScoreLabel()
        if uiTestScenario.isEnabled {
            configureUITestScenario()
        } else {
            SoundManager.shared.playBackgroundMusic()
            spawnerManager?.startSpawning()
        }
        updateAccessibilityState()
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if handleMuteToggleTap(at: location) {
            return
        }

        if gameManager.gameState == .gameOver {
            handleGameOverTap(at: location)
            return
        }

        guard gameManager.gameState == .playing, activeTouch == nil else { return }
        activeTouch = touch
        clearSelection(resumeNodes: true)
        addNodeToSelection(at: location)
        updateLine(to: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameManager.gameState == .playing else { return }
        guard let touch = activeTouch, touches.contains(touch) else { return }

        let location = touch.location(in: self)
        addNodeToSelection(at: location)
        updateLine(to: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        activeTouch = nil
        guard gameManager.gameState == .playing else { return }
        finalizeSelection()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        activeTouch = nil
        clearSelection(resumeNodes: true)
    }

    // MARK: - Selection

    private func nearestSpawnedAncestor(for node: SKNode) -> SKNode? {
        var currentNode: SKNode? = node
        while let candidate = currentNode {
            if candidate.name?.hasPrefix(SpawnerManager.spawnNodePrefix) == true {
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
        SoundManager.shared.playSelectionTick()
        updateRunningTotalLabel()

        if gameManager.checkMidSelectionTotal(selectedNodes) {
            triggerGameOverFromSelection()
        }
    }

    private func finalizeSelection() {
        guard !selectedNodes.isEmpty else {
            clearSelection(resumeNodes: false)
            return
        }

        lineNode?.removeFromParent()
        lineNode = nil
        hudNode?.updateRunningTotal(nil)

        let captured = selectedNodes
        selectedNodes.removeAll()

        let result = gameManager.submitCombination(captured)
        switch result {
        case .success:
            SoundManager.shared.playCorrectMatch()
            animateSuccess(captured)
            updateScoreLabel()
        case .exceeded:
            SoundManager.shared.playErrorBuzz()
            animateFailure(captured)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showGameOver()
            }
        case .invalid:
            SoundManager.shared.playErrorBuzz()
            resumeAndUnhighlight(captured)
        }
        updateAccessibilityState()
    }

    // Called when total exceeds 7 mid-drag; cancels the touch, animates the chain,
    // and schedules the game over overlay without waiting for finger lift.
    private func triggerGameOverFromSelection() {
        lineNode?.removeFromParent()
        lineNode = nil
        hudNode?.updateRunningTotal(nil)
        activeTouch = nil
        let captured = selectedNodes
        selectedNodes.removeAll()
        SoundManager.shared.playErrorBuzz()
        animateFailure(captured)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showGameOver()
        }
    }

    private func handleMuteToggleTap(at location: CGPoint) -> Bool {
        if let muteLabel {
            var tapArea = muteLabel.frame
            let expandX = max(0, (Self.minimumTapTargetSize - tapArea.width) / 2)
            let expandY = max(0, (Self.minimumTapTargetSize - tapArea.height) / 2)
            tapArea = CGRect(
                x: tapArea.minX - expandX,
                y: tapArea.minY - expandY,
                width: tapArea.width + (expandX * 2),
                height: tapArea.height + (expandY * 2)
            )
            if tapArea.contains(location) {
                toggleMuteSetting()
                return true
            }
        }
        return false
    }

    private func toggleMuteSetting() {
        let isMuted = SoundManager.shared.toggleMute()
        updateMuteLabel(isMuted: isMuted)
    }

    private func updateMuteLabel(isMuted: Bool? = nil) {
        let currentMuteState = isMuted ?? SoundManager.shared.isMuted
        muteLabel?.text = currentMuteState ? "🔇 Sound Off" : "🔊 Sound On"
    }

    private func clearSelection(resumeNodes: Bool) {
        lineNode?.removeFromParent()
        lineNode = nil
        hudNode?.updateRunningTotal(nil)
        if resumeNodes {
            resumeAndUnhighlight(selectedNodes)
        }
        selectedNodes.removeAll()
        updateAccessibilityState()
    }

    // Unhighlights nodes and restarts their fall from current position.
    private func resumeAndUnhighlight(_ nodes: [SKNode]) {
        nodes.forEach { node in
            applyHighlight(node, selected: false)
            let remainingY = node.position.y - SpawnerManager.offscreenRemovalY
            guard remainingY > 0 else {
                if spawnerManager?.recycle(node) != true {
                    node.removeFromParent()
                }
                return
            }
            // Scale fall duration proportionally to remaining travel distance.
            let totalTravelY = SpawnerManager.totalTravelDistance(forSceneHeight: size.height)
            let duration = max(0.5, (remainingY / totalTravelY) * GameScene.baseFallDuration)
            let moveDown = SKAction.moveTo(y: SpawnerManager.offscreenRemovalY, duration: duration)
            let cleanup = spawnerManager?.recycleAction(for: node) ?? .removeFromParent()
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
            let remove = spawnerManager?.recycleAction(for: node) ?? .removeFromParent()
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
            let remove = spawnerManager?.recycleAction(for: node) ?? .removeFromParent()
            node.run(.sequence([redFlash, shake, fadeOut, remove]))
        }
    }

    private func updateAccessibilityState() {
        guard uiTestScenario.isEnabled else {
            view?.accessibilityValue = nil
            return
        }
        let stateDescription = gameManager.gameState == .playing ? "playing" : "gameOver"
        let runningTotal = selectedNodes.isEmpty ? "none" : String(gameManager.evaluate(selectedNodes))
        view?.accessibilityValue = AccessibilityValueFormatter.value(
            stateDescription: stateDescription,
            score: gameManager.score,
            selectionCount: selectedNodes.count,
            runningTotal: runningTotal
        )
    }

    private func configureUITestScenario() {
        SoundManager.shared.stopBackgroundMusic()
        spawnerManager?.stopSpawning()
        spawnerManager?.recycleSpawnedNodes(children.filter { $0.name?.hasPrefix(SpawnerManager.spawnNodePrefix) == true })

        switch uiTestScenario {
        case .disabled:
            break
        case .scoreSequence:
            addUITestSpawnedNumber(value: 3, normalizedX: 0.35)
            addUITestSpawnedNumber(value: 4, normalizedX: 0.65)
        case .gameOver:
            addUITestSpawnedNumber(value: 4, normalizedX: 0.35)
            addUITestSpawnedNumber(value: 4, normalizedX: 0.65)
        }

        updateAccessibilityState()
    }

    private func addUITestSpawnedNumber(value: Int, normalizedX: CGFloat) {
        guard let spawnerManager else {
            assertionFailure("SpawnerManager must exist before configuring UI test nodes.")
            return
        }
        let node = spawnerManager.dequeueNumberNode(value: value)
        spawnerManager.prepareSpawnedNode(
            node,
            position: CGPoint(x: size.width * normalizedX, y: size.height * 0.55)
        )
        addChild(node)
    }
}
