-- title:   Shapeship
-- author:  Carl Lange
-- desc:    Build your ship from parts and blast through space! R-Type meets ship building.
-- site:
-- license: MIT License
-- version: 0.1
-- script:  lua

-- TIC-80 Color Palette Reference:
-- 0=Black(1A1C2C) 1=Purple(5D275D) 2=Red(B13E53) 3=Orange(EF7D57)
-- 4=Yellow(FFCD75) 5=Light Green(A7F070) 6=Green(38B764) 7=Dark Green(257179)
-- 8=Dark Blue(29366F) 9=Blue(3B5DC9) 10=Light Blue(41A6F6) 11=Cyan(73EFF7)
-- 12=White(F4F4F4) 13=Light Grey(94B0C2) 14=Grey(566C86) 15=Dark Grey(333C57)

-- Part type definitions - easily extensible
local pixel_types = {
    armor = {
        color = 14,      -- Grey
        health = 2,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        energy_cost = 1,
        special_effect = nil,
        rarity = 80, -- 80% base chance
        name = "Armor"
    },
    engine = {
        color = 9,       -- Blue
        health = 1,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        energy_cost = 1, -- Cheaper!
        special_effect = "movement_speed", -- Boost movement speed
        rarity = 80, -- 80% base chance
        name = "Engine"
    },
    shooter = {
        color = 2,       -- Red
        health = 1,
        can_shoot = true,
        shoot_interval = 36, -- 0.6 seconds at 60fps
        is_core = false,
        energy_cost = 3,
        special_effect = nil,
        rarity = 80, -- 80% base chance
        name = "Shooter"
    },
    laser = {
        color = 10,      -- Light Blue
        health = 1,
        can_shoot = true,
        shoot_interval = 20,
        is_core = false,
        energy_cost = 4,
        special_effect = nil,
        rarity = 25, -- 25% base chance
        name = "Laser"
    },
    dodge = {
        color = 1,       -- Purple
        health = 1,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        energy_cost = 3,
        special_effect = "dodge", -- Provides directional dodge with iframes
        rarity = 25, -- 25% base chance
        name = "Dodge"
    },
    generator = {
        color = 4,       -- Yellow
        health = 1,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        energy_cost = -3, -- Provides energy instead of consuming it
        special_effect = nil,
        rarity = 80, -- 80% base chance
        name = "Generator"
    },
    hardpoint = {
        color = 3,       -- Orange
        health = 1,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        energy_cost = 5,
        special_effect = "double_pick", -- Allows picking 2 parts per round
        rarity = 15, -- 15% base chance (increased from 5%)
        name = "Hardpoint"
    },
    repulsor = {
        color = 11,      -- Cyan
        health = 1,
        can_shoot = false,
        shoot_interval = 120, -- 2 seconds at 60fps for pulse timing (faster!)
        is_core = false,
        energy_cost = 4, -- Reduced from 6 to 4
        special_effect = "repulse", -- Pushes enemies away every 2 seconds
        rarity = 10, -- Increased from 5% to 10% (more common)
        name = "Repulsor"
    },
    homing = {
        color = 5,       -- Light Green
        health = 1,
        can_shoot = true,
        shoot_interval = 90, -- 1.5 seconds at 60fps
        is_core = false,
        energy_cost = 5,
        special_effect = nil,
        rarity = 15, -- 15% base chance
        name = "Homing"
    },
    explosive = {
        color = 3,       -- Orange
        health = 1,
        can_shoot = true,
        shoot_interval = 120, -- 2 seconds at 60fps
        is_core = false,
        energy_cost = 6,
        special_effect = nil,
        rarity = 10, -- 10% base chance
        name = "Explosive"
    },
    shield = {
        color = 13,      -- Light Grey
        health = 3,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        energy_cost = 4,
        special_effect = "shield", -- Provides shield regeneration
        rarity = 20, -- 20% base chance
        name = "Shield"
    },
    core = {
        color = 14,      -- Yellow - distinctive core color
        health = 1,      -- Fragile but critical
        can_shoot = false,
        shoot_interval = 0,
        is_core = true,  -- Critical part - game over if all cores destroyed
        energy_cost = 0, -- Free - rarity is the limiting factor
        special_effect = nil,
        rarity = 5,      -- Very rare - 5% base chance
        name = "Core"
    },
    magnet = {
        color = 6,       -- Green
        health = 1,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        energy_cost = 2,
        special_effect = "magnet", -- Attracts scrap from farther away
        rarity = 40,     -- 40% base chance
        name = "Magnet"
    },
    relay = {
        color = 12,      -- White
        health = 1,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        energy_cost = 4,
        special_effect = "relay", -- Amplifies adjacent special parts
        rarity = 15,     -- 15% base chance
        name = "Relay"
    },
    conduit = {
        color = 7,       -- Dark Green
        health = 1,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        energy_cost = 3,
        special_effect = "conduit", -- Allows synergies across gaps
        rarity = 10,     -- 10% base chance
        name = "Conduit"
    },
    catalyst = {
        color = 8,       -- Dark Blue
        health = 1,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        energy_cost = 5,
        special_effect = "catalyst", -- Reduces synergy requirements
        rarity = 8,      -- 8% base chance
        name = "Catalyst"
    },
    targeting = {
        color = 15,      -- Dark Grey
        health = 1,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        energy_cost = 6,
        special_effect = "targeting", -- Makes all projectiles homing
        rarity = 3,      -- 3% base chance - very rare
        name = "Targeting"
    }
}

-- Enemy type definitions
local enemy_types = {
    grunt = {
        color = 2,      -- Red
        health = 1,
        speed = 0.5,
        size = 8,
        score = 100,
        movement = "straight",
        spawn_weight = 100
    },
    fast = {
        color = 3,      -- Orange
        health = 1,
        speed = 1.2,
        size = 6,
        score = 150,
        movement = "straight",
        spawn_weight = 60
    },
    zigzag = {
        color = 4,      -- Yellow
        health = 1,
        speed = 0.7,
        size = 8,
        score = 200,
        movement = "zigzag",
        spawn_weight = 40
    },
    tank = {
        color = 1,      -- Purple
        health = 3,
        speed = 0.3,
        size = 12,
        score = 300,
        movement = "straight",
        spawn_weight = 20
    },
    hunter = {
        color = 9,      -- Blue
        health = 2,
        speed = 0.8,
        size = 10,
        score = 250,
        movement = "homing",
        spawn_weight = 30
    }
}

-- Display constants
local GAME_SHIP_SCALE = 0.5 -- Ship scale during gameplay (3x3 pixels per part)
-- TODO: Consider dynamic scaling based on ship size or game state

-- Grid constants
local GRID_WIDTH = 64  -- Grid width in cells
local GRID_HEIGHT = 64 -- Grid height in cells

-- Game state
local game = {
    state = "menu",     -- menu, building, playing, upgrading, gameover
    level = 1,
    score = 0,
    lives = 3,
    timer = 0,
    round_timer = 0,
    round_duration = 1800, -- 30 seconds at 60fps
    enemies_spawned = 0,
    next_enemy_spawn = 120, -- 2 seconds at 60fps
    spawn_rate = 120, -- Base spawn rate
    difficulty_multiplier = 1.0,
    parts_per_upgrade = 1, -- Can be increased by special effects
    max_parts_per_upgrade = 2
}

-- Player ship
local player = {
    x = 30, -- Moved further left to utilize extra space from scaling
    y = 60,
    pixels = {},
    last_shoot_times = {},
    speed = 1.5,
    base_energy = 20,    -- Starting energy budget
    energy_bonus = 0,    -- Additional energy from upgrades
    scrap_collected = 0, -- Scrap for increasing part rarity
    immunity_time = 0,   -- Frames of damage immunity remaining
    speed_burst_time = 0, -- Frames of speed burst remaining
    dodge_time = 0,      -- Frames of active dodge remaining
    dodge_iframes = 0    -- Frames of dodge invincibility remaining
}

-- Game objects
local bullets = {}
local enemies = {}
local scrap_drops = {}
local explosions = {} -- Visual explosion effects
local upgrade_options = {}

-- Building interface
local building = {
    dragging = false,
    drag_pixel = nil,
    drag_source = "", -- "palette" or "ship"
    drag_source_index = 0,
    mouse_grid_x = 0,
    mouse_grid_y = 0,
    ship_area = {x = 10, y = 10, w = 150, h = 120}, -- Larger ship area
    palette_area = {x = 170, y = 10, w = 60, h = 120}, -- Adjusted palette position
    available_parts = {"engine", "armor", "shooter", "laser", "dodge", "generator", "hardpoint", "repulsor", "magnet", "relay", "conduit", "catalyst", "targeting"},
    upgrade_mode = false,
    parts_added = 0,
    max_parts_to_add = 1,
    undo_state = nil, -- Backup of ship state before changes
    is_initial = false,
    zoom_level = 1.0, -- Zoom factor for building grid (1.0 = normal, 1.5 = 150%, etc.)
    grid_offset_x = 0, -- Pan offset for zoomed view
    grid_offset_y = 0
}

-- Initialize starting ship configuration
function init_ship()
    -- Reset energy bonus and scrap (except when called from menu)
    player.energy_bonus = 0
    if game.state == "menu" then
        player.scrap_collected = 0
    end

    -- Initialize synergies
    init_synergies()

    player.pixels = {
        -- Starting 3x3 configuration with generator (centered in 64x64 grid):
        -- Total cost: 5*armor(1) + core(0) + generator(-3) + shooter(3) = 3 energy
        -- a a
        -- c g s
        -- a a
        {x=30, y=30, type="armor", health=pixel_types.armor.health},
        {x=31, y=30, type="armor", health=pixel_types.armor.health},
        {x=30, y=31, type="core", health=pixel_types.core.health},
        {x=31, y=31, type="generator", health=pixel_types.generator.health},
        {x=32, y=31, type="shooter", health=pixel_types.shooter.health},
        {x=30, y=32, type="armor", health=pixel_types.armor.health},
        {x=31, y=32, type="armor", health=pixel_types.armor.health}
    }

    -- Initialize shoot timers for all parts
    for i, pixel in ipairs(player.pixels) do
        player.last_shoot_times[i] = 0
    end
end

-- Main game loop
function TIC()
    game.timer = game.timer + 1

    if game.state == "menu" then
        update_menu()
        draw_menu()
    elseif game.state == "building" then
        update_building()
        draw_building()
    elseif game.state == "playing" then
        update_game()
        draw_game()
    elseif game.state == "upgrading" then
        update_upgrading()
        draw_upgrading()
    elseif game.state == "gameover" then
        update_gameover()
        draw_gameover()
    end
end

-- === MENU STATE ===
function update_menu()
    local mx, my, left = mouse()

    if btnp(4) or left then -- A button or mouse click
        game.state = "upgrading"
        init_ship()
        start_initial_upgrade()
    end
end

function draw_menu()
    cls(0) -- Black background
    print("SHAPESHIP", 80, 50, 12, false, 2) -- White text
    print("Click or Press A to start", 60, 80, 13) -- Light grey text
end

-- === PLAYING STATE ===
function update_game()
    -- Calculate movement speed based on engine count
    local engine_count = count_parts_of_type("engine")
    local movement_speed = 1.0 + (engine_count - 1) * 0.3 -- Base 1.0, +0.3 per additional engine

    -- Check for speed burst activation (X button)
    if btnp(6) and player.speed_burst_time <= 0 then -- X button
        -- Check if player has afterburner synergy
        local has_afterburner = false
        if active_synergies then
            for synergy_id, synergy_data in pairs(active_synergies) do
                if synergy_data.definition.effects.speed_burst then
                    has_afterburner = true
                    player.speed_burst_time = synergy_data.definition.effects.burst_duration or 180 -- 3 seconds
                    break
                end
            end
        end
    end

    -- Check for dodge activation (B button)
    if btnp(5) then -- B button
        -- Find the first available dodge part (not on cooldown)
        local available_dodge = nil
        for _, pixel in ipairs(player.pixels) do
            if pixel.health > 0 and pixel.type == "dodge" and (pixel.dodge_cooldown or 0) <= 0 then
                available_dodge = pixel
                break
            end
        end

        if available_dodge then
            -- Determine dodge direction based on held movement buttons
            local dodge_direction = {x = 0, y = 0}
            if btn(0) then dodge_direction.y = -1 end -- Up
            if btn(1) then dodge_direction.y = 1 end  -- Down
            if btn(2) then dodge_direction.x = -1 end -- Left
            if btn(3) then dodge_direction.x = 1 end  -- Right

            -- If no direction held, dodge backwards (left)
            if dodge_direction.x == 0 and dodge_direction.y == 0 then
                dodge_direction.x = -1
            end

            -- Perform dodge
            local dodge_distance = 35 -- Fixed distance per dodge
            player.x = player.x + dodge_direction.x * dodge_distance
            player.y = player.y + dodge_direction.y * dodge_distance

            -- Keep player in bounds after dodge
            player.x = math.max(-20, math.min(200, player.x))
            player.y = math.max(-12, math.min(124, player.y))

            -- Set dodge state
            player.dodge_time = 15 -- 0.25 seconds of enhanced movement
            player.dodge_iframes = 30 -- 0.5 seconds of invincibility

            -- Put this specific dodge part on cooldown
            available_dodge.dodge_cooldown = 120 -- 2 seconds cooldown per part
        end
    end

    -- Apply speed burst multiplier
    if player.speed_burst_time > 0 then
        movement_speed = movement_speed * 2.5 -- 2.5x speed during burst
    end

    -- Player movement (allow ship to reach screen edges with scaled size)
    -- With 0.5 scale, parts are 3 pixels. Top parts at grid y=4 = 12 pixels
    -- To reach screen top (y=0), player.y needs to be -12
    local scaled_bound = 12 -- 4 * 6 * 0.5
    if btn(0) and player.y > -scaled_bound then player.y = player.y - movement_speed end
    if btn(1) and player.y < 124 then player.y = player.y + movement_speed end -- 136 - 12
    if btn(2) and player.x > -20 then player.x = player.x - movement_speed end -- Adjusted for smaller ship
    if btn(3) and player.x < 200 then player.x = player.x + movement_speed end -- Even more movement room

    -- Shooting
    update_shooting()

    -- Enemy spawning
    update_enemy_spawning()

    -- Update bullets
    update_bullets()

    -- Update explosions
    update_explosions()

    -- Update enemies
    update_enemies()

    -- Update scrap drops
    update_scrap_drops()

    -- Collision detection
    update_collisions()

    -- Update player special effects
    if player.immunity_time > 0 then
        player.immunity_time = player.immunity_time - 1
    end
    if player.speed_burst_time > 0 then
        player.speed_burst_time = player.speed_burst_time - 1
    end
    -- Update individual dodge part cooldowns
    for _, pixel in ipairs(player.pixels) do
        if pixel.type == "dodge" and pixel.dodge_cooldown and pixel.dodge_cooldown > 0 then
            pixel.dodge_cooldown = pixel.dodge_cooldown - 1
        end
    end
    if player.dodge_time > 0 then
        player.dodge_time = player.dodge_time - 1
    end
    if player.dodge_iframes > 0 then
        player.dodge_iframes = player.dodge_iframes - 1
    end

    -- Update synergies periodically (every 30 frames for performance)
    if game.timer % 30 == 0 then
        detect_synergies()
    end

    -- Update round timer
    game.round_timer = game.round_timer + 1

    -- Check round completion (survival-based)
    if game.round_timer >= game.round_duration then
        start_upgrade_phase()
    end

    -- Check lose condition - game over only when no living parts remain
    local living_parts = 0
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 then
            living_parts = living_parts + 1
        end
    end

    if living_parts == 0 then
        game.state = "gameover"
    end
end

function update_shooting()
    for i, pixel in ipairs(player.pixels) do
        local pixel_def = pixel_types[pixel.type]
        if pixel.health > 0 then
            if pixel_def.can_shoot and game.timer - player.last_shoot_times[i] >= pixel_def.shoot_interval then
                -- Check for synergy effects affecting this part
                local synergy_effects = get_part_synergy_effects(pixel.x, pixel.y, pixel.type)

                -- Create bullet at part position (match scaled ship)
                local part_size = 6 * GAME_SHIP_SCALE
                local ship_draw_x, ship_draw_y = get_ship_fighting_position()
                local bullet_x = ship_draw_x + pixel.x * part_size + part_size
                local bullet_y = ship_draw_y + pixel.y * part_size + part_size / 2

                -- Check for targeting parts to make bullets homing
                local targeting_count = count_parts_of_type("targeting")

                if synergy_effects.spread_shot then
                    -- Triple shot synergy - fire 3 bullets in a spread
                    local angles = {-synergy_effects.spread_angle, 0, synergy_effects.spread_angle}
                    for _, angle in ipairs(angles) do
                        local rad = math.rad(angle)
                        local bullet = {
                            x = bullet_x,
                            y = bullet_y,
                            speed = 3,
                            type = pixel.type,
                            angle = rad,
                            synergy = "spread_shot"
                        }

                        -- Apply targeting if available
                        if targeting_count > 0 then
                            bullet.homing = true
                            bullet.target = nil
                            bullet.lifetime = 360
                        end

                        table.insert(bullets, bullet)
                    end
                elseif synergy_effects.piercing_shot then
                    -- Laser focus synergy - piercing bullet
                    local bullet = {
                        x = bullet_x,
                        y = bullet_y,
                        speed = 4,
                        type = pixel.type,
                        piercing = true,
                        damage_multiplier = synergy_effects.damage_multiplier or 1,
                        synergy = "piercing_shot"
                    }

                    -- Apply targeting if available
                    if targeting_count > 0 then
                        bullet.homing = true
                        bullet.target = nil
                        bullet.lifetime = 360
                    end

                    table.insert(bullets, bullet)
                elseif synergy_effects.cross_fire then
                    -- Cross synergy - fire in 4 directions
                    local cross_directions = {
                        {angle = 0, name = "right"},      -- Right (normal)
                        {angle = 90, name = "up"},        -- Up
                        {angle = 180, name = "left"},     -- Left
                        {angle = 270, name = "down"}      -- Down
                    }

                    for _, dir in ipairs(cross_directions) do
                        local rad = math.rad(dir.angle)
                        local bullet = {
                            x = bullet_x,
                            y = bullet_y,
                            speed = synergy_effects.bullet_speed or 3,
                            type = pixel.type,
                            angle = rad,
                            synergy = "cross_fire",
                            direction = dir.name
                        }

                        -- Apply targeting if available
                        if targeting_count > 0 then
                            bullet.homing = true
                            bullet.target = nil
                            bullet.lifetime = 360
                        end

                        table.insert(bullets, bullet)
                    end
                elseif pixel.type == "homing" then
                    -- Homing missile(s)
                    local missile_count = 1
                    if synergy_effects.multi_missile then
                        missile_count = synergy_effects.missile_count or 3
                    end

                    for m = 1, missile_count do
                        -- Spread multiple missiles slightly
                        local spread_offset = 0
                        if missile_count > 1 then
                            spread_offset = (m - (missile_count + 1) / 2) * 4 -- 4 pixel spacing
                        end

                        table.insert(bullets, {
                            x = bullet_x + spread_offset,
                            y = bullet_y,
                            speed = 2,
                            type = pixel.type,
                            homing = true,
                            target = nil, -- Will be assigned when updating
                            lifetime = 300 -- 5 seconds max
                        })
                    end
                elseif pixel.type == "explosive" then
                    -- Explosive projectile
                    local explosion_radius = 25
                    if synergy_effects.enhanced_explosion then
                        explosion_radius = synergy_effects.explosion_radius or 40
                    end

                    local bullet = {
                        x = bullet_x,
                        y = bullet_y,
                        speed = 2.5,
                        type = pixel.type,
                        explosive = true,
                        explosion_radius = explosion_radius,
                        explosive_timer = 60 -- 1 second at 60fps
                    }

                    -- Apply targeting if available (homing explosive bullets!)
                    if targeting_count > 0 then
                        bullet.homing = true
                        bullet.target = nil
                        bullet.lifetime = 360
                    end

                    table.insert(bullets, bullet)
                else
                    -- Normal bullets
                    if targeting_count > 0 then
                        -- Normal bullet becomes homing
                        table.insert(bullets, {
                            x = bullet_x,
                            y = bullet_y,
                            speed = 3,
                            type = pixel.type,
                            homing = true,
                            target = nil, -- Will be assigned when updating
                            lifetime = 360 -- 6 seconds max (longer than normal homing)
                        })
                    else
                        -- Normal bullet
                        table.insert(bullets, {
                            x = bullet_x,
                            y = bullet_y,
                            speed = 3,
                            type = pixel.type
                        })
                    end
                end

                player.last_shoot_times[i] = game.timer
            elseif pixel_def.special_effect == "repulse" and game.timer - player.last_shoot_times[i] >= pixel_def.shoot_interval then
                -- Repulsor pulse effect
                local ship_draw_x, ship_draw_y = get_ship_fighting_position()
                repulsor_pulse(ship_draw_x + pixel.x * 6 + 3, ship_draw_y + pixel.y * 6 + 3)
                player.last_shoot_times[i] = game.timer
            end
        end
    end
end

function update_enemy_spawning()
    -- Only spawn if round is still active
    if game.round_timer < game.round_duration and game.timer >= game.next_enemy_spawn then
        local enemy_type = select_enemy_type()
        local enemy_def = enemy_types[enemy_type]

        table.insert(enemies, {
            x = 250,
            y = math.random(10, 120),
            type = enemy_type,
            health = enemy_def.health,
            max_health = enemy_def.health,
            speed = enemy_def.speed * game.difficulty_multiplier,
            size = enemy_def.size,
            movement_timer = 0,
            zigzag_direction = 1
        })

        game.enemies_spawned = game.enemies_spawned + 1

        -- Dynamic spawn rate based on difficulty
        local adjusted_spawn_rate = math.max(30, game.spawn_rate / game.difficulty_multiplier)
        game.next_enemy_spawn = game.timer + adjusted_spawn_rate
    end
end

function select_enemy_type()
    -- Create weighted selection based on round level
    local weights = {}
    local total_weight = 0

    for enemy_type, def in pairs(enemy_types) do
        local weight = def.spawn_weight

        -- Adjust weights based on round level
        if enemy_type == "fast" and game.level >= 2 then
            weight = weight * 1.5
        elseif enemy_type == "zigzag" and game.level >= 3 then
            weight = weight * 2
        elseif enemy_type == "tank" and game.level >= 4 then
            weight = weight * 2
        elseif enemy_type == "hunter" and game.level >= 5 then
            weight = weight * 2
        end

        -- Reduce grunt frequency in later rounds
        if enemy_type == "grunt" and game.level > 3 then
            weight = weight * 0.5
        end

        weights[enemy_type] = weight
        total_weight = total_weight + weight
    end

    -- Random selection
    local rand = math.random() * total_weight
    local current_weight = 0

    for enemy_type, weight in pairs(weights) do
        current_weight = current_weight + weight
        if rand <= current_weight then
            return enemy_type
        end
    end

    return "grunt" -- Fallback
end

function update_bullets()
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]

        if bullet.homing then
            -- Homing missile behavior
            bullet.lifetime = bullet.lifetime - 1

            -- Find closest enemy if no target
            if not bullet.target or bullet.target.health <= 0 then
                bullet.target = find_closest_enemy(bullet.x, bullet.y)
            end

            if bullet.target then
                -- Move toward target
                local dx = bullet.target.x + bullet.target.size/2 - bullet.x
                local dy = bullet.target.y + bullet.target.size/2 - bullet.y
                local distance = math.sqrt(dx*dx + dy*dy)

                if distance > 0 then
                    bullet.x = bullet.x + (dx / distance) * bullet.speed
                    bullet.y = bullet.y + (dy / distance) * bullet.speed
                end
            else
                -- No target, move forward
                bullet.x = bullet.x + bullet.speed
            end

            -- Remove if lifetime expired
            if bullet.lifetime <= 0 then
                table.remove(bullets, i)
            end
        elseif bullet.angle then
            -- Angled bullet movement (spread shot)
            bullet.x = bullet.x + bullet.speed * math.cos(bullet.angle)
            bullet.y = bullet.y + bullet.speed * math.sin(bullet.angle)
        else
            -- Normal horizontal movement
            bullet.x = bullet.x + bullet.speed
        end

        -- Handle explosive timer countdown
        if bullet.explosive and bullet.explosive_timer then
            bullet.explosive_timer = bullet.explosive_timer - 1
            if bullet.explosive_timer <= 0 then
                -- Auto-detonate explosive bullet
                create_explosion(bullet.x, bullet.y, bullet.explosion_radius)
                table.remove(bullets, i)
                goto continue -- Skip the rest of the bullet processing
            end
        end

        -- Remove bullets that go off screen (except homing missiles)
        if not bullet.homing and (bullet.x > 250 or bullet.x < -10 or bullet.y > 150 or bullet.y < -10) then
            table.remove(bullets, i)
        end

        ::continue::
    end
end

function update_explosions()
    for i = #explosions, 1, -1 do
        local explosion = explosions[i]

        explosion.lifetime = explosion.lifetime - 1

        -- Remove expired explosions
        if explosion.lifetime <= 0 then
            table.remove(explosions, i)
        end
    end
end

function update_enemies()
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        local enemy_def = enemy_types[enemy.type]

        -- Update movement based on type
        if enemy_def.movement == "straight" then
            enemy.x = enemy.x - enemy.speed
        elseif enemy_def.movement == "zigzag" then
            enemy.x = enemy.x - enemy.speed
            enemy.movement_timer = enemy.movement_timer + 1
            if enemy.movement_timer >= 30 then -- Change direction every 0.5 seconds
                enemy.zigzag_direction = -enemy.zigzag_direction
                enemy.movement_timer = 0
            end
            enemy.y = enemy.y + enemy.zigzag_direction * 1.5
        elseif enemy_def.movement == "homing" then
            -- Move toward player ship center
            local ship_center_x, ship_center_y = get_ship_center_fighting()

            local dx = ship_center_x - enemy.x
            local dy = ship_center_y - enemy.y
            local dist = math.sqrt(dx*dx + dy*dy)

            if dist > 0 then
                enemy.x = enemy.x + (dx / dist) * enemy.speed * 0.7 -- Slower homing
                enemy.y = enemy.y + (dy / dist) * enemy.speed * 0.7
            end

            -- Still move left slowly
            enemy.x = enemy.x - enemy.speed * 0.3
        else
            enemy.x = enemy.x - enemy.speed
        end

        -- Keep enemies in bounds
        enemy.y = math.max(0, math.min(136 - enemy.size, enemy.y))

        -- Remove enemies that go off screen
        if enemy.x < -enemy.size or enemy.x > 250 then
            table.remove(enemies, i)
        end
    end
end

function update_scrap_drops()
    for i = #scrap_drops, 1, -1 do
        local scrap = scrap_drops[i]

        -- Update lifetime
        scrap.lifetime = scrap.lifetime - 1

        -- Remove expired scrap
        if scrap.lifetime <= 0 then
            table.remove(scrap_drops, i)
        else
            -- Check for collection by player ship
            local ship_center_x, ship_center_y = get_ship_center_fighting()

            local dx = scrap.x - ship_center_x
            local dy = scrap.y - ship_center_y
            local distance = math.sqrt(dx * dx + dy * dy)

            -- Calculate collection radius with magnet boost
            local magnet_count = count_parts_of_type("magnet")
            local collection_radius = 20 + (magnet_count * 15) -- Base 20 + 15 per magnet

            -- Magnet attraction force
            if magnet_count > 0 and distance < collection_radius * 2 and distance > collection_radius then
                local pull_force = 2 + magnet_count -- Stronger pull with more magnets
                local pull_x = -(dx / distance) * pull_force
                local pull_y = -(dy / distance) * pull_force
                scrap.x = scrap.x + pull_x
                scrap.y = scrap.y + pull_y
            end

            -- Collection
            if distance < collection_radius then
                player.scrap_collected = player.scrap_collected + 1
                table.remove(scrap_drops, i)
            end
        end
    end
end

function update_collisions()
    -- Bullets vs Enemies
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        local bullet_removed = false

        for j = #enemies, 1, -1 do
            local enemy = enemies[j]
            if bullet.x >= enemy.x and bullet.x <= enemy.x + 8 and
               bullet.y >= enemy.y and bullet.y <= enemy.y + 8 then
                -- Hit!
                local damage = bullet.damage_multiplier or 1
                enemy.health = enemy.health - damage

                -- Handle explosive bullets
                if bullet.explosive then
                    -- Create explosion that damages nearby enemies
                    create_explosion(bullet.x, bullet.y, bullet.explosion_radius)
                    table.remove(bullets, i)
                    bullet_removed = true
                elseif not bullet.piercing then
                    -- Remove bullet unless it's piercing
                    table.remove(bullets, i)
                    bullet_removed = true
                end

                if enemy.health <= 0 then
                    local enemy_def = enemy_types[enemy.type]
                    game.score = game.score + enemy_def.score

                    -- 10% chance to drop scrap
                    if math.random() <= 0.1 then
                        table.insert(scrap_drops, {
                            x = enemy.x + enemy.size / 2,
                            y = enemy.y + enemy.size / 2,
                            lifetime = 600, -- 10 seconds at 60fps
                            collected = false
                        })
                    end

                    table.remove(enemies, j)
                end

                if bullet_removed then
                    break
                end
            end
        end
    end

    -- Enemies vs Ship
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        for j = #player.pixels, 1, -1 do
            local pixel = player.pixels[j]
            if pixel.health > 0 then
                local part_size = 6 * GAME_SHIP_SCALE -- Match visual scale
                local ship_draw_x, ship_draw_y = get_ship_fighting_position()
                local px = ship_draw_x + pixel.x * part_size
                local py = ship_draw_y + pixel.y * part_size
                if enemy.x < px + part_size and enemy.x + 8 > px and
                   enemy.y < py + part_size and enemy.y + 8 > py then
                    -- Ship hit!
                    if player.immunity_time <= 0 and player.dodge_iframes <= 0 then
                        pixel.health = pixel.health - 1

                        -- Check for core destruction - use as extra life
                        if pixel.health <= 0 and pixel_types[pixel.type].is_core then
                            -- Core acts as extra life - restore all ship parts when core is destroyed
                            trace("Core destroyed! Using as extra life...")

                            -- Restore all damaged parts to full health
                            for _, restore_pixel in ipairs(player.pixels) do
                                if restore_pixel.health <= 0 then
                                    restore_pixel.health = pixel_types[restore_pixel.type].health
                                end
                            end

                            -- Grant temporary immunity
                            player.immunity_time = 180 -- 3 seconds of immunity

                            -- Don't restore the core itself - it's consumed as the extra life
                            pixel.health = 0

                            return -- Skip normal damage processing
                        end

                        -- Check for shield synergy - activate immunity on damage
                        local synergy_effects = get_part_synergy_effects(pixel.x, pixel.y, pixel.type)
                        if synergy_effects.damage_immunity then
                            player.immunity_time = synergy_effects.immunity_duration or 120 -- 2 seconds at 60fps
                        end
                    end
                    table.remove(enemies, i)
                    break
                end
            end
        end
    end
end

function draw_game()
    cls(8) -- Dark blue space background

    -- Draw stars
    for i = 0, 20 do
        local star_x = (game.timer * 2 + i * 37) % 240
        local star_y = (i * 23) % 136
        pix(star_x, star_y, 12) -- White stars
    end

    -- Draw player ship (scaled down for better visibility)
    local ship_draw_x, ship_draw_y = get_ship_fighting_position()
    draw_ship(ship_draw_x, ship_draw_y, player.pixels, GAME_SHIP_SCALE)

    -- Draw bullets
    for _, bullet in ipairs(bullets) do
        if bullet.explosive then
            -- Draw explosive bullets differently - pulsing orange
            local pulse = math.sin(game.timer * 0.3) * 0.5 + 0.5
            local color = pulse > 0.5 and 3 or 2 -- Orange/Red pulsing
            rect(bullet.x, bullet.y, 3, 2, color) -- Slightly bigger
        else
            rect(bullet.x, bullet.y, 2, 1, 4) -- Yellow bullets
        end
    end

    -- Draw explosions
    for _, explosion in ipairs(explosions) do
        local life_ratio = explosion.lifetime / explosion.max_lifetime

        -- Expanding circle effect
        local current_radius = explosion.max_radius * (1 - life_ratio * 0.5) -- Start big, shrink slightly

        -- Multiple circles for effect
        local colors = {2, 3, 4} -- Red, Orange, Yellow
        for i, color in ipairs(colors) do
            local offset_radius = current_radius - (i - 1) * 3
            if offset_radius > 0 then
                local alpha = life_ratio * 255 -- Fade out over time
                if alpha > 50 then -- Only draw if visible enough
                    circb(explosion.x, explosion.y, offset_radius, color)
                end
            end
        end
    end

    -- Draw enemies
    for _, enemy in ipairs(enemies) do
        local enemy_def = enemy_types[enemy.type]
        rect(enemy.x, enemy.y, enemy.size, enemy.size, enemy_def.color)

        -- Draw health indicator for damaged enemies
        if enemy.health < enemy.max_health then
            local health_ratio = enemy.health / enemy.max_health
            rect(enemy.x, enemy.y - 3, enemy.size * health_ratio, 1, 5) -- Green health bar
            rect(enemy.x + enemy.size * health_ratio, enemy.y - 3, enemy.size * (1 - health_ratio), 1, 2) -- Red missing health
        end
    end

    -- Draw scrap drops
    for _, scrap in ipairs(scrap_drops) do
        -- Pulsing yellow/orange scrap
        local pulse = math.sin(game.timer * 0.2) * 0.5 + 0.5
        local color = pulse > 0.5 and 4 or 3 -- Yellow/Orange alternating
        rect(scrap.x - 2, scrap.y - 2, 4, 4, color)

        -- Draw collection range hint when close
        local ship_center_x, ship_center_y = get_ship_center_fighting()
        local distance = math.sqrt((scrap.x - ship_center_x)^2 + (scrap.y - ship_center_y)^2)

        if distance < 30 then
            circb(scrap.x, scrap.y, 20, 4) -- Yellow collection radius
        end
    end

    -- UI
    print("Score: " .. game.score, 5, 5, 12) -- White text
    print("Round: " .. game.level, 5, 15, 12) -- White text
    print("Scrap: " .. player.scrap_collected, 5, 25, 4) -- Yellow text

    -- Round timer
    local time_left = math.max(0, game.round_duration - game.round_timer)
    local seconds_left = math.ceil(time_left / 60)
    print("Time: " .. seconds_left .. "s", 5, 35, time_left < 300 and 2 or 12) -- Red when < 5 seconds

    -- Display active synergies
    if active_synergies then
        local synergy_y = 45
        for synergy_id, synergy_data in pairs(active_synergies) do
            local synergy_def = synergy_data.definition
            print(synergy_def.name, 5, synergy_y, 11) -- Cyan text for synergies
            synergy_y = synergy_y + 8
        end
    end
end

-- === UPGRADING STATE ===
function save_ship_state()
    -- Deep copy the current ship state
    building.undo_state = {}
    for i, pixel in ipairs(player.pixels) do
        local saved_pixel = {
            x = pixel.x,
            y = pixel.y,
            type = pixel.type,
            health = pixel.health
        }

        -- Save dodge cooldown for dodge parts
        if pixel.type == "dodge" then
            saved_pixel.dodge_cooldown = pixel.dodge_cooldown or 0
        end

        building.undo_state[i] = saved_pixel
    end
end

function restore_ship_state()
    if building.undo_state then
        -- Restore the saved state
        player.pixels = {}
        for i, pixel in ipairs(building.undo_state) do
            local restored_pixel = {
                x = pixel.x,
                y = pixel.y,
                type = pixel.type,
                health = pixel.health
            }

            -- Restore dodge cooldown for dodge parts
            if pixel.type == "dodge" then
                restored_pixel.dodge_cooldown = pixel.dodge_cooldown or 0
            end

            player.pixels[i] = restored_pixel
        end

        -- Reset building state
        building.parts_added = 0
        building.dragging = false
        building.drag_pixel = nil

        -- Reinitialize systems that depend on ship configuration
        -- Reset shoot timers for all parts
        player.last_shoot_times = {}
        for i, pixel in ipairs(player.pixels) do
            player.last_shoot_times[i] = 0
        end
        detect_synergies()
    end
end

function start_upgrade_phase()
    game.state = "upgrading"

    -- Save current ship state for undo
    save_ship_state()

    -- Apply special effects to determine how many parts can be picked
    apply_special_effects()

    -- Generate 5 random part options using percentage-based rarity
    upgrade_options = {}

    for i = 1, 5 do
        local rand_type = select_random_part()
        local appearance_chance = get_part_appearance_chance(rand_type)

        table.insert(upgrade_options, {
            type = rand_type,
            def = pixel_types[rand_type],
            appearance_chance = appearance_chance
        })
    end

    -- Set up building interface for upgrade mode
    building.dragging = false
    building.drag_pixel = nil
    building.upgrade_mode = true
    building.parts_added = 0
    building.max_parts_to_add = game.parts_per_upgrade
    building.available_parts = {}
    for i = 1, 5 do
        building.available_parts[i] = upgrade_options[i].type
    end
end

function start_initial_upgrade()
    game.state = "upgrading"

    -- Save current ship state for undo
    save_ship_state()

    -- For initial upgrade, offer 5 basic part types
    upgrade_options = {}
    local initial_types = {"armor", "shooter", "generator", "laser", "dodge"}

    for i = 1, 5 do
        table.insert(upgrade_options, {
            type = initial_types[i],
            def = pixel_types[initial_types[i]]
        })
    end

    -- Set up building interface for initial upgrade
    building.dragging = false
    building.drag_pixel = nil
    building.upgrade_mode = true
    building.parts_added = 0
    building.max_parts_to_add = 6
    building.available_parts = {}
    for i = 1, 5 do
        building.available_parts[i] = upgrade_options[i].type
    end
    building.is_initial = true -- Flag to track initial upgrade
end

function update_upgrading()
    local mx, my, left, middle, right = mouse()

    -- Handle right-click undo
    if right then
        restore_ship_state()
        return
    end

    -- Handle zoom controls (X and Y buttons) with cursor-centered zoom
    local mouse_x, mouse_y = mouse()
    local zoom_changed = false
    local old_zoom = building.zoom_level

    if btnp(6) then -- X button - zoom out
        building.zoom_level = math.max(building.zoom_level / 1.2, 0.5) -- Min 0.5x zoom out
        zoom_changed = true
    elseif btnp(7) then -- Y button - zoom in
        building.zoom_level = math.min(building.zoom_level * 1.2, 3.0) -- Max 3x zoom in
        zoom_changed = true
    end

    -- Adjust grid offset to keep cursor position stable during zoom
    if zoom_changed and mouse_x >= building.ship_area.x and mouse_x < building.ship_area.x + building.ship_area.w and
       mouse_y >= building.ship_area.y and mouse_y < building.ship_area.y + building.ship_area.h then

        local old_cell_size = 8 * old_zoom
        local new_cell_size = 8 * building.zoom_level

        -- Get grid positions with old and new cell sizes
        local old_grid_start_x, old_grid_start_y = get_centered_grid_start(old_cell_size)

        -- Calculate world coordinates under cursor before zoom
        local cursor_world_x = (mouse_x - old_grid_start_x) / old_cell_size
        local cursor_world_y = (mouse_y - old_grid_start_y) / old_cell_size

        -- Calculate where those coordinates should be after zoom
        local new_grid_start_x, new_grid_start_y = get_centered_grid_start(new_cell_size)
        local new_cursor_screen_x = new_grid_start_x + cursor_world_x * new_cell_size
        local new_cursor_screen_y = new_grid_start_y + cursor_world_y * new_cell_size

        -- Adjust offset to keep cursor over same world coordinates
        building.grid_offset_x = building.grid_offset_x + (new_cursor_screen_x - mouse_x)
        building.grid_offset_y = building.grid_offset_y + (new_cursor_screen_y - mouse_y)
    end

    -- Handle panning with arrow keys
    local pan_speed = 5 -- pixels per frame
    if btn(0) then building.grid_offset_y = building.grid_offset_y - pan_speed end -- Up
    if btn(1) then building.grid_offset_y = building.grid_offset_y + pan_speed end -- Down
    if btn(2) then building.grid_offset_x = building.grid_offset_x - pan_speed end -- Left
    if btn(3) then building.grid_offset_x = building.grid_offset_x + pan_speed end -- Right

    -- Convert mouse to grid coordinates in ship area (with zoom)
    if mx >= building.ship_area.x and mx < building.ship_area.x + building.ship_area.w and
       my >= building.ship_area.y and my < building.ship_area.y + building.ship_area.h then
        local cell_size = 8 * building.zoom_level
        local grid_start_x, grid_start_y = get_centered_grid_start(cell_size)
        building.mouse_grid_x = math.floor((mx - grid_start_x) / cell_size)
        building.mouse_grid_y = math.floor((my - grid_start_y) / cell_size)
    else
        building.mouse_grid_x = -1
        building.mouse_grid_y = -1
    end

    -- Handle mouse clicks and dragging (interaction always allowed with refreshing parts)
    if left and not building.dragging then
        -- Start dragging from palette
        if mx >= building.palette_area.x and mx < building.palette_area.x + building.palette_area.w and
           my >= building.palette_area.y and my < building.palette_area.y + building.palette_area.h then
            local palette_index = math.floor((my - building.palette_area.y - 10) / 15) + 1
            if palette_index >= 1 and palette_index <= #building.available_parts then
                building.dragging = true
                building.drag_pixel = building.available_parts[palette_index]
                building.drag_source = "palette"
                building.drag_source_index = palette_index
            end
        end
    end

    -- Handle drop
    if not left and building.dragging then
        if building.mouse_grid_x >= 0 and building.mouse_grid_y >= 0 then
            -- Valid drop zone
            if can_place_part(building.mouse_grid_x, building.mouse_grid_y, building.drag_pixel) then
                place_part(building.mouse_grid_x, building.mouse_grid_y, building.drag_pixel)
                building.parts_added = building.parts_added + 1

                -- Replace the used part with a new random one in upgrade mode
                if building.upgrade_mode and building.drag_source == "palette" then
                    building.available_parts[building.drag_source_index] = select_random_part()
                end
            end
        end

        building.dragging = false
        building.drag_pixel = nil
        building.drag_source = ""
        building.drag_source_index = 0
    end

    -- Keyboard controls
    if btnp(4) or (building.parts_added >= building.max_parts_to_add and left) then -- A button or click after adding max parts
        if building.is_initial then
            -- After initial upgrade, start the first round
            building.is_initial = false
            game.state = "playing"
            reset_round()
        else
            next_round()
        end
    end
end

function draw_upgrading()
    cls(15) -- Dark grey background

    -- Title
    if building.is_initial then
        print("SHIP SETUP", 100, 5, 12, false, 1, true)
    else
        print("UPGRADE", 105, 5, 12, false, 1, true)
    end

    -- Ship building area
    rect(building.ship_area.x, building.ship_area.y, building.ship_area.w, building.ship_area.h, 5)
    rectb(building.ship_area.x, building.ship_area.y, building.ship_area.w, building.ship_area.h, 12)
    print("SHIP", building.ship_area.x + 5, building.ship_area.y - 8, 12)

    -- Draw grid in ship area (with zoom and clipping)
    clip(building.ship_area.x, building.ship_area.y, building.ship_area.w, building.ship_area.h)
    local cell_size = 8 * building.zoom_level  -- Remove floor for better alignment
    local grid_start_x, grid_start_y = get_centered_grid_start(cell_size)

    for gx = 0, GRID_WIDTH - 1 do
        for gy = 0, GRID_HEIGHT - 1 do
            local px = grid_start_x + gx * cell_size
            local py = grid_start_y + gy * cell_size

            -- Only draw if visible in the clipped area
            if px + cell_size >= building.ship_area.x and px < building.ship_area.x + building.ship_area.w and
               py + cell_size >= building.ship_area.y and py < building.ship_area.y + building.ship_area.h then

                -- Highlight valid placement positions (only if we haven't added a part yet)
                if building.parts_added == 0 and building.dragging and can_place_part(gx, gy, building.drag_pixel) then
                    rect(px, py, cell_size, cell_size, 3) -- Dark green for valid
                elseif gx == building.mouse_grid_x and gy == building.mouse_grid_y then
                    rect(px, py, cell_size, cell_size, 2) -- Purple for hover
                else
                    rectb(px, py, cell_size, cell_size, 0) -- Dark grid
                end
            end
        end
    end
    clip()

    -- Draw ship parts (with zoom)
    clip(building.ship_area.x, building.ship_area.y, building.ship_area.w, building.ship_area.h)
    draw_ship_in_builder_zoomed(grid_start_x, grid_start_y, cell_size)
    clip()

    -- Pixel palette area
    rect(building.palette_area.x, building.palette_area.y, building.palette_area.w, building.palette_area.h, 5)
    rectb(building.palette_area.x, building.palette_area.y, building.palette_area.w, building.palette_area.h, 12)
    print("PARTS", building.palette_area.x + 5, building.palette_area.y - 8, 12)

    -- Draw available upgrade options
    for i, pixel_type in ipairs(building.available_parts) do
        local px = building.palette_area.x + 10
        local py = building.palette_area.y + 10 + (i-1) * 15
        local pixel_def = pixel_types[pixel_type]
        local upgrade_option = upgrade_options[i]

        -- Skip if currently dragging this part
        if not (building.dragging and building.drag_source == "palette" and building.drag_source_index == i) then
            -- Check if we can afford this part
            local can_afford = has_sufficient_energy(pixel_type)
            local color = can_afford and pixel_def.color or 0
            local text_color = can_afford and 15 or 8

            rect(px, py, 8, 8, color)

            -- Draw rarity border based on appearance chance
            if upgrade_option and upgrade_option.appearance_chance then
                local chance = upgrade_option.appearance_chance
                local rarity_color = 13 -- Default light grey for common (>50%)

                if chance <= 10 then
                    rarity_color = 12 -- White for ultra rare
                elseif chance <= 25 then
                    rarity_color = 3 -- Orange for rare
                elseif chance <= 50 then
                    rarity_color = 5 -- Light green for uncommon
                end

                rectb(px, py, 8, 8, rarity_color)
            end

            print(pixel_def.name, px + 12, py, text_color, false, 1, true)

            -- Show energy cost
            local cost_text = pixel_def.energy_cost >= 0 and ("+" .. pixel_def.energy_cost) or tostring(pixel_def.energy_cost)
            print(cost_text, px + 12, py + 7, text_color, false, 1, true)
        end
        -- Note: Removed greyout logic - parts now refresh when used
    end

    -- Draw dragged part following mouse
    if building.dragging then
        local mx, my = mouse()
        local pixel_def = pixel_types[building.drag_pixel]

        -- Snap to grid when over ship area for better visual feedback
        if mx >= building.ship_area.x and mx < building.ship_area.x + building.ship_area.w and
           my >= building.ship_area.y and my < building.ship_area.y + building.ship_area.h and
           building.mouse_grid_x >= 0 and building.mouse_grid_y >= 0 then
            local cell_size = 8 * building.zoom_level
            local grid_start_x = building.ship_area.x + 10 - building.grid_offset_x
            local grid_start_y = building.ship_area.y + 10 - building.grid_offset_y
            local snap_x = grid_start_x + building.mouse_grid_x * cell_size
            local snap_y = grid_start_y + building.mouse_grid_y * cell_size
            rect(snap_x, snap_y, cell_size, cell_size, pixel_def.color)
        else
            rect(mx - 4, my - 4, 8, 8, pixel_def.color)
        end
    end

    -- Status bar
    local energy = get_energy_status()
    local energy_color = energy.at_limit and 2 or (energy.remaining <= 2 and 4 or 12)
    print(energy.used .. "/" .. energy.total .. "E", 10, 130, energy_color)


    -- Status and controls
    if building.parts_added < building.max_parts_to_add then
        local remaining = building.max_parts_to_add - building.parts_added
        if building.max_parts_to_add == 1 then
            print("Choose 1 part (parts refresh)", 10, 120, 12)
        else
            print("Choose " .. remaining .. " more (parts refresh)", 10, 120, 12)
        end
    else
        print("Press A to continue", 10, 120, 12)
    end
end

-- === BUILDING STATE ===
function update_building()
    local mx, my, left, middle, right = mouse()

    -- Handle right-click undo
    if right then
        restore_ship_state()
        return
    end

    -- Handle zoom controls (X and Y buttons) with cursor-centered zoom
    local mouse_x, mouse_y = mouse()
    local zoom_changed = false
    local old_zoom = building.zoom_level

    if btnp(6) then -- X button - zoom out
        building.zoom_level = math.max(building.zoom_level / 1.2, 0.5) -- Min 0.5x zoom out
        zoom_changed = true
    elseif btnp(7) then -- Y button - zoom in
        building.zoom_level = math.min(building.zoom_level * 1.2, 3.0) -- Max 3x zoom in
        zoom_changed = true
    end

    -- Adjust grid offset to keep cursor position stable during zoom
    if zoom_changed and mouse_x >= building.ship_area.x and mouse_x < building.ship_area.x + building.ship_area.w and
       mouse_y >= building.ship_area.y and mouse_y < building.ship_area.y + building.ship_area.h then

        local old_cell_size = 8 * old_zoom
        local new_cell_size = 8 * building.zoom_level

        -- Get grid positions with old and new cell sizes
        local old_grid_start_x, old_grid_start_y = get_centered_grid_start(old_cell_size)

        -- Calculate world coordinates under cursor before zoom
        local cursor_world_x = (mouse_x - old_grid_start_x) / old_cell_size
        local cursor_world_y = (mouse_y - old_grid_start_y) / old_cell_size

        -- Calculate where those coordinates should be after zoom
        local new_grid_start_x, new_grid_start_y = get_centered_grid_start(new_cell_size)
        local new_cursor_screen_x = new_grid_start_x + cursor_world_x * new_cell_size
        local new_cursor_screen_y = new_grid_start_y + cursor_world_y * new_cell_size

        -- Adjust offset to keep cursor over same world coordinates
        building.grid_offset_x = building.grid_offset_x + (new_cursor_screen_x - mouse_x)
        building.grid_offset_y = building.grid_offset_y + (new_cursor_screen_y - mouse_y)
    end

    -- Handle panning with arrow keys
    local pan_speed = 5 -- pixels per frame
    if btn(0) then building.grid_offset_y = building.grid_offset_y - pan_speed end -- Up
    if btn(1) then building.grid_offset_y = building.grid_offset_y + pan_speed end -- Down
    if btn(2) then building.grid_offset_x = building.grid_offset_x - pan_speed end -- Left
    if btn(3) then building.grid_offset_x = building.grid_offset_x + pan_speed end -- Right

    -- Convert mouse to grid coordinates in ship area (with zoom)
    if mx >= building.ship_area.x and mx < building.ship_area.x + building.ship_area.w and
       my >= building.ship_area.y and my < building.ship_area.y + building.ship_area.h then
        local cell_size = 8 * building.zoom_level
        local grid_start_x, grid_start_y = get_centered_grid_start(cell_size)
        building.mouse_grid_x = math.floor((mx - grid_start_x) / cell_size)
        building.mouse_grid_y = math.floor((my - grid_start_y) / cell_size)
    else
        building.mouse_grid_x = -1
        building.mouse_grid_y = -1
    end

    -- Handle mouse clicks and dragging
    if left and not building.dragging then
        -- Start dragging from palette
        if mx >= building.palette_area.x and mx < building.palette_area.x + building.palette_area.w and
           my >= building.palette_area.y and my < building.palette_area.y + building.palette_area.h then
            local palette_index = math.floor((my - building.palette_area.y - 10) / 15) + 1
            if palette_index >= 1 and palette_index <= #building.available_pixels then
                building.dragging = true
                building.drag_pixel = building.available_pixels[palette_index]
                building.drag_source = "palette"
                building.drag_source_index = palette_index
            end
        -- Start dragging from ship
        elseif building.mouse_grid_x >= 0 and building.mouse_grid_y >= 0 then
            local pixel_at_pos = get_part_at_position(building.mouse_grid_x, building.mouse_grid_y)
            if pixel_at_pos then
                building.dragging = true
                building.drag_pixel = pixel_at_pos.type
                building.drag_source = "ship"
                building.drag_source_index = get_part_index(building.mouse_grid_x, building.mouse_grid_y)
            end
        end
    end

    -- Handle drop
    if not left and building.dragging then
        if building.mouse_grid_x >= 0 and building.mouse_grid_y >= 0 then
            -- Valid drop zone
            if can_place_part(building.mouse_grid_x, building.mouse_grid_y, building.drag_pixel) then
                place_part(building.mouse_grid_x, building.mouse_grid_y, building.drag_pixel)

                -- Replace the used part with a new random one when dragging from palette
                if building.drag_source == "palette" then
                    building.available_pixels[building.drag_source_index] = select_random_part()
                -- If dragging from ship, remove the original
                elseif building.drag_source == "ship" then
                    remove_part_at_index(building.drag_source_index)
                end
            end
        elseif building.drag_source == "ship" then
            -- Dragged ship part outside - remove it (unless it's the engine)
            local pixel = player.pixels[building.drag_source_index]
            if pixel and not pixel_types[pixel.type].is_core then
                remove_part_at_index(building.drag_source_index)
            end
        end

        building.dragging = false
        building.drag_pixel = nil
        building.drag_source = ""
        building.drag_source_index = 0
    end

    -- Keyboard controls
    if btnp(4) then -- A button - start game
        if has_core_part() then
            game.state = "playing"
            reset_round()
        end
    end
end

function draw_building()
    cls(7) -- Dark green background

    -- Title
    print("BUILD", 110, 5, 15, false, 1, true)

    -- Ship building area
    rect(building.ship_area.x, building.ship_area.y, building.ship_area.w, building.ship_area.h, 5)
    rectb(building.ship_area.x, building.ship_area.y, building.ship_area.w, building.ship_area.h, 12)
    print("SHIP", building.ship_area.x + 5, building.ship_area.y - 8, 12)

    -- Draw grid in ship area (with zoom and clipping)
    clip(building.ship_area.x, building.ship_area.y, building.ship_area.w, building.ship_area.h)
    local cell_size = 8 * building.zoom_level  -- Remove floor for better alignment
    local grid_start_x, grid_start_y = get_centered_grid_start(cell_size)

    for gx = 0, GRID_WIDTH - 1 do
        for gy = 0, GRID_HEIGHT - 1 do
            local px = grid_start_x + gx * cell_size
            local py = grid_start_y + gy * cell_size

            -- Only draw if visible in the clipped area
            if px + cell_size >= building.ship_area.x and px < building.ship_area.x + building.ship_area.w and
               py + cell_size >= building.ship_area.y and py < building.ship_area.y + building.ship_area.h then

                -- Highlight valid placement positions
                if building.dragging and can_place_part(gx, gy, building.drag_pixel) then
                    rect(px, py, cell_size, cell_size, 3) -- Dark green for valid
                elseif gx == building.mouse_grid_x and gy == building.mouse_grid_y then
                    rect(px, py, cell_size, cell_size, 2) -- Purple for hover
                else
                    rectb(px, py, cell_size, cell_size, 0) -- Dark grid
                end
            end
        end
    end

    -- Draw ship parts (with zoom)
    draw_ship_in_builder_zoomed(grid_start_x, grid_start_y, cell_size)
    clip()

    -- Pixel palette area
    rect(building.palette_area.x, building.palette_area.y, building.palette_area.w, building.palette_area.h, 5)
    rectb(building.palette_area.x, building.palette_area.y, building.palette_area.w, building.palette_area.h, 12)
    print("PARTS", building.palette_area.x + 5, building.palette_area.y - 8, 12)

    -- Draw available parts
    for i, pixel_type in ipairs(building.available_parts) do
        local px = building.palette_area.x + 10
        local py = building.palette_area.y + 10 + (i-1) * 16
        local pixel_def = pixel_types[pixel_type]

        -- Skip if currently dragging this part
        if not (building.dragging and building.drag_source == "palette" and building.drag_source_index == i) then
            -- Check if we can afford this part
            local can_afford = has_sufficient_energy(pixel_type)
            local color = can_afford and pixel_def.color or 0
            local text_color = can_afford and 15 or 8

            rect(px, py, 8, 8, color)
            print(pixel_def.name, px + 12, py - 1, text_color, false, 1, true)

            -- Show energy cost
            local cost_text = pixel_def.energy_cost >= 0 and ("+" .. pixel_def.energy_cost) or tostring(pixel_def.energy_cost)
            print(cost_text, px + 12, py + 6, text_color, false, 1, true)
        end
    end

    -- Draw dragged part following mouse
    if building.dragging then
        local mx, my = mouse()
        local pixel_def = pixel_types[building.drag_pixel]

        -- Snap to grid when over ship area for better visual feedback
        if mx >= building.ship_area.x and mx < building.ship_area.x + building.ship_area.w and
           my >= building.ship_area.y and my < building.ship_area.y + building.ship_area.h and
           building.mouse_grid_x >= 0 and building.mouse_grid_y >= 0 then
            local cell_size = 8 * building.zoom_level
            local grid_start_x = building.ship_area.x + 10 - building.grid_offset_x
            local grid_start_y = building.ship_area.y + 10 - building.grid_offset_y
            local snap_x = grid_start_x + building.mouse_grid_x * cell_size
            local snap_y = grid_start_y + building.mouse_grid_y * cell_size
            rect(snap_x, snap_y, cell_size, cell_size, pixel_def.color)
        else
            rect(mx - 4, my - 4, 8, 8, pixel_def.color)
        end
    end

    -- Status bar
    local energy = get_energy_status()
    local energy_color = energy.at_limit and 2 or (energy.remaining <= 2 and 4 or 12)
    print(energy.used .. "/" .. energy.total .. "E", 10, 135, energy_color)


    if has_core_part() then
        print("A: Start Round " .. game.level, 140, 125, 11)
    end
end

-- === GAME OVER STATE ===
function update_gameover()
    if btnp(4) then -- A button - restart
        game.state = "menu"
        game.score = 0
        game.level = 1
        game.lives = 3
    end
end

function draw_gameover()
    cls(0) -- Black background
    print("GAME OVER", 80, 50, 2, false, 2) -- Red text
    print("Final Score: " .. game.score, 70, 70, 12) -- White text
    print("Press A to return to menu", 50, 90, 10) -- Light blue text
end

-- === BUILDING HELPER FUNCTIONS ===
function get_part_at_position(gx, gy)
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 and pixel.x == gx and pixel.y == gy then
            return pixel
        end
    end
    return nil
end

function get_part_index(gx, gy)
    for i, pixel in ipairs(player.pixels) do
        if pixel.health > 0 and pixel.x == gx and pixel.y == gy then
            return i
        end
    end
    return 0
end

function can_place_part(gx, gy, part_type)
    -- Can't place outside grid bounds
    if gx < 0 or gx >= GRID_WIDTH or gy < 0 or gy >= GRID_HEIGHT then
        return false
    end

    -- Can't place on occupied position
    if get_part_at_position(gx, gy) then
        return false
    end

    -- Check energy constraints
    if not has_sufficient_energy(part_type) then
        return false
    end

    -- If no parts exist, can place anywhere (for initial placement)
    local has_parts = false
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 then
            has_parts = true
            break
        end
    end

    if not has_parts then
        return true
    end

    -- Core parts can be placed anywhere (allows starting new ship sections)
    if part_type == "core" then
        return true
    end

    -- Other parts must be adjacent to existing parts
    return is_adjacent_to_ship(gx, gy)
end

function place_part(gx, gy, part_type)
    -- Remove any existing part at this position first
    for i = #player.pixels, 1, -1 do
        if player.pixels[i].x == gx and player.pixels[i].y == gy then
            table.remove(player.pixels, i)
            table.remove(player.last_shoot_times, i)
            break
        end
    end

    -- Add new part
    local new_pixel = {
        x = gx,
        y = gy,
        type = part_type,
        health = pixel_types[part_type].health
    }

    -- Add dodge cooldown for dodge parts
    if part_type == "dodge" then
        new_pixel.dodge_cooldown = 0
    end

    table.insert(player.pixels, new_pixel)
    table.insert(player.last_shoot_times, 0)
end

function remove_part_at_index(index)
    if index > 0 and index <= #player.pixels then
        table.remove(player.pixels, index)
        table.remove(player.last_shoot_times, index)
    end
end

function draw_ship_in_builder_zoomed(grid_start_x, grid_start_y, cell_size)
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 then
            local px = grid_start_x + pixel.x * cell_size
            local py = grid_start_y + pixel.y * cell_size
            local pixel_def = pixel_types[pixel.type]

            rect(px, py, cell_size, cell_size, pixel_def.color)

            -- Draw border for core part
            if pixel_def.is_core then
                rectb(px, py, cell_size, cell_size, 15)
            end

            -- Draw synergy highlight
            if is_part_synergized(pixel.x, pixel.y) then
                rectb(px, py, cell_size, cell_size, 12) -- White border for synergized parts
            end
        end
    end
end

function draw_ship_in_builder(base_x, base_y)
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 then
            local px = base_x + pixel.x * 8
            local py = base_y + pixel.y * 8
            local pixel_def = pixel_types[pixel.type]

            rect(px, py, 8, 8, pixel_def.color)

            -- Draw border for core part
            if pixel_def.is_core then
                rectb(px, py, 8, 8, 15)
            end

            -- Draw synergy highlight
            if is_part_synergized(pixel.x, pixel.y) then
                rectb(px, py, 8, 8, 12) -- White border for synergized parts
            end
        end
    end
end

-- === HELPER FUNCTIONS ===
function draw_ship(x, y, pixels, scale)
    scale = scale or 1
    for _, pixel in ipairs(pixels) do
        -- Handle both real parts (with health) and example parts (without health)
        local pixel_health = pixel.health or 1
        if pixel_health > 0 then
            local px = x + pixel.x * 6 * scale
            local py = y + pixel.y * 6 * scale
            local size = 6 * scale
            local pixel_def = pixel_types[pixel.type]
            rect(px, py, size, size, pixel_def.color)

            -- Draw health indicator for damaged parts (only for real parts)
            if pixel.health and pixel.health < pixel_types[pixel.type].health then
                rect(px, py, size, 1, 8) -- Red damage indicator
            end

            -- Draw synergy highlight in game view
            if pixel.health and is_part_synergized(pixel.x, pixel.y) then
                -- Pulsing white border effect
                local pulse = math.sin(game.timer * 0.1) * 0.5 + 0.5
                if pulse > 0.5 then
                    rectb(px, py, size, size, 12) -- White border
                end
            end

            -- Draw special effect highlights (immunity/speed burst)
            if pixel.health then -- Only for real parts in game
                -- Immunity effect - blue glow
                if player.immunity_time > 0 then
                    local immunity_pulse = math.sin(game.timer * 0.3) * 0.5 + 0.5
                    if immunity_pulse > 0.3 then
                        rectb(px-1, py-1, size+2, size+2, 9) -- Blue outline
                    end
                end

                -- Speed burst effect - yellow glow
                if player.speed_burst_time > 0 then
                    local burst_pulse = math.sin(game.timer * 0.4) * 0.5 + 0.5
                    if burst_pulse > 0.3 then
                        rectb(px-1, py-1, size+2, size+2, 4) -- Yellow outline
                    end
                end

                -- Dodge effect - purple glow during iframes
                if player.dodge_iframes > 0 then
                    local dodge_pulse = math.sin(game.timer * 0.5) * 0.5 + 0.5
                    if dodge_pulse > 0.2 then
                        rectb(px-1, py-1, size+2, size+2, 1) -- Purple outline
                    end
                end

                -- Dodge cooldown indicator for dodge parts
                if pixel.type == "dodge" and pixel.dodge_cooldown and pixel.dodge_cooldown > 0 then
                    local cooldown_ratio = pixel.dodge_cooldown / 120 -- 120 = max cooldown
                    local indicator_height = math.floor(size * cooldown_ratio)

                    -- Draw cooldown bar overlay (semi-transparent dark)
                    for cy = 0, indicator_height - 1 do
                        for cx = 0, size - 1 do
                            if (cx + cy) % 2 == 0 then -- Checkerboard pattern for transparency effect
                                pix(px + cx, py + cy, 0) -- Black pixels
                            end
                        end
                    end

                    -- Draw cooldown border
                    rectb(px, py, size, indicator_height, 14) -- Grey border for cooldown area
                end
            end
        end
    end
end

function reset_round()
    bullets = {}
    enemies = {}
    scrap_drops = {}
    game.enemies_spawned = 0
    game.round_timer = 0
    game.next_enemy_spawn = game.timer + 120

    -- Increase difficulty each round
    game.difficulty_multiplier = 1.0 + (game.level - 1) * 0.2

    -- Decrease spawn rate (increase spawn frequency)
    game.spawn_rate = math.max(30, 120 - (game.level - 1) * 10)
end

function next_round()
    game.level = game.level + 1

    -- Increase energy budget every few rounds
    if game.level % 3 == 0 then
        player.energy_bonus = player.energy_bonus + 2
    end

    game.state = "playing"
    reset_round()
end

function has_core_part()
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 and pixel_types[pixel.type].is_core then
            return true
        end
    end
    return false
end

function get_ship_bounds()
    local min_x, max_x = math.huge, -math.huge
    local min_y, max_y = math.huge, -math.huge

    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 then
            min_x = math.min(min_x, pixel.x)
            max_x = math.max(max_x, pixel.x)
            min_y = math.min(min_y, pixel.y)
            max_y = math.max(max_y, pixel.y)
        end
    end

    return {min_x=min_x, max_x=max_x, min_y=min_y, max_y=max_y}
end

function get_ship_center_fighting()
    -- Get ship center in fighting scene coordinates (independent of building grid)
    -- Now that we've fixed ship positioning, player.x and player.y represent the actual center
    return player.x, player.y
end

function get_ship_fighting_position()
    -- Calculate where to draw the ship so it appears properly positioned
    -- This accounts for the ship's bounds so player.x, player.y represents the ship center
    local ship_bounds = get_ship_bounds()
    if ship_bounds.min_x == math.huge then
        return player.x, player.y -- Default if no ship parts
    end

    -- Calculate offset to center the ship bounds around player.x, player.y
    local center_x = (ship_bounds.min_x + ship_bounds.max_x) / 2
    local center_y = (ship_bounds.min_y + ship_bounds.max_y) / 2

    -- Return position that will center the ship when drawn
    local draw_x = player.x - (center_x * 6 * GAME_SHIP_SCALE)
    local draw_y = player.y - (center_y * 6 * GAME_SHIP_SCALE)

    return draw_x, draw_y
end

function get_ship_core_position()
    -- Find the first core part to center the building grid around
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 and pixel_types[pixel.type].is_core then
            return pixel.x, pixel.y
        end
    end
    -- If no core found, return center of ship bounds
    local ship_bounds = get_ship_bounds()
    if ship_bounds.min_x == math.huge then
        return 0, 0 -- Default position
    end
    return (ship_bounds.min_x + ship_bounds.max_x) / 2, (ship_bounds.min_y + ship_bounds.max_y) / 2
end

function get_centered_grid_start(cell_size)
    -- Calculate grid start position to center the core in the ship area
    local core_x, core_y = get_ship_core_position()

    -- Center of the ship area
    local center_x = building.ship_area.x + building.ship_area.w / 2
    local center_y = building.ship_area.y + building.ship_area.h / 2

    -- Calculate where the grid should start so the core appears in the center
    local grid_start_x = center_x - (core_x * cell_size) - building.grid_offset_x
    local grid_start_y = center_y - (core_y * cell_size) - building.grid_offset_y

    return grid_start_x, grid_start_y
end

function is_position_valid(x, y)
    -- Check if position is already occupied
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 and pixel.x == x and pixel.y == y then
            return false
        end
    end
    return true
end

function is_adjacent_to_ship(x, y)
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 then
            local dx = math.abs(pixel.x - x)
            local dy = math.abs(pixel.y - y)
            if (dx == 1 and dy == 0) or (dx == 0 and dy == 1) then
                return true
            end
        end
    end
    return false
end

-- === ENERGY SYSTEM FUNCTIONS ===
function calculate_energy_used()
    local total_used = 0
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 then
            total_used = total_used + pixel_types[pixel.type].energy_cost
        end
    end
    return total_used
end

function get_total_energy_budget()
    local base_total = player.base_energy + player.energy_bonus

    -- Add generator cluster synergy bonus (only if active_synergies is initialized)
    if active_synergies and active_synergies.generator_cluster then
        for _, match in ipairs(active_synergies.generator_cluster.matches) do
            local synergy_def = active_synergies.generator_cluster.definition
            local bonus_per_generator = synergy_def.effects.energy_boost or 0
            base_total = base_total + (#match.parts * bonus_per_generator)
        end
    end

    return base_total
end

function has_sufficient_energy(additional_part_type)
    local current_used = calculate_energy_used()
    local additional_cost = pixel_types[additional_part_type].energy_cost
    local total_energy = get_total_energy_budget()
    return (current_used + additional_cost) <= total_energy
end

function get_energy_status()
    local used = calculate_energy_used()
    local total = get_total_energy_budget()
    return {
        used = used,
        total = total,
        remaining = total - used,
        at_limit = used >= total
    }
end

-- === SYNERGY SYSTEM ===
-- Define synergy patterns and their effects
local synergy_definitions = {
    triple_shooter_line = {
        name = "Triple Shot",
        description = "3 shooters in a line fire spread shots",
        pattern_type = "line",
        required_parts = {"shooter", "shooter", "shooter"},
        min_length = 3,
        effects = {
            spread_shot = true,
            spread_angle = 30 -- degrees
        }
    },
    generator_cluster = {
        name = "Power Core",
        description = "3+ generators adjacent boost energy output",
        pattern_type = "cluster",
        required_parts = {"generator"},
        min_count = 3,
        effects = {
            energy_boost = 2 -- additional energy per generator beyond base
        }
    },
    armor_wall = {
        name = "Fortress Wall",
        description = "5+ armor in a line gains damage reduction",
        pattern_type = "line",
        required_parts = {"armor", "armor", "armor", "armor", "armor"},
        min_length = 5,
        effects = {
            damage_reduction = 0.5 -- 50% damage reduction for the line
        }
    },
    laser_focus = {
        name = "Focused Beam",
        description = "2 lasers adjacent fire piercing shots",
        pattern_type = "adjacent",
        required_parts = {"laser", "laser"},
        min_count = 2,
        effects = {
            piercing_shot = true,
            damage_multiplier = 1.5
        }
    },
    shooter_cross = {
        name = "Crossfire",
        description = "5 shooters in cross formation fire in 4 directions",
        pattern_type = "cross",
        required_parts = {"shooter", "shooter", "shooter", "shooter", "shooter"},
        center_part = "shooter", -- The center part of the cross
        arm_parts = {"shooter", "shooter", "shooter", "shooter"}, -- The 4 arms
        effects = {
            cross_fire = true,
            bullet_speed = 4
        }
    },
    homing_swarm = {
        name = "Missile Swarm",
        description = "3+ homing parts in cluster fire multiple missiles",
        pattern_type = "cluster",
        required_parts = {"homing"},
        min_count = 3,
        effects = {
            multi_missile = true,
            missile_count = 2 -- Fire 2 missiles per shot
        }
    },
    explosive_line = {
        name = "Bombardment",
        description = "3+ explosives in line increase blast radius",
        pattern_type = "line",
        required_parts = {"explosive", "explosive", "explosive"},
        min_length = 3,
        effects = {
            enhanced_explosion = true,
            radius_multiplier = 1.5
        }
    },
    shield_wall = {
        name = "Aegis Protocol",
        description = "2+ shield parts adjacent provide damage immunity windows",
        pattern_type = "adjacent",
        required_parts = {"shield", "shield"},
        min_count = 2,
        effects = {
            damage_immunity = true,
            immunity_duration = 30, -- 0.5 seconds at 60fps
            immunity_cooldown = 180 -- 3 seconds cooldown
        }
    },
    engine_boost = {
        name = "Afterburner",
        description = "4+ engines in cluster provide speed burst ability",
        pattern_type = "cluster",
        required_parts = {"engine"},
        min_count = 4,
        effects = {
            speed_burst = true,
            burst_multiplier = 2.0,
            burst_duration = 120 -- 2 seconds
        }
    }
}

-- Store active synergies
local active_synergies = {}

-- Percentage-based rarity system
function get_part_appearance_chance(part_type)
    local base_chance = pixel_types[part_type].rarity
    local scrap_bonus = 0

    -- Only parts with base chance <= 30% get scrap bonuses
    if base_chance <= 30 then
        scrap_bonus = player.scrap_collected * 2 -- +2% per scrap
    end

    return math.min(95, base_chance + scrap_bonus) -- Cap at 95%
end

function count_parts_of_type(part_type)
    local count = 0
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 and pixel.type == part_type then
            count = count + 1
        end
    end
    return count
end

function select_random_part()
    local available_parts = {"armor", "engine", "shooter", "generator", "laser", "dodge", "hardpoint", "repulsor", "homing", "explosive", "shield", "core", "magnet", "relay", "conduit", "catalyst", "targeting"}
    local total_weight = 0
    local weights = {}

    -- Check if near energy limit to bias toward generators
    local energy = get_energy_status()
    local energy_ratio = energy.remaining / energy.total
    local near_limit = energy_ratio < 0.2 -- Less than 20% energy remaining

    -- Calculate weighted selection based on appearance chances
    for _, part_type in ipairs(available_parts) do
        local chance = get_part_appearance_chance(part_type)

        -- Heavily bias toward generators when near energy limit
        if near_limit and part_type == "generator" then
            chance = chance * 5 -- 5x more likely to get generators when low on energy
        end

        weights[part_type] = chance
        total_weight = total_weight + chance
    end

    -- Random selection based on weights
    local rand = math.random() * total_weight
    local current_weight = 0

    for _, part_type in ipairs(available_parts) do
        current_weight = current_weight + weights[part_type]
        if rand <= current_weight then
            return part_type
        end
    end

    -- Fallback (should never reach here)
    return "armor"
end

-- Initialize synergies on startup
function init_synergies()
    active_synergies = {}
end

function detect_synergies()
    active_synergies = {}

    -- Check for catalyst parts to reduce requirements
    local catalyst_count = count_parts_of_type("catalyst")
    local requirement_reduction = catalyst_count > 0 and 1 or 0 -- Reduce min requirements by 1 if catalyst present

    for synergy_id, synergy_def in pairs(synergy_definitions) do
        local matches = {}

        -- Create modified synergy definition with reduced requirements
        local modified_def = {}
        for k, v in pairs(synergy_def) do
            modified_def[k] = v
        end

        -- Apply catalyst reduction
        if modified_def.min_length then
            modified_def.min_length = math.max(2, modified_def.min_length - requirement_reduction)
        end
        if modified_def.min_count then
            modified_def.min_count = math.max(2, modified_def.min_count - requirement_reduction)
        end

        if modified_def.pattern_type == "line" then
            matches = detect_line_patterns(modified_def)
        elseif modified_def.pattern_type == "cluster" then
            matches = detect_cluster_patterns(modified_def)
        elseif modified_def.pattern_type == "adjacent" then
            matches = detect_adjacent_patterns(modified_def)
        elseif modified_def.pattern_type == "cross" then
            matches = detect_cross_patterns(modified_def)
        end

        if #matches > 0 then
            active_synergies[synergy_id] = {
                definition = synergy_def, -- Store original for effects
                matches = matches,
                catalyst_boosted = catalyst_count > 0
            }
        end
    end
end

function detect_line_patterns(synergy_def)
    local matches = {}
    local required_type = synergy_def.required_parts[1]
    local min_length = synergy_def.min_length

    -- Check horizontal lines
    for y = 0, GRID_HEIGHT - 1 do
        local line_parts = {}
        for x = 0, GRID_WIDTH - 1 do
            local part = get_part_at_position(x, y)
            if part and part.health > 0 and part.type == required_type then
                table.insert(line_parts, {x = x, y = y, part = part})
            else
                if #line_parts >= min_length then
                    table.insert(matches, {direction = "horizontal", parts = line_parts})
                end
                line_parts = {}
            end
        end
        if #line_parts >= min_length then
            table.insert(matches, {direction = "horizontal", parts = line_parts})
        end
    end

    -- Check vertical lines
    for x = 0, GRID_WIDTH - 1 do
        local line_parts = {}
        for y = 0, GRID_HEIGHT - 1 do
            local part = get_part_at_position(x, y)
            if part and part.health > 0 and part.type == required_type then
                table.insert(line_parts, {x = x, y = y, part = part})
            else
                if #line_parts >= min_length then
                    table.insert(matches, {direction = "vertical", parts = line_parts})
                end
                line_parts = {}
            end
        end
        if #line_parts >= min_length then
            table.insert(matches, {direction = "vertical", parts = line_parts})
        end
    end

    return matches
end

function detect_cluster_patterns(synergy_def)
    local matches = {}
    local required_type = synergy_def.required_parts[1]
    local min_count = synergy_def.min_count
    local visited = {}

    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 and pixel.type == required_type then
            local key = pixel.x .. "," .. pixel.y
            if not visited[key] then
                local cluster = find_connected_parts(pixel.x, pixel.y, required_type, visited)
                if #cluster >= min_count then
                    table.insert(matches, {parts = cluster})
                end
            end
        end
    end

    return matches
end

function detect_adjacent_patterns(synergy_def)
    local matches = {}
    local required_type = synergy_def.required_parts[1]
    local min_count = synergy_def.min_count

    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 and pixel.type == required_type then
            local adjacent_parts = find_adjacent_parts(pixel.x, pixel.y, required_type)
            if #adjacent_parts >= min_count then
                table.insert(matches, {parts = adjacent_parts})
            end
        end
    end

    return matches
end

function detect_cross_patterns(synergy_def)
    local matches = {}
    local center_type = synergy_def.center_part
    local arm_type = synergy_def.arm_parts[1] -- Assume all arms are same type for now

    -- Find all potential center parts
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 and pixel.type == center_type then
            local cross_parts = check_cross_at_position(pixel.x, pixel.y, center_type, arm_type)
            if cross_parts then
                table.insert(matches, {
                    center = {x = pixel.x, y = pixel.y, part = pixel},
                    arms = cross_parts.arms,
                    parts = cross_parts.all_parts
                })
            end
        end
    end

    return matches
end

function check_cross_at_position(center_x, center_y, center_type, arm_type)
    -- Define the 4 directions for cross arms
    local directions = {
        {dx = 0, dy = -1, name = "up"},    -- Up
        {dx = 1, dy = 0, name = "right"},  -- Right
        {dx = 0, dy = 1, name = "down"},   -- Down
        {dx = -1, dy = 0, name = "left"}   -- Left
    }

    local arms = {}
    local all_parts = {{x = center_x, y = center_y, part = get_part_at_position(center_x, center_y)}}

    -- Check each direction for an arm part
    for _, dir in ipairs(directions) do
        local arm_x = center_x + dir.dx
        local arm_y = center_y + dir.dy
        local arm_part = get_part_at_position(arm_x, arm_y)

        if arm_part and arm_part.health > 0 and arm_part.type == arm_type then
            table.insert(arms, {
                x = arm_x,
                y = arm_y,
                part = arm_part,
                direction = dir.name
            })
            table.insert(all_parts, {x = arm_x, y = arm_y, part = arm_part})
        else
            -- Cross is incomplete if any arm is missing
            return nil
        end
    end

    -- Valid cross found (center + 4 arms = 5 parts total)
    return {
        arms = arms,
        all_parts = all_parts
    }
end

function find_connected_parts(start_x, start_y, part_type, visited)
    local cluster = {}
    local queue = {{x = start_x, y = start_y}}
    local conduit_count = count_parts_of_type("conduit")
    local bridge_range = conduit_count > 0 and 2 or 1 -- Conduits allow connections across 1 gap

    while #queue > 0 do
        local current = table.remove(queue, 1)
        local key = current.x .. "," .. current.y

        if not visited[key] then
            visited[key] = true
            local part = get_part_at_position(current.x, current.y)

            if part and part.health > 0 and part.type == part_type then
                table.insert(cluster, {x = current.x, y = current.y, part = part})

                -- Add positions within bridge range
                for dx = -bridge_range, bridge_range do
                    for dy = -bridge_range, bridge_range do
                        if (dx == 0 and math.abs(dy) <= bridge_range) or (dy == 0 and math.abs(dx) <= bridge_range) then
                            local adj_x = current.x + dx
                            local adj_y = current.y + dy
                            if adj_x >= 0 and adj_x < GRID_WIDTH and adj_y >= 0 and adj_y < GRID_HEIGHT then
                                table.insert(queue, {x = adj_x, y = adj_y})
                            end
                        end
                    end
                end
            end
        end
    end

    return cluster
end

function find_adjacent_parts(x, y, part_type)
    local adjacent_parts = {{x = x, y = y, part = get_part_at_position(x, y)}}
    local conduit_count = count_parts_of_type("conduit")
    local bridge_range = conduit_count > 0 and 2 or 1 -- Conduits allow connections across 1 gap

    -- Check all positions within bridge range
    for dx = -bridge_range, bridge_range do
        for dy = -bridge_range, bridge_range do
            if (dx == 0 and math.abs(dy) <= bridge_range) or (dy == 0 and math.abs(dx) <= bridge_range) then
                if not (dx == 0 and dy == 0) then -- Skip the center position
                    local adj_x, adj_y = x + dx, y + dy
                    local part = get_part_at_position(adj_x, adj_y)
                    if part and part.health > 0 and part.type == part_type then
                        table.insert(adjacent_parts, {x = adj_x, y = adj_y, part = part})
                    end
                end
            end
        end
    end

    return adjacent_parts
end

function find_closest_enemy(x, y)
    local closest_enemy = nil
    local closest_distance = math.huge

    for _, enemy in ipairs(enemies) do
        if enemy.health > 0 then
            local dx = enemy.x + enemy.size/2 - x
            local dy = enemy.y + enemy.size/2 - y
            local distance = math.sqrt(dx*dx + dy*dy)

            if distance < closest_distance then
                closest_distance = distance
                closest_enemy = enemy
            end
        end
    end

    return closest_enemy
end

function create_explosion(x, y, radius)
    -- Add visual explosion effect
    table.insert(explosions, {
        x = x,
        y = y,
        radius = radius,
        max_radius = radius,
        lifetime = 30, -- 0.5 seconds at 60fps
        max_lifetime = 30
    })

    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        local dx = enemy.x + enemy.size/2 - x
        local dy = enemy.y + enemy.size/2 - y
        local distance = math.sqrt(dx*dx + dy*dy)

        if distance <= radius then
            enemy.health = enemy.health - 2 -- Explosion damage

            if enemy.health <= 0 then
                local enemy_def = enemy_types[enemy.type]
                game.score = game.score + enemy_def.score

                -- 10% chance to drop scrap
                if math.random() <= 0.1 then
                    table.insert(scrap_drops, {
                        x = enemy.x + enemy.size / 2,
                        y = enemy.y + enemy.size / 2,
                        lifetime = 600,
                        collected = false
                    })
                end

                table.remove(enemies, i)
            end
        end
    end
end

function get_part_synergy_effects(x, y, part_type)
    local effects = {}

    if active_synergies then
        for synergy_id, synergy_data in pairs(active_synergies) do
            for _, match in ipairs(synergy_data.matches) do
                for _, part_data in ipairs(match.parts) do
                    if part_data.x == x and part_data.y == y then
                        -- This part is affected by this synergy
                        for effect_name, effect_value in pairs(synergy_data.definition.effects) do
                            effects[effect_name] = effect_value
                        end
                    end
                end
            end
        end
    end

    return effects
end

function is_part_synergized(x, y)
    if active_synergies then
        for synergy_id, synergy_data in pairs(active_synergies) do
            for _, match in ipairs(synergy_data.matches) do
                for _, part_data in ipairs(match.parts) do
                    if part_data.x == x and part_data.y == y then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- === SPECIAL EFFECTS SYSTEM ===
function calculate_special_effects()
    local effects = {
        double_pick = false,
        repulsor_parts = {},
        amplified_pick = false
    }

    for i, pixel in ipairs(player.pixels) do
        if pixel.health > 0 then
            local pixel_def = pixel_types[pixel.type]
            if pixel_def.special_effect == "double_pick" then
                effects.double_pick = true

                -- Check for adjacent relay parts for amplification
                local has_relay_boost = false
                local directions = {
                    {dx = -1, dy = 0}, {dx = 1, dy = 0},
                    {dx = 0, dy = -1}, {dx = 0, dy = 1}
                }

                for _, dir in ipairs(directions) do
                    local adj_x = pixel.x + dir.dx
                    local adj_y = pixel.y + dir.dy
                    local adj_part = get_part_at_position(adj_x, adj_y)
                    if adj_part and adj_part.health > 0 and pixel_types[adj_part.type].special_effect == "relay" then
                        has_relay_boost = true
                        break
                    end
                end

                if has_relay_boost then
                    effects.amplified_pick = true -- Relay amplifies hardpoint from +1 to +2 picks
                end
            elseif pixel_def.special_effect == "repulse" then
                table.insert(effects.repulsor_parts, {index = i, pixel = pixel})
            end
        end
    end

    return effects
end

function apply_special_effects()
    local effects = calculate_special_effects()

    -- Detect synergies whenever ship configuration changes
    detect_synergies()

    -- Reset to base values
    game.parts_per_upgrade = 1

    -- Apply effects
    if effects.amplified_pick then
        game.parts_per_upgrade = math.min(game.parts_per_upgrade + 2, game.max_parts_per_upgrade) -- Relay amplifies to +2
    elseif effects.double_pick then
        game.parts_per_upgrade = math.min(game.parts_per_upgrade + 1, game.max_parts_per_upgrade)
    end
end

function repulsor_pulse(pulse_x, pulse_y)
    local pulse_radius = 80 -- Increased range of repulsor effect
    local push_force = 60   -- Increased push force

    -- Count repulsors for scaling effect
    local repulsor_count = count_parts_of_type("repulsor")
    local scaled_radius = pulse_radius + (repulsor_count - 1) * 15 -- +15 radius per additional repulsor
    local scaled_force = push_force + (repulsor_count - 1) * 10   -- +10 force per additional repulsor

    for i, enemy in ipairs(enemies) do
        local dx = enemy.x - pulse_x
        local dy = enemy.y - pulse_y
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance < scaled_radius and distance > 0 then
            -- Normalize direction and apply push force
            local push_x = (dx / distance) * scaled_force
            local push_y = (dy / distance) * scaled_force

            enemy.x = enemy.x + push_x
            enemy.y = enemy.y + push_y

            -- Damage enemies that are very close to the pulse
            if distance < scaled_radius * 0.4 then
                enemy.health = enemy.health - 1
                if enemy.health <= 0 then
                    game.score = game.score + enemy_types[enemy.type].score
                    table.remove(enemies, i)
                end
            end

            -- Keep enemies in bounds after push
            enemy.x = math.max(-enemy.size, math.min(250, enemy.x))
            enemy.y = math.max(0, math.min(136 - enemy.size, enemy.y))
        end
    end
end

-- Initialize on startup
init_ship()