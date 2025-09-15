# Shapeship - Game Design Document

## Core Concept

Shapeship is a horizontal scrolling shoot-em-up inspired by R-Type, but with a unique ship building mechanic. Players construct their spaceship from different pixel types, each with unique properties and functions. The game combines classic shmup action with creative ship design and strategic pixel placement.

## Gameplay Loop

1. **Combat Phase**: Fly through levels shooting enemies and avoiding obstacles
2. **Building Phase**: Between levels, choose from random pixel types to add to your ship
3. **Progression**: Each level increases difficulty and offers new pixel types

## Ship Building System

### Pixel Types

- **Core**: The heart of your ship. Game over if destroyed. Always starts in the center.
- **Gun**: Fires basic projectiles forward. More guns = more firepower.
- **Laser**: Fires continuous beam that pierces through enemies.
- **Booster**: Increases ship speed and maneuverability.
- **Armor**: Absorbs damage before being destroyed. Protects adjacent pixels.
- **Shield**: Generates temporary protective barriers.
- **Missile**: Fires homing projectiles at enemies.
- **Spread**: Fires multiple projectiles in a spread pattern.

### Building Rules

- Ship starts with just a Core pixel
- Each level completion offers 3 random pixel types to choose from
- Pixels must be placed adjacent to existing pixels (connected ship)
- Ship size affects speed and maneuverability (larger = slower)
- Pixel placement affects firing patterns and ship behavior

## Combat Mechanics

### Movement
- 8-directional movement with momentum
- Ship speed affected by total pixel count and booster pixels
- Collision detection per individual pixel

### Weapons
- Each weapon pixel fires independently
- Firing rate depends on pixel type
- Weapon positioning affects trajectory and coverage

### Damage System
- Individual pixels can be destroyed
- Core destruction = game over
- Losing pixels affects ship capabilities
- Some pixels can be "critical" - losing them disables connected systems

## Level Design

### Environment Types
- **Asteroid Fields**: Dense obstacles requiring careful navigation
- **Enemy Formations**: Waves of ships in tactical arrangements
- **Space Stations**: Large structures with turrets and weak points
- **Nebulae**: Visibility reduced, energy weapons boosted

### Progression
- 10 levels per sector
- Each sector introduces new enemy types and pixel options
- Boss fights every 5 levels
- Increasing complexity in level layouts and enemy AI

## Visual Style

### Aesthetic
- Retro pixel art with TIC-80's 16-color palette
- Clean, readable sprite design for fast-paced action
- Particle effects for explosions and weapon fire
- Smooth scrolling backgrounds

### UI Design
- Minimal HUD: Score, Lives, Level
- Ship builder with grid-based placement
- Visual feedback for pixel types and connections

## Technical Implementation

### Core Systems
1. **Ship System**: Modular pixel-based ship representation
2. **Combat System**: Collision detection, weapon management
3. **Level System**: Scrolling backgrounds, enemy spawning
4. **Builder System**: Drag-and-drop pixel placement interface

### Performance Considerations
- Efficient collision detection for modular ships
- Optimized particle systems within TIC-80 limits
- Smart enemy AI that doesn't overwhelm the CPU

## Progression & Replayability

### Unlocks
- New pixel types unlock as you progress
- Special "legendary" pixels with unique properties
- Color variants of pixels with different stats

### Scoring
- Points for enemies destroyed
- Bonus for efficient ship designs
- Multipliers for consecutive hits without taking damage

### Difficulty Scaling
- Enemy health and speed increase
- More complex enemy patterns
- Environmental hazards become more frequent

## Balance & Advanced Mechanics

### Energy Budget System
- **Energy Management**: Each pixel consumes energy per frame from the ship's power budget
- **Generator Pixels**: Special pixels that produce energy, expanding your power capacity
- **Energy Costs**: Weapon pixels (high cost), armor (medium), utility pixels (low)
- **Power Starvation**: Insufficient energy causes pixels to operate at reduced efficiency
- **Strategic Trade-offs**: More weapons require more generators, balancing offense vs utility

### Pixel Synergies
- **Linear Bonuses**: 3+ shooters in a row = increased fire rate or damage
- **Formation Effects**: Specific patterns unlock special abilities (L-shape = corner shots)
- **Type Combinations**: Laser + armor = reinforced beam, shooter + booster = rapid fire
- **Proximity Bonuses**: Adjacent similar pixels gain efficiency improvements

### Ship Shape Penalties
- **Aerodynamic Efficiency**: Tall/thin ships move faster but are fragile
- **Square Ships**: Balanced but no specialization bonuses
- **Long Ships**: Slower movement, harder to maneuver, but stable weapon platforms
- **Compact Designs**: Faster, more maneuverable, better for dodging
- **Center of Mass**: Ship balance affects handling and turning speed

## Future Expansion Ideas

### Advanced Mechanics
- **Ship Classes**: Predefined templates for different playstyles
- **Overclocking**: Temporarily boost pixel performance at cost of stability and energy
- **Salvage Mode**: Collect destroyed enemy pixels mid-combat
- **Heat Management**: Weapon pixels generate heat, requiring cooling systems

### Quality of Life
- Ship blueprint saving/loading
- Challenge modes with specific ship restrictions
- Leaderboards and ship sharing

---

*This design serves as the foundation for Shapeship's development, balancing creative ship building with intense shoot-em-up action within TIC-80's technical constraints.*