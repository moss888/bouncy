function move_x(player)

    if (player.stored_speed_x ~= 0) then
        if (sign(player.speed_x) == sign(player.stored_speed_x) or player.speed_x == 0) then
            player.dump_stored_speed_x = true
        elseif (sign(player.speed_x) ~= sign(player.stored_speed_x) and abs(player.speed_x) > 1) then
            player.stored_speed_x = 0
        end
    end

    if (player.dump_stored_speed_x) then
        player.speed_x = player.speed_x + player.stored_speed_x
        player.stored_speed_x = 0
        player.dump_stored_speed_x = false
        local abs_speed = abs(player.speed_x)
        if (abs_speed > gravity) then
            if (abs_speed < (stored_energy_limit / 3)) then
                sfx(0, -1, 8, 1)
            elseif (abs_speed >= (stored_energy_limit / 3) and abs_speed < ((stored_energy_limit / 3) * 2)) then
                sfx(0, -1, 8, 2)
            elseif (abs_speed >= ((stored_energy_limit / 3) * 2)) then
                sfx(0, -1, 8, 4)
            end
        end
    end

    if (player.speed_x > 0 or player.speed_x < 0) then
        player.dx = player.x + player.speed_x
    end

    set_ball_sprite_index()

    local collision_result = check_map_collision_x(player,
        (bouncy_terrain_flag | sloped_terrain_l_flag | sloped_terrain_r_flag | terrain_flag | hazard_flag |
            top_only_collision_flag), resolution)

    if (collision_result.collision == true) then

        if (collision_result.flag & hazard_flag > 0) then
            check_standard_hazard_hit(collision_result, hazard_flag)
        end

        if (collision_result.flag & sloped_terrain_l_flag > 0) then
            handle_slope_collision_left_x(collision_result)
        elseif (collision_result.flag & sloped_terrain_r_flag > 0) then
            handle_slope_collision_right_x(collision_result)
        elseif ((collision_result.flag & top_only_collision_flag > 0)) then
            calculate_top_only_collision_terrain(collision_result)
            player.colliding_x = false
            player.x = player.dx
        elseif ((collision_result.flag & bouncy_terrain_flag) > 0) then
            handle_bouncy_collision_x(collision_result)
        elseif ((collision_result.flag & terrain_flag > 0)) then
            -- normal terrain
            player.colliding_x = true
            if (collision_result.last_non_collision_x ~= nil) then
                player.x = collision_result.last_non_collision_x
            else
                player.x = collision_result.collision_x
            end
            calculate_stored_energy_x()
            player.dx = player.x
            player.speed_x = 0
        else
            player.colliding_x = false
            player.x = player.dx
        end
    else
        player.colliding_x = false
        player.x = player.dx
    end

end

function move_y(player)

    if (player.dump_stored_speed_y) then
        player.speed_y = player.speed_y + player.stored_speed_y
        player.stored_speed_y = 0
        player.dump_stored_speed_y = false

        local abs_speed = abs(player.speed_y)
        if (abs_speed > gravity) then
            if (abs_speed < (stored_energy_limit / 3)) then
                sfx(0, -1, 0, 1)
            elseif (abs_speed >= (stored_energy_limit / 3) and abs_speed < ((stored_energy_limit / 3) * 2)) then
                sfx(0, -1, 0, 2)
            elseif (abs_speed >= ((stored_energy_limit / 3) * 2)) then
                sfx(0, -1, 0, 4)
            end
        end
    end

    if (player.speed_y > 0 or player.speed_y < 0) then
        player.dy = player.dy + player.speed_y
        if (sign(player.dy) == 1 and player.stored_speed_y > 0) then
            player.dump_stored_speed_y = true
        end
    end

    local collision_result = check_map_collision_y(player,
        (bouncy_terrain_flag | sloped_terrain_l_flag | sloped_terrain_r_flag | terrain_flag | hazard_flag |
            top_only_hazard_flag | top_only_collision_flag), resolution)

    if (collision_result.collision == true) then
        -- check hazard collisions
        if (collision_result.flag & hazard_flag > 0) then
            check_standard_hazard_hit(collision_result, hazard_flag)
        elseif (collision_result.flag & top_only_hazard_flag > 0) then
            check_top_only_hazard_hit(collision_result, top_only_hazard_flag)
        end
        if (collision_result.flag1 & sloped_terrain_l_flag > 0) then
            handle_slope_collision_left_y(collision_result)
        elseif (collision_result.flag2 & sloped_terrain_r_flag > 0) then
            handle_slope_collision_right_y(collision_result)
        elseif ((collision_result.flag & bouncy_terrain_flag) > 0) then
            handle_bouncy_collision_y(collision_result)
        elseif ((collision_result.flag & terrain_flag > 0) or (collision_result.flag & top_only_collision_flag > 0)) then
            -- normal terrain
            player.colliding_y = true
            player.y = collision_result.collision_y
            calculate_top_only_collision_terrain(collision_result)
            calculate_stored_energy_y()
            player.dy = player.y
            player.speed_y = 0
        else
            player.colliding_y = false
            player.y = player.dy
        end
    else
        player.colliding_y = false
        player.y = player.dy
    end

end

function calculate_top_only_collision_terrain(collision_result)
    if (collision_result.flag & top_only_collision_flag > 0) then
        local tile = nil
        for _, test_tile in pairs(collision_result.tiles) do
            if (tile == nil) then
                tile = test_tile
            elseif test_tile.y < tile.y then
                tile = test_tile
            end
        end
        player.y = ((tile.y * 8) - 8)
    end
end

function calculate_stored_energy_x()
    local stored_energy_x = player.dx - player.x
    if (stored_energy_x ~= 0) then
        local dynamic_bounce_loss_ratio = 1
        if (player.debounce) then
            dynamic_bounce_loss_ratio = dynamic_bounce_loss_ratio - debounce_ratio
        end
        player.stored_speed_x = (player.stored_speed_x - stored_energy_x) * dynamic_bounce_loss_ratio
        if (abs(player.stored_speed_x) > stored_energy_limit) then
            player.stored_speed_x = stored_energy_limit * sign(player.stored_speed_x)
        end
    end
end

function calculate_stored_energy_y()
    local stored_energy_y_after_collision = player.speed_y
    if (player.speed_y > gravity or player.speed_y < 0) then
        local dynamic_bounce_loss_ratio = bounce_loss_ratio
        if (player.debounce) then
            dynamic_bounce_loss_ratio = dynamic_bounce_loss_ratio - debounce_ratio
        end
        player.stored_speed_y = (player.stored_speed_y - player.speed_y) * dynamic_bounce_loss_ratio
        if (abs(player.stored_speed_y) > stored_energy_limit) then
            player.stored_speed_y = (stored_energy_limit * sign(player.stored_speed_y))
        end
    else
        player.dump_stored_speed_y = true
    end
end

function handle_bouncy_collision_x(collision_result)
    local tile = nil
    for _, test_tile in pairs(collision_result.tiles) do
        if (tile == nil) then
            tile = test_tile
        else
            if (player.speed_x <= 0) then
                if (test_tile.x < tile.x) then
                    tile = test_tile
                end
            else
                if (test_tile.x > tile.x) then
                    tile = test_tile
                end
            end
        end
    end
    if (player.speed_x <= 0) then
        player.x = (tile.x * 8) + 9
    else
        player.x = (tile.x * 8) - 9
    end
    if (player.debounce == true) then
        player.speed_x = player.speed_x * -1.1
    else
        player.speed_x = player.speed_x * -1.8
    end
    
    player.dx = player.x
    player.dump_stored_speed_x = true
end

function handle_bouncy_collision_y(collision_result)
    local tile = nil
    for _, test_tile in pairs(collision_result.tiles) do
        if (tile == nil) then
            tile = test_tile
        else
            if (player.speed_y <= 0) then
                if (test_tile.y < tile.y) then
                    tile = test_tile
                end
            else
                if (test_tile.y > tile.y) then
                    tile = test_tile
                end
            end
        end
    end
    if (player.speed_y <= 0) then
        player.y = (tile.y * 8) + 9
    else
        player.y = (tile.y * 8) - 9
    end
    if (player.debounce == true) then
        player.speed_y = player.speed_y * -1.1
    else
        player.speed_y = player.speed_y * -1.8
    end
    player.dy = player.y
    player.dump_stored_speed_y = true
end

function handle_slope_collision_left_y(collision_result)
    player.colliding_y = true
    local tile = nil
    for _, test_tile in pairs(collision_result.tiles) do
        if (tile == nil) then
            tile = test_tile
        elseif test_tile.x < tile.x then
            tile = test_tile
        end
    end
    local tile = collision_result.tiles[1]
    local tile_min_x = (tile.x * 8)
    local tile_max_x = (tile.x * 8) + 8
    local tile_min_y = (tile.y * 8)
    local x_speed = player.speed_x
    if (x_speed < 4 or player.debounce) then
        if ((player.x + 0) >= (tile_min_x) and (player.x + 0) <= tile_max_x) then
            local block_x = ((player.x + 0) - tile_min_x)
            if (block_x < 0) then
                block_x = 0
            end
            common_slope_y_calculation()
            player.y = tile_min_y + block_x - 6
            player.dy = player.y
        end
    else
        player.y = player.dy
        player.stored_speed_y = 0
    end
    player.x = player.dx

end

function handle_slope_collision_left_x(collision_result)
    player.colliding_x = true
    local tile = nil
    for _, test_tile in pairs(collision_result.tiles) do
        if (tile == nil) then
            tile = test_tile
        elseif test_tile.y > tile.y then
            tile = test_tile
        end
    end
    local tile = collision_result.tiles[1]
    local tile_min_x = (tile.x * 8)
    local tile_max_x = (tile.x * 8) + 8
    local tile_min_y = (tile.y * 8)
    local x_speed = player.speed_x
    if (x_speed < 4 or player.debounce) then
        if ((player.x + 0) >= tile_min_x and (player.x + 0) <= tile_max_x) then
            local block_x = ((player.x + 0) - tile_min_x)
            if (block_x < 0) then
                block_x = 0
            end
            common_slope_y_calculation()
            player.y = tile_min_y + block_x - 8
        end
    else
        player.y = player.dy
        player.stored_speed_y = 0
    end
    player.x = player.dx

end

function common_slope_y_calculation()
    if (player.debounce) then
        player.speed_y = gravity * 3
    else
        player.dy = player.y
        player.speed_y = 0
        player.stored_speed_y = 0
    end
end

function handle_slope_collision_right_y(collision_result)
    player.colliding_y = true
    local tile = nil
    for _, test_tile in pairs(collision_result.tiles) do
        if (tile == nil) then
            tile = test_tile
        elseif test_tile.x > tile.x then
            tile = test_tile
        end
    end
    local tile = collision_result.tiles[1]
    local tile_min_x = (tile.x * 8)
    local tile_max_x = (tile.x * 8) + 8
    local tile_max_y = (tile.y * 8) + 8
    local x_speed = player.speed_x
    if (x_speed > -4 or player.debounce) then
        if ((player.x + 8) >= tile_min_x and (player.x + 8) <= tile_max_x) then
            local block_x = ((player.x + 8) - tile_min_x)
            if (block_x < 0) then
                block_x = 0
            end
            common_slope_y_calculation()
            player.y = tile_max_y - block_x - 6
            player.dy = player.y
        end
    else
        player.y = player.dy
        player.stored_speed_y = 0
    end
    player.x = player.dx

end

function handle_slope_collision_right_x(collision_result)
    player.colliding_x = true
    local tile = nil
    for _, test_tile in pairs(collision_result.tiles) do
        if (tile == nil) then
            tile = test_tile
        elseif test_tile.y > tile.y then
            tile = test_tile
        end
    end
    local tile = collision_result.tiles[1]
    local tile_min_x = (tile.x * 8)
    local tile_max_x = (tile.x * 8) + 8
    local tile_max_y = (tile.y * 8) + 8
    local x_speed = player.speed_x
    if (x_speed > -4 or player.debounce) then
        if ((player.x + 8) >= tile_min_x and (player.x + 8) <= tile_max_x) then
            local block_x = ((player.x + 8) - tile_min_x)
            if (block_x < 0) then
                block_x = 0
            end
            common_slope_y_calculation()
            player.y = tile_max_y - block_x - 8
        end
        if (btn(3)) then
            player.speed_x = player.speed_x - 0.7
        end
    else
        player.y = player.dy
        player.stored_speed_y = 0
    end

    player.x = player.dx

end

function check_standard_hazard_hit(collision_result, hazard_flag)
    local tiles = tile_centers_at_corners(player.x, player.y, player.x + 8, player.y, player.x, player.y + 8,
        player.x + 8, player.y + 8)
    for _, tile in pairs(tiles) do
        if ((tile.flag & hazard_flag) > 0) then
            local hazard_collides = box_collision(player.x + 4, player.y + 4, player.width, player.height,
                tile.center_x, tile.center_y, 4, 4)
            if (hazard_collides) then
                player.hazard_hit = true
                hazard_hit_animation = 0
                break
            end
        end
    end
end

function check_top_only_hazard_hit(collision_result, top_only_hazard_flag)
    local tiles = tile_centers_at_corners(player.x, player.y, player.x + 8, player.y, player.x, player.y + 8,
        player.x + 8, player.y + 8)
    for _, tile in pairs(tiles) do
        if ((tile.flag & top_only_hazard_flag) > 0) then
            local hazard_collides = box_collision(player.x + 4, player.y + 4, player.width, player.height,
                tile.center_x, (tile.center_y - 2), 4, 4)
            if (hazard_collides) then
                player.hazard_hit = true
                hazard_hit_animation = 0
                break
            end
        end
    end
end

function apply_friction(player)
    local friction = ground_friction
    if (player.colliding_y == false) then
        friction = air_friction
    end

    if (player.speed_x > 0) then
        player.speed_x = player.speed_x - friction
        if (player.speed_x < 0) then
            player.speed_x = 0
        end
    end
    if (player.speed_x < 0) then
        player.speed_x = player.speed_x + friction
        if (player.speed_x > 0) then
            player.speed_x = 0
        end
    end

    local quantum_gravity = gravity
    if (player.speed_x > 5) then
        quantum_gravity = relativity_gravity
    end
    player.speed_y = player.speed_y + quantum_gravity

    if (player.speed_y > vertical_add_energy_limit) then
        player.speed_y = vertical_add_energy_limit
    end
end

function non_physical_collisions()
    for i = 1, #checkpoint_locations, 1 do
        if (i ~= current_checkpoint) then
            if (box_collision(player.x, player.y, player.width, player.height, checkpoint_locations[i][1],
                checkpoint_locations[i][2], 8, 8)) then
                sfx(1)
                current_checkpoint = i
            end
        end
    end

end
