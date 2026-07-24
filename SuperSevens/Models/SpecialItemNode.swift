import SpriteKit

enum SpecialItemType: CaseIterable {
    case multiplier
    case star
    case heptagon
    case minusOne
    case divisionByTwo

    var displayText: String {
        switch self {
        case .multiplier:
            return "×2"
        case .star:
            return "★"
        case .heptagon:
            return "H7"
        case .minusOne:
            return "-1"
        case .divisionByTwo:
            return "÷2"
        }
    }

    var color: SKColor {
        switch self {
        case .multiplier:
            return .systemOrange
        case .star:
            return .systemYellow
        case .heptagon:
            return .systemPurple
        case .minusOne:
            return .systemRed
        case .divisionByTwo:
            return .systemGreen
        }
    }
}

final class SpecialItemNode: SKShapeNode {
    let itemType: SpecialItemType

    init(itemType: SpecialItemType, size: CGSize = CGSize(width: 56, height: 56)) {
        self.itemType = itemType
        super.init()

        let path = CGPath(roundedRect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height), cornerWidth: 12, cornerHeight: 12, transform: nil)
        self.path = path
        fillColor = itemType.color
        strokeColor = .white
        lineWidth = 2
        name = "specialItemNode"

        let label = SKLabelNode(text: itemType.displayText)
        label.fontName = "AvenirNext-Bold"
        label.fontColor = .white
        label.fontSize = 24
        label.verticalAlignmentMode = .center
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for SpecialItemNode.")
    }
}
