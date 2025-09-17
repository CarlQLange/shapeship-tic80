# Shapeship Parts & Synergies Guide

Complete reference for all ship parts, their effects, costs, and synergy combinations in Shapeship.

## Table of Contents
- [Core Parts](#core-parts)
- [Weapon Parts](#weapon-parts)
- [Special Parts](#special-parts)
- [Advanced Special Parts](#advanced-special-parts)
- [Synergy System](#synergy-system)
- [Rarity & Scrap System](#rarity--scrap-system)
- [Balance Notes](#balance-notes)

---

## Core Parts

### **Armor** 🛡️
- **Color**: Grey (14)
- **Health**: 2
- **Energy Cost**: +1
- **Effect**: High-health defensive part
- **Rarity**: 80% (Common)

### **Engine** ⚡
- **Color**: Blue (9)
- **Health**: 1
- **Energy Cost**: +1 (Recently buffed from +2)
- **Effect**: Increases movement speed
- **Formula**: Base 1.0 speed + 0.3 per additional engine
- **Rarity**: 80% (Common)

### **Generator** 🔋
- **Color**: Yellow (4)
- **Health**: 1
- **Energy Cost**: -3 (Provides energy)
- **Effect**: Power source - generates energy instead of consuming it
- **Auto-Bias**: 5x more likely to appear when below 20% energy
- **Rarity**: 80% (Common)

---

## Weapon Parts

### **Shooter** 🔫
- **Color**: Red (2)
- **Health**: 1
- **Energy Cost**: +3
- **Effect**: Basic projectile weapon
- **Fire Rate**: Every 0.6 seconds (36 frames)
- **Projectile**: Standard yellow bullets
- **Rarity**: 80% (Common)

### **Laser** ⚡
- **Color**: Light Blue (10)
- **Health**: 1
- **Energy Cost**: +4
- **Effect**: Fast-firing energy weapon
- **Fire Rate**: Every 0.33 seconds (20 frames)
- **Projectile**: Standard yellow bullets (faster rate)
- **Rarity**: 25% (Uncommon)

### **Homing** 🎯
- **Color**: Light Green (5)
- **Health**: 1
- **Energy Cost**: +5
- **Effect**: Fires homing missiles that track enemies
- **Fire Rate**: Every 1.5 seconds (90 frames)
- **Projectile**: Slower but seeks nearest target
- **Lifetime**: 6 seconds maximum
- **Rarity**: 15% (Rare)

### **Explosive** 💥
- **Color**: Orange (3)
- **Health**: 1
- **Energy Cost**: +6
- **Effect**: Fires explosive projectiles with area damage
- **Fire Rate**: Every 2 seconds (120 frames)
- **Projectile**: Pulsing orange/red bullets (3x2 size)
- **Explosion**:
  - **Auto-Detonation**: Explodes after 1 second if no impact (reduced from 2s)
  - **Damage Radius**: 25 pixels (base), 40 with synergy
  - **Visual Effect**: Multi-ring explosion (Red/Orange/Yellow)
  - **Area Damage**: 2 damage to all enemies in radius
- **Rarity**: 10% (Rare)

---

## Special Parts

### **Core** 💖
- **Color**: Yellow (14)
- **Health**: 1
- **Energy Cost**: 0 (Free)
- **Effect**: **Extra Life System**
  - When destroyed: Restores all damaged parts to full health
  - Grants 3 seconds of immunity
  - Core is consumed in the process
- **Game Over**: Only when no living parts remain (not when cores are gone)
- **Rarity**: 5% (Very Rare)

### **Dodge** 🏃
- **Color**: Purple (1)
- **Health**: 1
- **Energy Cost**: +3
- **Effect**: Directional dodge with invincibility frames
- **Dodge Distance**: 30 + (5 × dodge part count) pixels
- **Activation**: Arrow keys during combat
- **Rarity**: 25% (Uncommon)

### **Shield** 🛡️
- **Color**: Light Grey (13)
- **Health**: 3
- **Energy Cost**: +4
- **Effect**: High-health defensive part with regeneration
- **Rarity**: 20% (Uncommon)

### **Magnet** 🧲
- **Color**: Green (6)
- **Health**: 1
- **Energy Cost**: +2
- **Effect**: Enhances scrap collection
- **Collection Radius**: 20 + (15 × magnet count) pixels
- **Attraction Range**: 2× collection radius with pull force
- **Pull Force**: 2 + magnet count
- **Rarity**: 40% (Common)

### **Repulsor** 🌊
- **Color**: Cyan (11)
- **Health**: 1
- **Energy Cost**: +4 (Recently buffed from +6)
- **Effect**: Area-of-effect enemy repulsion and damage
- **Pulse Interval**: 2 seconds (Recently buffed from 3s)
- **Base Stats**: 80 radius, 60 push force
- **Scaling**: Multiple repulsors stack
  - +15 radius per additional repulsor
  - +10 force per additional repulsor
- **Damage**: Enemies within 40% of radius take 1 damage
- **Rarity**: 10% (Recently buffed from 5%)

---

## Advanced Special Parts

### **Hardpoint** 🔧
- **Color**: Orange (3)
- **Health**: 1
- **Energy Cost**: +5
- **Effect**: **Double Parts Per Upgrade** - allows picking 2 parts per round instead of 1
- **Note**: Intentionally overpowered for power fantasy gameplay
- **Rarity**: 15% (Rare) - increased from 5%

### **Relay** 📡
- **Color**: White (12)
- **Health**: 1
- **Energy Cost**: +4
- **Effect**: Amplifies adjacent special parts (implementation varies by synergy)
- **Rarity**: 15% (Rare)

### **Conduit** 🔗
- **Color**: Dark Green (7)
- **Health**: 1
- **Energy Cost**: +3
- **Effect**: Allows synergies to work across gaps
- **Rarity**: 10% (Rare)

### **Catalyst** ⚗️
- **Color**: Dark Blue (8)
- **Health**: 1
- **Energy Cost**: +5
- **Effect**: **Reduces synergy requirements by 1 part**
- **Example**: Triple Shot needs only 2 shooters instead of 3
- **Rarity**: 8% (Rare)

### **Targeting** 🎯
- **Color**: Dark Grey (15)
- **Health**: 1
- **Energy Cost**: +6
- **Effect**: **Makes ALL projectiles homing** (extremely powerful)
- **Rarity**: 3% (Very Rare)

---

## Synergy System

### **Weapon Synergies**

#### **Triple Shot** (Shooter Line)
- **Requirements**: 3 shooters in a line
- **Catalyst Reduction**: 2 shooters with catalyst
- **Effect**: Spread shot with 30° angle
- **Result**: Each shooter fires 3 bullets in spread pattern

#### **Focused Beam** (Laser Adjacent)
- **Requirements**: 2 lasers adjacent
- **Catalyst Reduction**: Cannot be reduced further
- **Effect**: Piercing shots with 1.5× damage
- **Result**: Laser shots penetrate through multiple enemies

#### **Crossfire** (Shooter Cross)
- **Requirements**: 5 shooters in cross formation (center + 4 arms)
- **Catalyst Reduction**: Pattern-specific, cannot use catalyst
- **Effect**: Fires in 4 directions with increased bullet speed
- **Result**: Center shooter fires in all cardinal directions

#### **Missile Swarm** (Homing Cluster)
- **Requirements**: 3+ homing parts in cluster
- **Catalyst Reduction**: 2 homing with catalyst
- **Effect**: Fires 2 missiles per shot
- **Result**: Each homing part fires multiple seeking missiles

#### **Bombardment** (Explosive Line)
- **Requirements**: 3 explosives in a line
- **Catalyst Reduction**: 2 explosives with catalyst
- **Effect**: 1.5× blast radius
- **Result**: Explosion radius increases from 25 to ~40 pixels

### **Utility Synergies**

#### **Power Core** (Generator Cluster)
- **Requirements**: 3+ generators adjacent
- **Catalyst Reduction**: 2 generators with catalyst
- **Effect**: +2 energy per generator beyond base cost
- **Result**: Massive energy generation scaling

#### **Fortress Wall** (Armor Line)
- **Requirements**: 5 armor in a line
- **Catalyst Reduction**: 4 armor with catalyst
- **Effect**: 50% damage reduction for entire line
- **Result**: Extremely tanky defensive formation

#### **Aegis Protocol** (Shield Adjacent)
- **Requirements**: 2+ shield parts adjacent
- **Catalyst Reduction**: Cannot be reduced further
- **Effect**: Damage immunity windows
- **Timing**: 0.5s immunity, 3s cooldown

#### **Afterburner** (Engine Cluster)
- **Requirements**: 4+ engines in cluster
- **Catalyst Reduction**: 3 engines with catalyst
- **Effect**: Speed burst ability (X button)
- **Boost**: 2.5× speed for 2 seconds

---

## Rarity & Scrap System

### **Rarity Tiers**
- **Common (80%)**: Armor, Engine, Generator, Shooter
- **Uncommon (20-40%)**: Laser (25%), Dodge (25%), Shield (20%), Magnet (40%)
- **Rare (8-15%)**: Homing (15%), Hardpoint (15%), Relay (15%), Conduit (10%), Repulsor (10%), Catalyst (8%)
- **Very Rare (3-10%)**: Explosive (10%), Core (5%), Targeting (3%)

### **Scrap Bonus System**
- **Eligibility**: Parts with ≤30% base rarity get scrap bonuses
- **Bonus Rate**: +2% chance per scrap collected
- **Maximum**: 95% chance cap
- **Effect**: Makes rare parts more accessible as you progress

### **Smart Generator Spawns**
- **Trigger**: When below 20% energy remaining
- **Effect**: Generators become 5× more likely to appear
- **Purpose**: Prevents energy deadlock situations

---

## Balance Notes

### **Recent Buffs (Latest Update)**

#### **Engine Improvements**
- Cost reduced from 2 → 1 energy
- Now provides meaningful movement speed boost
- Much more viable for mobility builds

#### **Core Rework**
- Changed from liability to asset
- Extra life mechanic makes cores highly valuable
- No longer causes immediate game over

#### **Repulsor Buffs**
- Cost reduced from 6 → 4 energy
- Pulse rate increased (3s → 2s)
- Rarity improved (5% → 10%)
- Added damage component
- Multiple repulsors now stack effectively

#### **Explosive Enhancements**
- Auto-detonation after 1 second (reduced from 2s)
- Visual explosion effects show damage radius
- Pulsing bullet appearance
- No more wasted shots

### **Intentional Power Level**
- **Hardpoint** remains extremely powerful for power fantasy gameplay
- **Targeting** is intentionally game-changing when found
- **Generator synergies** can create massive energy economies
- Game embraces "become OP" philosophy rather than strict balance

### **Known Synergy Interactions**
- **Catalyst** + **Multiple Synergies**: Can enable multiple reduced-requirement synergies
- **Targeting** + **Any Weapon**: Makes every projectile homing (including explosives)
- **Relay** + **Special Parts**: Amplification effects vary by specific synergy
- **Conduit** + **Gap Formations**: Allows creative ship layouts

---

## Tips for New Players

1. **Energy Management**: Always ensure positive energy balance with generators
2. **Core Value**: Cores are now extremely valuable - prioritize them when available
3. **Synergy Planning**: Plan ship layout for synergy formations early
4. **Catalyst Strategy**: Catalyst can enable multiple synergies simultaneously
5. **Mobility Matters**: Don't underestimate engine speed for survival
6. **Explosive Tactics**: Use auto-detonation for area denial
7. **Scrap Collection**: Collect scrap to improve rare part spawn rates

---

## Advanced Strategies

### **Energy Economy Builds**
- Rush generator clusters for massive energy generation
- Enables high-cost part spam builds
- Catalyst reduces generator requirements to 2

### **Weapon Platform Builds**
- Hardpoint → Double parts per round → Exponential scaling
- Focus on weapon synergies with catalyst support
- Targeting makes any weapon setup extremely powerful

### **Tank Builds**
- Core for extra lives + Shield/Armor walls
- Aegis Protocol for immunity windows
- Repulsors for area denial

### **Speed Builds**
- Engine clusters for movement + Afterburner
- Dodge parts for invincibility frames
- High mobility survival strategy

*Last Updated: Latest balance patch with hardpoint availability buff (5% → 15%) and explosive timing improvement (2s → 1s)*