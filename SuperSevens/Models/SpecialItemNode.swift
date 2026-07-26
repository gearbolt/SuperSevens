import SpriteKit

enum SpecialItemType: CaseIterable, Hashable {
    case multiplier
    case multiplierThree
    case star
    case heptagon
    case minusOne
    case divisionByTwo

    var displayText: String {
        switch self {
        case .multiplier:
            return "×2"
        case .multiplierThree:
            return "×3"
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
        case .multiplierThree:
            return .brown
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

    /// Relative spawn weight used for rarity-based selection.
    /// Higher values spawn more frequently; lower values are rarer.
    var spawnWeight: Double {
        switch self {
        case .multiplier:
            return 3
        case .multiplierThree:
            return 1
        case .star:
            return 1
        case .heptagon:
            return 2
        case .minusOne:
            return 3
        case .divisionByTwo:
            return 2
        }
    }

    /// The score multiplier contributed by this item, or nil if not a multiplier type.
    var scoreMultiplier: Int? {
        switch self {
        case .multiplier:
            return 2
        case .multiplierThree:
            return 3
        default:
            return nil
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

    func prepareForReuse() {
        fillColor = itemType.color
        strokeColor = .white
        lineWidth = 2
    }
}
