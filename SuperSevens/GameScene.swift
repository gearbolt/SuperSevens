//
//  GameScene.swift
//  SuperSevens
//
//  Created by TGO on 7/20/26.
//

import SpriteKit

class GameScene: SKScene {
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = .black
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .black
    }
}
