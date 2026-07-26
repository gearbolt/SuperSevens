//
//  HUDNode.swift
//  SuperSevens
//
//  Created by TGO on 7/20/26.
//

import SpriteKit

/// Encapsulates the in-game heads-up display: the persistent score counter and
/// the running-total indicator shown while a combination is being drawn.
final class HUDNode: SKNode {
    static let scoreLabelName = "scoreLabel"
    static let runningTotalLabelName = "runningTotalLabel"

    private let scoreLabel: SKLabelNode
    private let runningTotalLabel: SKLabelNode

    init(sceneSize: CGSize) {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        runningTotalLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        super.init()
        buildUI(sceneSize: sceneSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for HUDNode.")
    }

    /// Refreshes the score counter shown in the top-left corner of the screen.
    func updateScore(_ score: Int) {
        scoreLabel.text = "Score: \(score)"
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

    private func buildUI(sceneSize: CGSize) {
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 20, y: sceneSize.height - 50)
        scoreLabel.zPosition = 10
        scoreLabel.text = "Score: 0"
        scoreLabel.name = Self.scoreLabelName
        addChild(scoreLabel)

        runningTotalLabel.fontSize = 22
        runningTotalLabel.fontColor = .yellow
        runningTotalLabel.horizontalAlignmentMode = .center
        runningTotalLabel.position = CGPoint(x: sceneSize.width / 2, y: 60)
        runningTotalLabel.zPosition = 10
        runningTotalLabel.name = Self.runningTotalLabelName
        addChild(runningTotalLabel)
    }
}
