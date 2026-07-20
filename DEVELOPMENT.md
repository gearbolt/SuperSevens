# Development Guide

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/gearbolt/SuperSevens.git
   cd SuperSevens
   ```

2. **Open in Xcode**
   - Create a new iOS Game project with SpriteKit
   - Or open the .xcodeproj file if one exists

3. **Install dependencies** (if using CocoaPods or SPM)
   ```bash
   # If using CocoaPods
   pod install
   ```

## Architecture Overview

### GameManager
- Handles game state (playing, paused, game over)
- Tracks score and lives
- Validates arithmetic combinations

### SpawnerManager
- Spawns numbers and special items
- Controls spawn rate (increases with difficulty)
- Manages item lifecycle

### GameScene
- Handles touch input for line drawing
- Updates game state each frame
- Renders all game elements

## Implementation Tips

### Line Drawing
- Use `UITouch` delegates to track finger movement
- Create `SKShapeNode` for visual line feedback
- Store touched items in array as user drags

### Arithmetic Validation
- Parse the chain of items
- Apply multipliers and operators in correct order
- Check if result equals 7

### Special Items
- **Stars**: Replace with 7 value
- **Heptagon**: Negate the next number
- **÷2**: Split into two items (handled specially)

## Testing Checklist

- [ ] Numbers spawn correctly
- [ ] Touch input registers lines
- [ ] Arithmetic calculation is accurate
- [ ] Score updates on valid combination
- [ ] Game over triggers on invalid combination
- [ ] Special items work as intended
- [ ] Difficulty increases over time

## Performance Considerations

- Limit active nodes on screen (reuse pooled nodes if needed)
- Optimize touch detection with collision masks
- Use SKPhysicsBody sparingly
- Profile with Instruments (Xcode)

## Debugging

- Use `print()` statements in GameManager for logic
- Enable physics debugging in GameScene: `physicsWorld.showsPhysics = true`
- Use breakpoints in Xcode for step-through debugging
