# Super 7 - iOS Game

A fast-paced iOS game combining line-drawing mechanics with arithmetic. Players create sums or products that equal 7 by connecting numbers (1-6) and special power-up items.

## Game Mechanics

### Core Gameplay
- Connect numbers and special items to create sums or products equaling 7
- Numbers spawn rapidly across the screen
- Touching numbers creates a line connecting them
- Release to calculate the total — if it equals 7, you score!
- **Game Over** if any combination exceeds 7

### Special Items

| Item | Effect |
|------|--------|
| **Multipliers (×2, ×3)** | Increase the value of a number |
| **Minus 1 (-1)** | Lower a number or combine for greater negative effect |
| **Stars** | Instantly transform any number into 7 |
| **Heptagon (+/-)** | Acts as -1 multiplier, flips the sign of touched numbers |
| **Division by 2 (÷2)** | Splits numbers in half (odd numbers round differently) |

## Technology Stack

- **Language**: Swift
- **Framework**: SpriteKit
- **Deployment Target**: iOS 14+
- **Architecture**: MVC with Scene-based game logic

## Project Structure

```
SuperSevens/
├── GameScene.swift          # Main game scene
├── GameViewController.swift  # View controller
├── Models/
│   ├── GameItem.swift       # Base class for numbers and special items
│   ├── Number.swift         # Number item logic
│   └── SpecialItem.swift    # Special item types
├── Managers/
│   ├── GameManager.swift    # Game state and logic
│   └── SpawnerManager.swift # Item spawning
└── UI/
    ├── HUD.swift            # Heads-up display (score, lives)
    └── GameOverScreen.swift # Game over UI
```

## Development Roadmap

- [ ] Basic SpriteKit scene setup
- [ ] Number and item spawning system
- [ ] Touch and line-drawing mechanics
- [ ] Arithmetic calculation and validation
- [ ] Score system
- [ ] Special item implementations
- [ ] Game over detection
- [ ] UI/HUD
- [ ] Sound effects and feedback
- [ ] Polish and optimization

## Getting Started

1. Open Xcode
2. Create a new iOS Game project with SpriteKit template
3. Clone this repository
4. Follow the implementation roadmap

## License

MIT