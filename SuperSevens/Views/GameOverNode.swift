//
//  GameOverNode.swift
//  SuperSevens
//
//  Created by TGO on 7/20/26.
//

import SpriteKit

final class GameOverNode: SKNode {
    static let playAgainButtonName = "gameOver_playAgain"
    static let mainMenuButtonName = "gameOver_mainMenu"

    init(score: Int, highScore: Int, isNewHighScore: Bool) {
        super.init()
        buildUI(score: score, highScore: highScore, isNewHighScore: isNewHighScore)
        animateIn()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for GameOverNode.")
    }

    private func buildUI(score: Int, highScore: Int, isNewHighScore: Bool) {
        let bg = SKShapeNode(rectOf: CGSize(width: 300, height: 250), cornerRadius: 20)
        bg.fillColor = SKColor(white: 0, alpha: 0.88)
        bg.strokeColor = .white
        bg.lineWidth = 2
        addChild(bg)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Game Over"
        titleLabel.fontSize = 38
        titleLabel.fontColor = .red
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 86)
        addChild(titleLabel)

        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: 46)
        addChild(scoreLabel)

        let highScoreText = isNewHighScore ? "New Best: \(highScore)!" : "Best: \(highScore)"
        let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        highScoreLabel.text = highScoreText
        highScoreLabel.fontSize = 20
        highScoreLabel.fontColor = isNewHighScore ? .systemYellow : .lightGray
        highScoreLabel.verticalAlignmentMode = .center
        highScoreLabel.position = CGPoint(x: 0, y: 14)
        addChild(highScoreLabel)

        addButton(
            text: "Play Again",
            name: Self.playAgainButtonName,
            position: CGPoint(x: -76, y: -60),
            color: .systemGreen
        )

        addButton(
            text: "Main Menu",
            name: Self.mainMenuButtonName,
            position: CGPoint(x: 76, y: -60),
            color: .systemBlue
        )
    }

    private func addButton(text: String, name: String, position: CGPoint, color: SKColor) {
        let button = SKShapeNode(rectOf: CGSize(width: 128, height: 44), cornerRadius: 10)
        button.fillColor = color
        button.strokeColor = .white
        button.lineWidth = 1.5
        button.position = position
        button.name = name
        addChild(button)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = name
        button.addChild(label)
    }

    private func animateIn() {
        setScale(0.5)
        alpha = 0
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.35)
        scaleAction.timingMode = .easeOut
        let fadeIn = SKAction.fadeIn(withDuration: 0.25)
        run(.group([scaleAction, fadeIn]))
    }
}
