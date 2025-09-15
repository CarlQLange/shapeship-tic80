-- title:   Shapeship
-- author:  Carl Lange
-- desc:    Build your ship from pixels and blast through space! R-Type meets ship building.
-- site:
-- license: MIT License
-- version: 0.1
-- script:  lua

-- TIC-80 Color Palette Reference:
-- 0=Black(1A1C2C) 1=Purple(5D275D) 2=Red(B13E53) 3=Orange(EF7D57)
-- 4=Yellow(FFCD75) 5=Light Green(A7F070) 6=Green(38B764) 7=Dark Green(257179)
-- 8=Dark Blue(29366F) 9=Blue(3B5DC9) 10=Light Blue(41A6F6) 11=Cyan(73EFF7)
-- 12=White(F4F4F4) 13=Light Grey(94B0C2) 14=Grey(566C86) 15=Dark Grey(333C57)

-- Pixel type definitions - easily extensible
local pixel_types = {
    armor = {
        color = 14,      -- Grey
        health = 2,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        name = "Armor"
    },
    engine = {
        color = 9,       -- Blue
        health = 1,
        can_shoot = false,
        shoot_interval = 0,
        is_core = true,   -- Core pixel - game over if destroyed
        name = "Engine"
    },
    shooter = {
        color = 2,       -- Red
        health = 1,
        can_shoot = true,
        shoot_interval = 36, -- 0.6 seconds at 60fps
        is_core = false,
        name = "Shooter"
    },
    laser = {
        color = 10,      -- Light Blue
        health = 1,
        can_shoot = true,
        shoot_interval = 20,
        is_core = false,
        name = "Laser"
    },
    reflector = {
        color = 1,       -- Purple
        health = 1,
        can_shoot = false,
        shoot_interval = 0,
        is_core = false,
        name = "Reflector"
    }
}

-- Game state
local game = {
    state = "menu",     -- menu, building, playing, upgrading, gameover
    level = 1,
    score = 0,
    lives = 3,
    timer = 0,
    enemies_spawned = 0,
    enemies_killed = 0,
    next_enemy_spawn = 120 -- 2 seconds at 60fps
}

-- Player ship
local player = {
    x = 50,
    y = 60,
    pixels = {},
    last_shoot_times = {},
    speed = 1.5
}

-- Game objects
local bullets = {}
local enemies = {}
local upgrade_options = {}

-- Building interface
local building = {
    dragging = false,
    drag_pixel = nil,
    drag_source = "", -- "palette" or "ship"
    drag_source_index = 0,
    mouse_grid_x = 0,
    mouse_grid_y = 0,
    ship_area = {x = 20, y = 20, w = 120, h = 96},
    palette_area = {x = 160, y = 20, w = 60, h = 96},
    available_pixels = {"engine", "armor", "shooter", "laser", "reflector"},
    upgrade_mode = false,
    pixels_added = 0,
    is_initial = false
}

-- Initialize starting ship configuration
function init_ship()
    player.pixels = {
        -- Starting 3x3 configuration centered on grid:
        -- a a
        -- e a s
        -- a a
        {x=5, y=4, type="armor", health=pixel_types.armor.health},
        {x=6, y=4, type="armor", health=pixel_types.armor.health},
        {x=5, y=5, type="engine", health=pixel_types.engine.health},
        {x=6, y=5, type="armor", health=pixel_types.armor.health},
        {x=7, y=5, type="shooter", health=pixel_types.shooter.health},
        {x=5, y=6, type="armor", health=pixel_types.armor.health},
        {x=6, y=6, type="armor", health=pixel_types.armor.health}
    }

    -- Initialize shoot timers for all pixels
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
    -- Player movement (allow ship to reach screen edges)
    -- Top pixels are at grid y=4, so player.y + 4*6 = player.y + 24
    -- To reach screen top (y=0), player.y needs to be -24
    if btn(0) and player.y > -24 then player.y = player.y - player.speed end
    if btn(1) and player.y < 120 then player.y = player.y + player.speed end
    if btn(2) and player.x > -30 then player.x = player.x - player.speed end -- Allow some left overhang
    if btn(3) and player.x < 180 then player.x = player.x + player.speed end

    -- Shooting
    update_shooting()

    -- Enemy spawning
    update_enemy_spawning()

    -- Update bullets
    update_bullets()

    -- Update enemies
    update_enemies()

    -- Collision detection
    update_collisions()

    -- Check win condition
    if game.enemies_killed >= 5 then
        start_upgrade_phase()
    end

    -- Check lose condition
    if not has_core_pixel() then
        game.state = "gameover"
    end
end

function update_shooting()
    for i, pixel in ipairs(player.pixels) do
        local pixel_def = pixel_types[pixel.type]
        if pixel_def.can_shoot and pixel.health > 0 then
            if game.timer - player.last_shoot_times[i] >= pixel_def.shoot_interval then
                -- Create bullet at pixel position
                local bullet_x = player.x + pixel.x * 6 + 6
                local bullet_y = player.y + pixel.y * 6 + 3
                table.insert(bullets, {
                    x = bullet_x,
                    y = bullet_y,
                    speed = 3,
                    type = pixel.type
                })
                player.last_shoot_times[i] = game.timer
            end
        end
    end
end

function update_enemy_spawning()
    if game.enemies_spawned < 5 and game.timer >= game.next_enemy_spawn then
        -- Spawn enemy from right side
        table.insert(enemies, {
            x = 250,
            y = math.random(10, 120),
            health = 1,
            speed = 0.5
        })
        game.enemies_spawned = game.enemies_spawned + 1
        game.next_enemy_spawn = game.timer + 120 -- Next enemy in 2 seconds
    end
end

function update_bullets()
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet.x = bullet.x + bullet.speed

        -- Remove bullets that go off screen
        if bullet.x > 250 then
            table.remove(bullets, i)
        end
    end
end

function update_enemies()
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        enemy.x = enemy.x - enemy.speed

        -- Remove enemies that go off screen
        if enemy.x < -10 then
            table.remove(enemies, i)
        end
    end
end

function update_collisions()
    -- Bullets vs Enemies
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        for j = #enemies, 1, -1 do
            local enemy = enemies[j]
            if bullet.x >= enemy.x and bullet.x <= enemy.x + 8 and
               bullet.y >= enemy.y and bullet.y <= enemy.y + 8 then
                -- Hit!
                table.remove(bullets, i)
                table.remove(enemies, j)
                game.enemies_killed = game.enemies_killed + 1
                game.score = game.score + 100
                break
            end
        end
    end

    -- Enemies vs Ship
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        for j = #player.pixels, 1, -1 do
            local pixel = player.pixels[j]
            if pixel.health > 0 then
                local px = player.x + pixel.x * 6
                local py = player.y + pixel.y * 6
                if enemy.x < px + 6 and enemy.x + 8 > px and
                   enemy.y < py + 6 and enemy.y + 8 > py then
                    -- Ship hit!
                    pixel.health = pixel.health - 1
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

    -- Draw player ship
    draw_ship(player.x, player.y, player.pixels)

    -- Draw bullets
    for _, bullet in ipairs(bullets) do
        rect(bullet.x, bullet.y, 2, 1, 4) -- Yellow bullets
    end

    -- Draw enemies
    for _, enemy in ipairs(enemies) do
        rect(enemy.x, enemy.y, 8, 8, 2) -- Red enemies
    end

    -- UI
    print("Score: " .. game.score, 5, 5, 12) -- White text
    print("Round: " .. game.level, 5, 15, 12) -- White text
    print("Enemies: " .. game.enemies_killed .. "/5", 5, 25, 12) -- White text
end

-- === UPGRADING STATE ===
function start_upgrade_phase()
    game.state = "upgrading"

    -- Generate 3 random pixel options
    upgrade_options = {}
    local available_types = {"armor", "shooter", "laser", "reflector"}

    for i = 1, 3 do
        local rand_type = available_types[math.random(#available_types)]
        table.insert(upgrade_options, {
            type = rand_type,
            def = pixel_types[rand_type]
        })
    end

    -- Set up building interface for upgrade mode
    building.dragging = false
    building.drag_pixel = nil
    building.upgrade_mode = true
    building.pixels_added = 0
    building.available_pixels = {upgrade_options[1].type, upgrade_options[2].type, upgrade_options[3].type}
end

function start_initial_upgrade()
    game.state = "upgrading"

    -- For initial upgrade, offer basic pixel types
    upgrade_options = {}
    local initial_types = {"armor", "shooter", "laser"}

    for i = 1, 3 do
        table.insert(upgrade_options, {
            type = initial_types[i],
            def = pixel_types[initial_types[i]]
        })
    end

    -- Set up building interface for initial upgrade
    building.dragging = false
    building.drag_pixel = nil
    building.upgrade_mode = true
    building.pixels_added = 0
    building.available_pixels = {upgrade_options[1].type, upgrade_options[2].type, upgrade_options[3].type}
    building.is_initial = true -- Flag to track initial upgrade
end

function update_upgrading()
    local mx, my, left, middle, right = mouse()

    -- Convert mouse to grid coordinates in ship area
    if mx >= building.ship_area.x and mx < building.ship_area.x + building.ship_area.w and
       my >= building.ship_area.y and my < building.ship_area.y + building.ship_area.h then
        building.mouse_grid_x = math.floor((mx - building.ship_area.x - 4) / 8)
        building.mouse_grid_y = math.floor((my - building.ship_area.y - 4) / 8)
    else
        building.mouse_grid_x = -1
        building.mouse_grid_y = -1
    end

    -- Only allow interaction if we haven't added a pixel yet
    if building.pixels_added == 0 then
        -- Handle mouse clicks and dragging
        if left and not building.dragging then
            -- Start dragging from palette
            if mx >= building.palette_area.x and mx < building.palette_area.x + building.palette_area.w and
               my >= building.palette_area.y and my < building.palette_area.y + building.palette_area.h then
                local palette_index = math.floor((my - building.palette_area.y - 10) / 16) + 1
                if palette_index >= 1 and palette_index <= #building.available_pixels then
                    building.dragging = true
                    building.drag_pixel = building.available_pixels[palette_index]
                    building.drag_source = "palette"
                    building.drag_source_index = palette_index
                end
            end
        end

        -- Handle drop
        if not left and building.dragging then
            if building.mouse_grid_x >= 0 and building.mouse_grid_y >= 0 then
                -- Valid drop zone
                if can_place_pixel(building.mouse_grid_x, building.mouse_grid_y, building.drag_pixel) then
                    place_pixel(building.mouse_grid_x, building.mouse_grid_y, building.drag_pixel)
                    building.pixels_added = 1
                end
            end

            building.dragging = false
            building.drag_pixel = nil
            building.drag_source = ""
            building.drag_source_index = 0
        end
    end

    -- Keyboard controls
    if btnp(4) or (building.pixels_added > 0 and left) then -- A button or click after adding pixel
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
        print("CUSTOMIZE YOUR STARTING SHIP", 55, 5, 12, false, 1, true)
    else
        print("CHOOSE ONE PIXEL TO ADD", 65, 5, 12, false, 1, true)
    end

    -- Ship building area
    rect(building.ship_area.x, building.ship_area.y, building.ship_area.w, building.ship_area.h, 5)
    rectb(building.ship_area.x, building.ship_area.y, building.ship_area.w, building.ship_area.h, 12)
    print("SHIP", building.ship_area.x + 5, building.ship_area.y - 8, 12)

    -- Draw grid in ship area
    for gx = 0, 13 do
        for gy = 0, 10 do
            local px = building.ship_area.x + 4 + gx * 8
            local py = building.ship_area.y + 4 + gy * 8

            -- Highlight valid placement positions (only if we haven't added a pixel yet)
            if building.pixels_added == 0 and building.dragging and can_place_pixel(gx, gy, building.drag_pixel) then
                rect(px, py, 8, 8, 3) -- Dark green for valid
            elseif gx == building.mouse_grid_x and gy == building.mouse_grid_y then
                rect(px, py, 8, 8, 2) -- Purple for hover
            else
                rectb(px, py, 8, 8, 0) -- Dark grid
            end
        end
    end

    -- Draw ship pixels
    draw_ship_in_builder(building.ship_area.x + 4, building.ship_area.y + 4)

    -- Pixel palette area
    rect(building.palette_area.x, building.palette_area.y, building.palette_area.w, building.palette_area.h, 5)
    rectb(building.palette_area.x, building.palette_area.y, building.palette_area.w, building.palette_area.h, 12)
    print("OPTIONS", building.palette_area.x + 5, building.palette_area.y - 8, 12)

    -- Draw available upgrade options
    for i, pixel_type in ipairs(building.available_pixels) do
        local px = building.palette_area.x + 10
        local py = building.palette_area.y + 10 + (i-1) * 16
        local pixel_def = pixel_types[pixel_type]

        -- Skip if currently dragging this pixel or if we already added a pixel
        if not (building.dragging and building.drag_source == "palette" and building.drag_source_index == i) and
           building.pixels_added == 0 then
            rect(px, py, 8, 8, pixel_def.color)
            print(pixel_def.name, px + 12, py + 2, 15, false, 1, true)
        elseif building.pixels_added > 0 then
            -- Gray out options after adding
            rect(px, py, 8, 8, 0)
            print(pixel_def.name, px + 12, py + 2, 5, false, 1, true)
        end
    end

    -- Draw dragged pixel following mouse
    if building.dragging and building.pixels_added == 0 then
        local mx, my = mouse()
        local pixel_def = pixel_types[building.drag_pixel]
        rect(mx - 4, my - 4, 8, 8, pixel_def.color)
    end

    -- Instructions
    if building.pixels_added == 0 then
        print("Drag one pixel from right to add to ship", 10, 120, 12)
    else
        print("Pixel added! Press A or click to continue", 40, 120, 12)
    end
end

-- === BUILDING STATE ===
function update_building()
    local mx, my, left, middle, right = mouse()

    -- Convert mouse to grid coordinates in ship area
    if mx >= building.ship_area.x and mx < building.ship_area.x + building.ship_area.w and
       my >= building.ship_area.y and my < building.ship_area.y + building.ship_area.h then
        building.mouse_grid_x = math.floor((mx - building.ship_area.x - 10) / 8)
        building.mouse_grid_y = math.floor((my - building.ship_area.y - 10) / 8)
    else
        building.mouse_grid_x = -1
        building.mouse_grid_y = -1
    end

    -- Handle mouse clicks and dragging
    if left and not building.dragging then
        -- Start dragging from palette
        if mx >= building.palette_area.x and mx < building.palette_area.x + building.palette_area.w and
           my >= building.palette_area.y and my < building.palette_area.y + building.palette_area.h then
            local palette_index = math.floor((my - building.palette_area.y - 10) / 16) + 1
            if palette_index >= 1 and palette_index <= #building.available_pixels then
                building.dragging = true
                building.drag_pixel = building.available_pixels[palette_index]
                building.drag_source = "palette"
                building.drag_source_index = palette_index
            end
        -- Start dragging from ship
        elseif building.mouse_grid_x >= 0 and building.mouse_grid_y >= 0 then
            local pixel_at_pos = get_pixel_at_position(building.mouse_grid_x, building.mouse_grid_y)
            if pixel_at_pos then
                building.dragging = true
                building.drag_pixel = pixel_at_pos.type
                building.drag_source = "ship"
                building.drag_source_index = get_pixel_index(building.mouse_grid_x, building.mouse_grid_y)
            end
        end
    end

    -- Handle drop
    if not left and building.dragging then
        if building.mouse_grid_x >= 0 and building.mouse_grid_y >= 0 then
            -- Valid drop zone
            if can_place_pixel(building.mouse_grid_x, building.mouse_grid_y, building.drag_pixel) then
                place_pixel(building.mouse_grid_x, building.mouse_grid_y, building.drag_pixel)

                -- If dragging from ship, remove the original
                if building.drag_source == "ship" then
                    remove_pixel_at_index(building.drag_source_index)
                end
            end
        elseif building.drag_source == "ship" then
            -- Dragged ship pixel outside - remove it (unless it's the engine)
            local pixel = player.pixels[building.drag_source_index]
            if pixel and not pixel_types[pixel.type].is_core then
                remove_pixel_at_index(building.drag_source_index)
            end
        end

        building.dragging = false
        building.drag_pixel = nil
        building.drag_source = ""
        building.drag_source_index = 0
    end

    -- Keyboard controls
    if btnp(4) then -- A button - start game
        if has_core_pixel() then
            game.state = "playing"
            reset_round()
        end
    end
end

function draw_building()
    cls(7) -- Dark green background

    -- Title
    print("SHIP BUILDER", 80, 5, 15, false, 1, true)

    -- Ship building area
    rect(building.ship_area.x, building.ship_area.y, building.ship_area.w, building.ship_area.h, 5)
    rectb(building.ship_area.x, building.ship_area.y, building.ship_area.w, building.ship_area.h, 12)
    print("SHIP", building.ship_area.x + 5, building.ship_area.y - 8, 12)

    -- Draw grid in ship area
    for gx = 0, 13 do
        for gy = 0, 10 do
            local px = building.ship_area.x + 10 + gx * 8
            local py = building.ship_area.y + 10 + gy * 8

            -- Highlight valid placement positions
            if building.dragging and can_place_pixel(gx, gy, building.drag_pixel) then
                rect(px, py, 8, 8, 3) -- Dark green for valid
            elseif gx == building.mouse_grid_x and gy == building.mouse_grid_y then
                rect(px, py, 8, 8, 2) -- Purple for hover
            else
                rectb(px, py, 8, 8, 0) -- Dark grid
            end
        end
    end

    -- Draw ship pixels
    draw_ship_in_builder(building.ship_area.x + 10, building.ship_area.y + 10)

    -- Pixel palette area
    rect(building.palette_area.x, building.palette_area.y, building.palette_area.w, building.palette_area.h, 5)
    rectb(building.palette_area.x, building.palette_area.y, building.palette_area.w, building.palette_area.h, 12)
    print("PIXELS", building.palette_area.x + 5, building.palette_area.y - 8, 12)

    -- Draw available pixels
    for i, pixel_type in ipairs(building.available_pixels) do
        local px = building.palette_area.x + 10
        local py = building.palette_area.y + 10 + (i-1) * 16
        local pixel_def = pixel_types[pixel_type]

        -- Skip if currently dragging this pixel
        if not (building.dragging and building.drag_source == "palette" and building.drag_source_index == i) then
            rect(px, py, 8, 8, pixel_def.color)
            print(pixel_def.name, px + 12, py + 2, 15, false, 1, true)
        end
    end

    -- Draw dragged pixel following mouse
    if building.dragging then
        local mx, my = mouse()
        local pixel_def = pixel_types[building.drag_pixel]
        rect(mx - 4, my - 4, 8, 8, pixel_def.color)
    end

    -- Instructions
    print("Drag pixels from right to left to build ship", 10, 125, 7)
    if has_core_pixel() then
        print("Press A to start round " .. game.level, 140, 125, 11)
    else
        print("Need engine pixel to start!", 140, 125, 8)
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
function get_pixel_at_position(gx, gy)
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 and pixel.x == gx and pixel.y == gy then
            return pixel
        end
    end
    return nil
end

function get_pixel_index(gx, gy)
    for i, pixel in ipairs(player.pixels) do
        if pixel.health > 0 and pixel.x == gx and pixel.y == gy then
            return i
        end
    end
    return 0
end

function can_place_pixel(gx, gy, pixel_type)
    -- Can't place outside grid bounds
    if gx < 0 or gx > 13 or gy < 0 or gy > 10 then
        return false
    end

    -- Can't place on occupied position
    if get_pixel_at_position(gx, gy) then
        return false
    end

    -- If no pixels exist, can place anywhere (for initial placement)
    local has_pixels = false
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 then
            has_pixels = true
            break
        end
    end

    if not has_pixels then
        return true
    end

    -- Must be adjacent to existing pixel
    return is_adjacent_to_ship(gx, gy)
end

function place_pixel(gx, gy, pixel_type)
    -- Remove any existing pixel at this position first
    for i = #player.pixels, 1, -1 do
        if player.pixels[i].x == gx and player.pixels[i].y == gy then
            table.remove(player.pixels, i)
            table.remove(player.last_shoot_times, i)
            break
        end
    end

    -- Add new pixel
    table.insert(player.pixels, {
        x = gx,
        y = gy,
        type = pixel_type,
        health = pixel_types[pixel_type].health
    })
    table.insert(player.last_shoot_times, 0)
end

function remove_pixel_at_index(index)
    if index > 0 and index <= #player.pixels then
        table.remove(player.pixels, index)
        table.remove(player.last_shoot_times, index)
    end
end

function draw_ship_in_builder(base_x, base_y)
    for _, pixel in ipairs(player.pixels) do
        if pixel.health > 0 then
            local px = base_x + pixel.x * 8
            local py = base_y + pixel.y * 8
            local pixel_def = pixel_types[pixel.type]

            rect(px, py, 8, 8, pixel_def.color)

            -- Draw border for core pixel
            if pixel_def.is_core then
                rectb(px, py, 8, 8, 15)
            end
        end
    end
end

-- === HELPER FUNCTIONS ===
function draw_ship(x, y, pixels, scale)
    scale = scale or 1
    for _, pixel in ipairs(pixels) do
        -- Handle both real pixels (with health) and example pixels (without health)
        local pixel_health = pixel.health or 1
        if pixel_health > 0 then
            local px = x + pixel.x * 6 * scale
            local py = y + pixel.y * 6 * scale
            local size = 6 * scale
            local pixel_def = pixel_types[pixel.type]
            rect(px, py, size, size, pixel_def.color)

            -- Draw health indicator for damaged pixels (only for real pixels)
            if pixel.health and pixel.health < pixel_types[pixel.type].health then
                rect(px, py, size, 1, 8) -- Red damage indicator
            end
        end
    end
end

function reset_round()
    bullets = {}
    enemies = {}
    game.enemies_spawned = 0
    game.enemies_killed = 0
    game.next_enemy_spawn = game.timer + 120
end

function next_round()
    game.level = game.level + 1
    game.state = "playing"
    reset_round()
end

function has_core_pixel()
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

-- Initialize on startup
init_ship()