//
//  GameScene.swift
//  SuperSevens
//
//  Created by TGO on 7/20/26.
//

import SpriteKit

class GameScene: SKScene {
    private var score: Int = 0
    private var spawnerManager: SpawnerManager?

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
        spawnerManager?.startSpawning()
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        spawnerManager?.stopSpawning()
    }

    override func update(_ currentTime: TimeInterval) {
        spawnerManager?.update(currentTime: currentTime, score: score)
        spawnerManager?.cleanupOutOfBoundsNodes()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }

        if spawnerManager?.removeTappedNodes(at: location) == true {
            score += 1
        }
    }
}
