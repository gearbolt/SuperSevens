import SpriteKit

final class NumberNode: SKShapeNode {
    static let validRange = 1...6

    let value: Int

    init(value: Int, radius: CGFloat = 28) {
        precondition(NumberNode.validRange.contains(value), "NumberNode value must be between 1 and 6.")
        self.value = value
        super.init()

        let path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        self.path = path
        fillColor = .systemBlue
        strokeColor = .white
        lineWidth = 2
        name = "numberNode"

        let label = SKLabelNode(text: "\(self.value)")
        label.fontName = "AvenirNext-Bold"
        label.fontColor = .white
        label.fontSize = radius
        label.verticalAlignmentMode = .center
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}
