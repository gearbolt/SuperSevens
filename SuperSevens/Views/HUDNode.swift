//
//  HUDNode.swift
//  SuperSevens
//
//  Created by TGO on 7/20/26.
//

import SpriteKit

/// Encapsulates the in-game heads-up display: score, lives counter,
/// pause button, and the running-total indicator shown during a selection.
final class HUDNode: SKNode {
    static let scoreLabelName = "scoreLabel"
    static let runningTotalLabelName = "runningTotalLabel"
    static let pauseButtonName = "pauseButton"

    private static let heartSpacing: CGFloat = 28
    private static let pauseButtonMinTargetSize: CGFloat = 44
    private static let scoreBumpScale: CGFloat = 1.3
    private static let scoreBumpUpDuration: TimeInterval = 0.08
    private static let scoreBumpDownDuration: TimeInterval = 0.14

    private let scoreLabel: SKLabelNode
    private let runningTotalLabel: SKLabelNode
    private let pauseButton: SKLabelNode
    private var heartNodes: [SKLabelNode] = []

    init(sceneSize: CGSize) {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        runningTotalLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        pauseButton = SKLabelNode(fontNamed: "AvenirNext-Bold")
        super.init()
        buildUI(sceneSize: sceneSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for HUDNode.")
    }

    // MARK: - Public update API

    /// Refreshes the score counter with a smooth bump animation.
    func updateScore(_ score: Int) {
        scoreLabel.text = "Score: \(score)"
        animateScoreBump()
    }

    /// Refreshes the lives (hearts) display, animating any hearts that were just lost.
    func updateLives(_ lives: Int) {
        for (index, heart) in heartNodes.enumerated() {
            let shouldBeActive = index < lives
            if !shouldBeActive && heart.alpha > 0.5 {
                // Animate the heart being lost
                let shake = SKAction.sequence([
                    SKAction.moveBy(x: -5, y: 0, duration: 0.05),
                    SKAction.moveBy(x: 10, y: 0, duration: 0.08),
                    SKAction.moveBy(x: -5, y: 0, duration: 0.05)
                ])
                let fadeOut = SKAction.fadeAlpha(to: 0.25, duration: 0.3)
                heart.run(.group([shake, fadeOut]))
            } else if shouldBeActive {
                heart.alpha = 1
            }
        }
    }

    /// Updates the running-total indicator.
    /// Pass `nil` to hide the label (e.g. when no nodes are selected).
    func updateRunningTotal(_ total: Int?) {
        guard let total else {
            runningTotalLabel.text = ""
            return
        }
        runningTotalLabel.text = "= \(total)"
        runningTotalLabel.fontColor = total > 7 ? .red : (total == 7 ? .green : .yellow)
    }

    /// Updates the pause button icon to reflect the current paused state.
    func setPaused(_ paused: Bool) {
        pauseButton.text = paused ? "▶" : "⏸"
    }

    // MARK: - Hit Testing

    /// Returns true if `point` (in parent coordinates) falls within the pause button's
    /// expanded minimum-tap-target area.
    func hitTestPauseButton(at point: CGPoint) -> Bool {
        var area = pauseButton.frame
        let expandX = max(0, (Self.pauseButtonMinTargetSize - area.width) / 2)
        let expandY = max(0, (Self.pauseButtonMinTargetSize - area.height) / 2)
        area = CGRect(
            x: area.minX - expandX,
            y: area.minY - expandY,
            width: area.width + expandX * 2,
            height: area.height + expandY * 2
        )
        return area.contains(point)
    }

    // MARK: - Layout

    private func buildUI(sceneSize: CGSize) {
        let topY = sceneSize.height - 50

        // Score label — top left
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 16, y: topY)
        scoreLabel.zPosition = 10
        scoreLabel.text = "Score: 0"
        scoreLabel.name = Self.scoreLabelName
        addChild(scoreLabel)

        // Lives hearts — top centre
        buildLivesDisplay(centreX: sceneSize.width / 2, y: topY)

        // Pause button — top right
        pauseButton.fontSize = 22
        pauseButton.fontColor = .white
        pauseButton.horizontalAlignmentMode = .right
        pauseButton.verticalAlignmentMode = .center
        pauseButton.position = CGPoint(x: sceneSize.width - 16, y: topY)
        pauseButton.zPosition = 10
        pauseButton.text = "⏸"
        pauseButton.name = Self.pauseButtonName
        addChild(pauseButton)

        // Running-total indicator — lower centre
        runningTotalLabel.fontSize = 22
        runningTotalLabel.fontColor = .yellow
        runningTotalLabel.horizontalAlignmentMode = .center
        runningTotalLabel.verticalAlignmentMode = .center
        runningTotalLabel.position = CGPoint(x: sceneSize.width / 2, y: 60)
        runningTotalLabel.zPosition = 10
        runningTotalLabel.name = Self.runningTotalLabelName
        addChild(runningTotalLabel)
    }

    private func buildLivesDisplay(centreX: CGFloat, y: CGFloat) {
        let count = GameManager.initialLives
        let totalWidth = CGFloat(count - 1) * Self.heartSpacing
        let startX = centreX - totalWidth / 2

        for i in 0..<count {
            let heart = SKLabelNode(text: "❤️")
            heart.fontSize = 20
            heart.horizontalAlignmentMode = .center
            heart.verticalAlignmentMode = .center
            heart.position = CGPoint(x: startX + CGFloat(i) * Self.heartSpacing, y: y)
            heart.zPosition = 10
            addChild(heart)
            heartNodes.append(heart)
        }
    }

    // MARK: - Animations

    private func animateScoreBump() {
        scoreLabel.removeAction(forKey: "scoreBump")
        let scaleUp = SKAction.scale(to: Self.scoreBumpScale, duration: Self.scoreBumpUpDuration)
        scaleUp.timingMode = .easeOut
        let scaleDown = SKAction.scale(to: 1.0, duration: Self.scoreBumpDownDuration)
        scaleDown.timingMode = .easeIn
        scoreLabel.run(.sequence([scaleUp, scaleDown]), withKey: "scoreBump")
    }
}
