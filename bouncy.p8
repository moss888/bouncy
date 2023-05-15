pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--bouncy by broommoss
--⬅️➡️⬇️ to move. x,z to debounce
-- Utilities for LUA programming
frame_counter = 0
debug = true

function log(text)
    if debug then
        printh(text, "log")
        -- printh(time() .. " " .. text, "log")
    end
end

function shallow_copy(t)
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function update_framecount()
    frame_counter = frame_counter + 1
    if frame_counter > 30 then
        frame_counter = 1
    end
end

function position_to_maptile_coord(x, y)
    local result = {}
    result.x = flr(x / 8)
    result.y = flr(y / 8)
    return result
end

function sign(x)
    return x > 0 and 1 or x < 0 and -1 or 0
end

function tile_centers_at_corners(x1, y1, x2, y2, x3, y3, x4, y4)
    local corners = {}
    corners[1] = position_to_maptile_coord(x1, y1)
    corners[2] = position_to_maptile_coord(x2, y2)
    corners[3] = position_to_maptile_coord(x3, y3)
    corners[4] = position_to_maptile_coord(x4, y4)
    corners[1].center_x = (corners[1].x * 8) + 4
    corners[1].center_y = (corners[1].y * 8) + 4
    corners[2].center_x = (corners[2].x * 8) + 4
    corners[2].center_y = (corners[2].y * 8) + 4
    corners[3].center_x = (corners[3].x * 8) + 4
    corners[3].center_y = (corners[3].y * 8) + 4
    corners[4].center_x = (corners[4].x * 8) + 4
    corners[4].center_y = (corners[4].y * 8) + 4
    corners[1].flag = fget(mget(corners[1].x, corners[1].y))
    corners[2].flag = fget(mget(corners[2].x, corners[2].y))
    corners[3].flag = fget(mget(corners[3].x, corners[3].y))
    corners[4].flag = fget(mget(corners[4].x, corners[4].y))
    return corners
end

function tile_directly_below_player(x1, y1)
    local tile = {}
    tile[1] = position_to_maptile_coord(x1 + 2, y1 + 8)
    tile[1].center_x = (tile[1].x * 8) + 4
    tile[1].center_y = (tile[1].y * 8) + 4
    tile[1].flag = fget(mget(tile[1].x, tile[1].y))
    return tile
end

function check_sloped_map_collision_y(obj, collision_flag, resolution)
    result = {
        collision = false
    }
    return result
end

function check_sloped_map_collision_x(obj, collision_flag, resolution)
    result = {
        collision = false
    }
    return result
end

function points_distance(x1, y1, x2, y2)
    local result = sqrt((((x2 - x1) ^ 2) + ((y2 - y1) ^ 2)))
    return result
end

function check_map_collision_y(obj, collision_flag, resolution)
    local result = {
        collision = false
    }

    local distance = abs(obj.dy - obj.y)
    local direction = sign((obj.dy - obj.y))
    local p1, p2 = {
        x = obj.x,
        y = obj.y,
        height_mod = 0
    }, {
        x = obj.x + obj.width,
        y = obj.y,
        height_mod = 0
    }

    if (direction == -1) then
        p1.x, p1.y, p1.height_mod = obj.x + 1, obj.y, 0
        p2.x, p2.y, p2.height_mod = obj.x + obj.width - 1, obj.y, 0
    elseif (direction == 1) then
        p1.x, p1.y, p1.height_mod = obj.x + 1, obj.y, (obj.height - resolution)
        p2.x, p2.y, p2.height_mod = obj.x + obj.width - 1, obj.y, (obj.height - resolution)
    end

    for i = 0, distance, resolution do
        -- line(p1.x, p1.y + p1.height_mod + (direction * i), p2.x, p2.y + p2.height_mod + (direction * i), rnd(12))
        local p1_map_tile = position_to_maptile_coord(p1.x, p1.y + p1.height_mod + (direction * i))
        local p2_map_tile = position_to_maptile_coord(p2.x, p2.y + p2.height_mod + (direction * i))
        -- rect(p1_map_tile.x * 8, (p1_map_tile.y) * 8, (p1_map_tile.x * 8) + 8, (p1_map_tile.y * 8) + 8, rnd(12))

        local p1_flag = fget(mget(p1_map_tile.x, p1_map_tile.y))
        local p2_flag = fget(mget(p2_map_tile.x, p2_map_tile.y))
        if ((p1_flag & collision_flag) > 0) or ((p2_flag & collision_flag) > 0) then
            result.collision = true
            result.flag = p1_flag | p2_flag
            result.flag1 = p1_flag
            result.flag2 = p2_flag
            result.collision_y = p1.y + (direction * i)
            result.tiles = {}
            if ((p1_flag & collision_flag) > 0) then
                result.tiles[#result.tiles + 1] = p1_map_tile
            end
            if ((p2_flag & collision_flag) > 0) then
                result.tiles[#result.tiles + 1] = p2_map_tile
            end
            break
        else
            result.last_non_collision_y = p1.y + (direction * i)
        end
    end

    return result
end

function box_collision(obj1_x, obj1_y, obj1_w, obj1_h, obj2_x, obj2_y, obj2_w, obj2_h)
    local collision_x_length = (obj1_w / 2) + (obj2_w / 2)
    local collision_y_length = (obj1_h / 2) + (obj2_h / 2)
    local x_diff = abs(obj2_x - obj1_x)
    local y_diff = abs(obj2_y - obj1_y)
    if (x_diff <= collision_x_length and y_diff <= collision_y_length) then
        return true
    else
        return false
    end
end

function check_map_collision_x(obj, collision_flag, resolution)
    local result = {
        collision = false
    }

    local distance = abs(obj.dx - obj.x)
    local direction = sign((obj.dx - obj.x))
    local p1, p2 = {
        x = obj.x,
        y = obj.y + resolution,
        width_mod = 0
    }, {
        x = obj.x,
        y = obj.y + obj.height - resolution,
        width_mod = 0
    }

    if (direction == -1) then
        p1.x, p1.y, p1.width_mod = obj.x + 0.5, obj.y + 2, 0
        p2.x, p2.y, p2.width_mod = obj.x + 0.5, (obj.y + obj.height - 2), 0
    elseif (direction == 1) then
        p1.x, p1.y, p1.width_mod = obj.x, obj.y + 2, obj.width - 0.5
        p2.x, p2.y, p2.width_mod = obj.x, (obj.y + obj.height - 2), obj.width - 0.5
    end

    for i = 0, distance, resolution do
        -- line(p1.x + p1.width_mod + (direction * i), p1.y, p1.x + p1.width_mod + (direction * i), p2.y, rnd(12))
        local p1_map_tile = position_to_maptile_coord(p1.x + p1.width_mod + (direction * i), p1.y)
        local p2_map_tile = position_to_maptile_coord(p2.x + p2.width_mod + (direction * i), p2.y)
        local p1_flag = fget(mget(p1_map_tile.x, p1_map_tile.y))
        local p2_flag = fget(mget(p2_map_tile.x, p2_map_tile.y))
        -- rect(p1_map_tile.x * 8, (p1_map_tile.y) * 8, (p1_map_tile.x * 8) + 8, (p1_map_tile.y * 8) + 8, rnd(12))

        if (((p1_flag & collision_flag) > 0) or ((p2_flag & collision_flag) > 0)) then
            result.collision = true
            result.flag = p1_flag | p2_flag
            result.flag1 = p1_flag
            result.flag2 = p2_flag
            result.collision_x = p1.x + (direction * i)
            result.tiles = {}
            if ((p1_flag & collision_flag) > 0) then
                result.tiles[#result.tiles + 1] = p1_map_tile
            end
            if ((p2_flag & collision_flag) > 0) then
                result.tiles[#result.tiles + 1] = p2_map_tile
            end
            break
        else
            result.last_non_collision_x = p1.x + (direction * i)
        end
    end

    return result
end




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
        elseif ((collision_result.flag & top_only_collision_flag > 0)) then
            calculate_top_only_collision_terrain(collision_result)
            player.colliding_x = false
            player.x = player.dx
        else
            player.colliding_x = false
            player.x = player.dx
        end
    else
        player.colliding_x = false
        player.x = player.dx
    end

end

function dump_store_speed_y_sfx()
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

function move_y(player)

    if (player.dump_stored_speed_y) then
        player.speed_y = player.speed_y + player.stored_speed_y
        player.stored_speed_y = 0
        player.dump_stored_speed_y = false
        dump_store_speed_y_sfx()
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
            if((collision_result.flag & terrain_flag == 0))then
                calculate_top_only_collision_terrain(collision_result)
            end
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
        player.speed_x = player.speed_x * -1.6
    end
    if (abs(player.speed_x) > max_x_speed) then
        if (sign(player.speed_x) > 0) then
            player.speed_x = max_x_speed
        else
            player.speed_x = max_x_speed * -1
        end
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
        player.speed_y = player.speed_y * -1.6
    end
    player.dy = player.y
    player.dump_stored_speed_y = true
end

function handle_slope_collision_left_y(collision_result)
    last_slope_flag_used = sloped_terrain_l_flag
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
    if (x_speed < slope_speed_threshold or player.debounce) then
        if ((player.x + 0) >= (tile_min_x) and (player.x + 0) <= tile_max_x) then
            local block_x = ((player.x + 0) - tile_min_x)
            if (block_x < 0) then
                block_x = 0
            end
            player.y = tile_min_y + block_x - 6
            common_slope_y_calculation()
        end
    else
        player.y = player.dy
        player.stored_speed_y = 0
    end
    player.x = player.dx

end

function handle_slope_collision_left_x(collision_result)
    last_slope_flag_used = sloped_terrain_l_flag
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
    if (x_speed < slope_speed_threshold or player.debounce) then
        if ((player.x + 0) >= tile_min_x and (player.x + 0) <= tile_max_x) then
            local block_x = ((player.x + 0) - tile_min_x)
            if (block_x < 0) then
                block_x = 0
            end
            player.y = tile_min_y + block_x - 8
            common_slope_y_calculation()
        end
    else
        player.y = player.dy
        player.stored_speed_y = 0
    end
    player.x = player.dx

end

function handle_slope_collision_right_y(collision_result)
    last_slope_flag_used = sloped_terrain_r_flag
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
    if (x_speed > (slope_speed_threshold * -1) or player.debounce) then
        if ((player.x + 8) >= tile_min_x and (player.x + 8) <= tile_max_x) then
            local block_x = ((player.x + 8) - tile_min_x)
            if (block_x < 0) then
                block_x = 0
            end
            player.y = tile_max_y - block_x - 6
            common_slope_y_calculation()
        end
    else
        player.y = player.dy
        player.stored_speed_y = 0
    end
    player.x = player.dx

end

function handle_slope_collision_right_x(collision_result)
    last_slope_flag_used = sloped_terrain_r_flag
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
    if (x_speed > (slope_speed_threshold * -1) or player.debounce) then
        if ((player.x + 8) >= tile_min_x and (player.x + 8) <= tile_max_x) then
            local block_x = ((player.x + 8) - tile_min_x)
            if (block_x < 0) then
                block_x = 0
            end
            player.y = tile_max_y - block_x - 8
            common_slope_y_calculation()
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
    end
    if (btn(3) and (player.debounce == false)) then
        player.slope_jump_mode = 2
        calculate_stored_energy_slope_y()
        player.dy = player.y
    elseif player.slope_jump_mode == 2 then
        player.dump_stored_speed_y = true
        -- if (last_slope_flag_used == sloped_terrain_r_flag) then
        --     player.stored_speed_x = (player.stored_speed_y/1.7)
        -- else
        --     player.stored_speed_x = ((player.stored_speed_y/1.7) * -1)
        -- end
        player.dump_stored_speed_x = true
        player.speed_y = 0
        player.dy = player.y
        player.slope_jump_mode = 1
    elseif (player.slope_jump_mode > 0 and player.slope_jump_mode < 2) then
        player.slope_jump_mode = player.slope_jump_mode - 1
        player.y = player.dy
    else
        player.dy = player.y
        player.speed_y = 0
        player.stored_speed_y = 0
    end
end

function calculate_stored_energy_slope_y()
    local stored_energy_y_after_collision = player.speed_y
    if (player.speed_y > gravity or player.speed_y < 0) then
        local dynamic_bounce_loss_ratio = bounce_loss_ratio
        if (player.debounce) then
            dynamic_bounce_loss_ratio = dynamic_bounce_loss_ratio - debounce_ratio
        end
        player.stored_speed_y = (player.stored_speed_y - (player.speed_y / 5)) * (dynamic_bounce_loss_ratio)
        if (abs(player.stored_speed_y) > stored_energy_limit) then
            player.stored_speed_y = (stored_energy_limit * sign(player.stored_speed_y))
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

function check_standard_hazard_hit(collision_result, hazard_flag)
    local tiles = tile_centers_at_corners(player.x, player.y, player.x + 8, player.y, player.x, player.y + 8,
        player.x + 8, player.y + 8)
    for _, tile in pairs(tiles) do
        if ((tile.flag & hazard_flag) > 0) then
            local hazard_collides = box_collision(player.x + 4, player.y + 4, player.width, player.height,
                tile.center_x, tile.center_y, 3.5, 3.5)
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



-- pico8_import utilities.lua
function _init()
    -- log('bouncy init called')
    terrain_flag = 0x2
    bubble_power_enabled = false
    death_count = 0
    hazard_flag = 0x4
    camera_offset_x = 0
    camera_offset_y = 0
    bouncy_terrain_flag = 0x80
    top_only_hazard_flag = 0x8
    sloped_terrain_l_flag = 0x10
    sloped_terrain_r_flag = 0x20
    top_only_collision_flag = 0x40
    -- {{letter='?',x=0,y=0,color=7}}
    letters_to_draw = {}
    button_sets = {{
        buttons = {{
            x = 65,
            y = 34,
            state = false,
            timeout = 30,
            always_on = true
        }, {
            x = 66,
            y = 37,
            state = false,
            timeout = 30,
            always_on = true
        }, {
            x = 67,
            y = 34, 
            state = false,
            timeout = 30,
            always_on = true
        }, {
            x = 68,
            y = 37,
            state = false,
            timeout = 30,
            always_on = true
        }, {
            x = 69 ,
            y = 34,
            state = false,
            timeout = 30,
            always_on = true
        }, {
            x = 70,
            y = 37,
            state = false,
            timeout = 30,
            always_on = true
        }},
        label = 'final_door',
        final_door_open = false
    }, {
        buttons = {{
            x = 1,
            y = 20,
            state = false,
            timeout = 30,
            always_on = true
        }, {
            x = 14,
            y = 20,
            state = false,
            timeout = 30,
            always_on = true
        }},
        label = 'seed_door',
        seed_door_open = false
    }, {
        buttons = {{
            x = 16,
            y = 53,
            state = false,
            timeout = 30,
            always_on = true,
            text = {
                letter = 'P',
                x = 141,
                y = 441,
                color = 7
            }

        }, {
            x = 126,
            y = 62,
            state = false,
            timeout = 30,
            always_on = true,
            text = {
                letter = 'U',
                x = 157,
                y = 441,
                color = 7
            }
        }, {
            x = 45,
            y = 44,
            state = false,
            timeout = 30,
            always_on = true,
            text = {
                letter = 'S',
                x = 173,
                y = 441,
                color = 7
            }
        }, {
            x = 78,
            y = 42,
            state = false,
            timeout = 30,
            always_on = true,
            text = {
                letter = 'H',
                x = 189,
                y = 441,
                color = 7
            }
        }, {
            x = 113,
            y = 44,
            state = false,
            timeout = 30,
            always_on = true,
            text = {
                letter = chr(94),
                x = 205,
                y = 443,
                color = 7
            }
        }},
        label = 'blue_goo',
        blue_goo_open = false
    },{
        buttons = {{
            x = 82,
            y = 20,
            state = false,
            timeout = 30,
            always_on = true
        }},
        label = 'laser_switch',
        laser_switch_activated = false
    }}
    final_door_animation = 0
    seed_captured = false
    game_over_animation = 0
    game_over = false
    last_slope_flag_used = sloped_terrain_l_flag
    slope_speed_threshold = 4
    current_checkpoint = -1
    rolling_ball_index_count = 1
    -- electric boxes (tile_start_x,tile_start_y,tile_end_x,tile_end_y,alignment,max_count,animation_count)
    electric_boxes = {{
        sx = 57,
        sy = 50,
        ex = 57,
        ey = 51,
        direction = 'y',
        max_count = 90,
        style = 'osc',
        count = 0
    }, {
        sx = 76,
        sy = 48,
        ex = 80,
        ey = 48,
        direction = 'x',
        max_count = 90,
        style = 'osc',
        count = 0
    }, {
        sx = 76,
        sy = 45,
        ex = 80,
        ey = 45,
        direction = 'x',
        max_count = 45,
        style = 'osc',
        count = 0
    }, {
        sx = 27,
        sy = 35,
        ex = 30,
        ey = 35,
        direction = 'x',
        max_count = 60,
        style = 'osc',
        count = 0
    }, {
        sx = 48,
        sy = 33,
        ex = 48,
        ey = 36,
        direction = 'y',
        max_count = 145,
        style = 'osc',
        count = 0
    }, {
        sx = 51,
        sy = 33,
        ex = 51,
        ey = 36,
        direction = 'y',
        style = 'osc',
        max_count = 90,
        count = 0
    }, {
        sx = 54,
        sy = 33,
        ex = 54,
        ey = 36,
        style = 'osc',
        direction = 'y',
        max_count = 120,
        count = 0
    }, {
        sx = 78,
        sy = 17,
        ex = 78,
        ey = 30,
        direction = 'y',
        max_count = 160,
        count = 0,
        style = 'on',
        label = 'laser_switch_pair'
    }}

    -- tile_start_x,tile_start_y,tile_end_x,tile_end_y,max_count,animation_count            
    slime_emitter_locations = {{100, 17, 100, 26, 72, 0}, {106, 17, 106, 20, 90, 0}, {86, 23, 86, 30, 90, 0},
                               {11, 41, 11, 49, 140, 0}, {11, 41, 11, 49, 140, 0}, {126, 41, 126, 61, 200, 0},
                               {99, 44, 99, 44, 70, 0}, {104, 44, 104, 45, 70, 0},{109, 44, 109, 45, 120, 0}}
    slime_sprite_indexes = {32, 33, 34}
    -- x,y,sprite#
    slime_sprites_to_draw = {}
    checkpoint_locations = {{136, 24}, {345, 16}, {704, 16}, {992, 192}, {752, 224}, {448, 168}, {88, 216}, {136, 490}}
    checkpoint_sprites = {73, 74}
    rolling_ball_indexes = {7, 8, 9, 10}
    x_squish_ball_indexes = {27, 28, 29}
    y_squish_ball_indexes = {11, 12, 13}
    horizontal_add_energy = 0.7
    vertical_add_energy = 1.7
    bounce_loss_ratio = 0.8
    debounce_ratio = 0.6
    max_x_speed = 30
    vertical_add_energy_limit = 8
    horizontal_add_energy_limit = 5
    stored_energy_limit = 8
    ground_friction = 0.3
    air_friction = 0.2
    gravity = 0.3
    relativity_gravity = 0.1
    resolution = 0.1
    camera_x_front_boundry = 212
    camera_y_top_boundry = 212
    camera_y_bottom_boundry = 340

    camera_x_back_boundry = 0
    hazard_hit_animation = 0
    seed_door_animation = 0
    blue_goo_animation = 0
    music_pattern_playing = -1
    player_defaults = {
        hazard_hit = false,
        x = 64,
        y = 112,
        dx = 64,
        dy = 112,
        width = 8,
        height = 8,
        speed_x = 0,
        speed_y = 0,
        stored_speed_x = 0,
        stored_speed_y = 0,
        dump_stored_speed_y = false,
        dump_stored_speed_x = false,
        ball_sprite_index = rolling_ball_indexes[1],
        ball_sprite_flip_x = false,
        ball_sprite_flip_y = false,
        colliding_x = false,
        colliding_y = false,
        debounce = false,
        slope_jump_mode = 0
    }
    player = shallow_copy(player_defaults)

end

function get_user_input(player)
    if btn(0) then
        if (player.colliding_y and btn(3)) then
            player.speed_x = player.speed_x * 0.95
        else
            player.speed_x = player.speed_x - horizontal_add_energy
            if (player.speed_x <= (horizontal_add_energy_limit * -1)) then
                player.speed_x = (horizontal_add_energy_limit * -1)
            end
        end
    end
    if btn(1) then
        if (player.colliding_y and btn(3)) then
            player.speed_x = player.speed_x * 0.95
        else
            player.speed_x = player.speed_x + horizontal_add_energy
            if (player.speed_x >= horizontal_add_energy_limit) then
                player.speed_x = horizontal_add_energy_limit
            end

        end
    end
    if btn(3) then
        player.speed_y = player.speed_y + vertical_add_energy
        if (player.speed_y >= vertical_add_energy_limit) then
            player.speed_y = vertical_add_energy_limit
        end
        if (player.colliding_y) then
            player.speed_x = player.speed_x * 0.95
        end
    end
    if btn(2) and bubble_power_enabled then
        player.speed_y = player.speed_y - (gravity + resolution)
        if (player.speed_y <= (vertical_add_energy_limit * -1)) then
            player.speed_y = vertical_add_energy_limit * -1
        end
    end
    if btn(4) or btn(5) then
        player.debounce = true
    else
        player.debounce = false
    end
    -- if btn(5) then
    --     player.hazard_hit = true
    -- end

end

function set_ball_sprite_index()
    player.ball_sprite_flip_x = false
    player.ball_sprite_flip_y = false

    local dx = player.dx
    local x = player.x
    local dy = player.dy
    local y = player.y

    if (dx < x) then
        rolling_ball_index_count = rolling_ball_index_count - 1
        if (rolling_ball_index_count < 1) then
            rolling_ball_index_count = 4
        end
    elseif (dx > x) then
        rolling_ball_index_count = rolling_ball_index_count + 1
        if (rolling_ball_index_count > 4) then
            rolling_ball_index_count = 1
        end
    end

    local x_squish_ball_index = get_x_squish_ball_index()
    local y_squish_ball_index = get_y_squish_ball_index()

    if ((x_squish_ball_index > -1 and player.colliding_x) or (y_squish_ball_index > -1 and player.colliding_y)) then
        if (y_squish_ball_index > -1) then
            player.ball_sprite_index = y_squish_ball_indexes[y_squish_ball_index]
            if (sign(player.stored_speed_y) == 1) then
                player.ball_sprite_flip_y = true
            end
        else
            player.ball_sprite_index = x_squish_ball_indexes[x_squish_ball_index]
            if (dx < x) then
                player.ball_sprite_flip_x = true
            end
        end
    else
        player.ball_sprite_index = rolling_ball_indexes[rolling_ball_index_count]
    end

end

function get_x_squish_ball_index()
    local result = -1
    local abs_stored_speed_x = abs(player.stored_speed_x)

    if abs_stored_speed_x > 2.5 and abs_stored_speed_x <= 5 then
        result = 1
    elseif abs_stored_speed_x > 5 and abs_stored_speed_x <= 8 then
        result = 2
    elseif abs_stored_speed_x > 8 then
        result = 3
    end

    return result
end

function get_y_squish_ball_index()
    local result = -1
    local abs_stored_speed_x = abs(player.stored_speed_y)

    if abs_stored_speed_x > 2.5 and abs_stored_speed_x <= 5 then
        result = 1
    elseif abs_stored_speed_x > 5 and abs_stored_speed_x <= 8 then
        result = 2
    elseif abs_stored_speed_x > 8 then
        result = 3
    end

    return result
end

function reset_player()
    pal()
    death_count = death_count + 1
    player = shallow_copy(player_defaults)
    camera_x_front_boundry = 212
    camera_x_back_boundry = 0
    hazard_hit_animation = 0
    if (current_checkpoint > 0) then
        checkpoint = checkpoint_locations[current_checkpoint]
        player.x = checkpoint[1]
        player.y = checkpoint[2]
        player.dx = checkpoint[1]
        player.dy = checkpoint[2]
        if (current_checkpoint == 1) then
            camera_x_front_boundry = 212
            camera_x_back_boundry = 0
        else
            camera_x_front_boundry = player.x + 12
            camera_x_back_boundry = player.x - 28
            camera_offset_x = player.x - 72
        end
    end
end

function _update()

    update_framecount()
    if (player.hazard_hit) then
        hazard_hit_animation = hazard_hit_animation + 1
        if (hazard_hit_animation > 30) then
            reset_player()
        end
    else
        update_buttons()
        update_seed_door()
        update_blue_goo()
        update_electric_boxes()
        update_seed_status()
        update_final_door()
        get_user_input(player)
        move_x(player)
        move_y(player)
        non_physical_collisions()
        slime_emitters()
        apply_friction(player)
        check_oob()
    end

end

function check_oob()
    if(player.x < -8 or player.y < -8 or player.x > 1024 or player.y > 520)then
        player.hazard_hit = true
        hazard_hit_animation = 0
    end
end




function update_seed_status()
    if (seed_captured == false and (final_door_animation > 0)) then
        if (box_collision(player.x + 4, player.y + 4, 8, 8, 996, 268, 6, 6) == true) then
            seed_captured = true
            mset(124, 33, 0)
            mset(124, 34, 0)
            bubble_power_enabled = false
            blue_goo_animation = 109
        end
    else
        if (seed_captured == true and box_collision(player.x + 4, player.y + 4, 8, 8, 64, 120, 16, 8) == true and final_door_animation > 0) then
            game_over = true
            seed_captured = false
            game_over_animation = 1
            mset(15, 14, 20)
            mset(14, 14, 6)

        end
    end
end

function handle_game_over_animation()
    if (game_over == true and game_over_animation > 0) then
        if (game_over_animation == 1) then
            sfx(47, -1)
        elseif (game_over_animation == 30) then
            mset(7, 14, 124)
            mset(8, 14, 124)
        elseif (game_over_animation == 90) then
            mset(7, 14, 123)
        elseif (game_over_animation == 150) then
            mset(7, 13, 122)
            sfx(48, -1)
        elseif (game_over_animation == 300) then
            music(57, -1)
        else
            if (game_over_animation >= 301) then
                print('A GAME BY BROOMMOSS', 24, 60, 11)
                print('A GAME BY BROOMMOSS', 25, 61, 0)
            end
            if (game_over_animation >= 420) then
                print('YOU DIED ' .. death_count .. ' TIMES', 29, 70, 0)
                print('YOU DIED ' .. death_count .. ' TIMES', 30, 71, 7)
            end
            if (game_over_animation >= 540) then
                if (death_count == 0) then
                    print('RANK S : BETTER THAN MOSS', 14, 82, 0)
                    print('RANK S : BETTER THAN MOSS', 15, 82, 11)
                    circ(player.x + 3, player.y + 3, 8, 7)
                    circ(player.x + 3, player.y + 3, 7, 10)
                    circ(player.x + 3, player.y + 3, 6, 7)
                    circ(player.x + 3, player.y + 3, 5, 10)
                elseif (death_count >= 1 and death_count < 10) then
                    print('RANK A : APEX BOUNCER', 20, 81, (9))
                    print('RANK A : APEX BOUNCER', 21, 82, (10))
                elseif (death_count >= 10 and death_count < 30) then
                    print('RANK B : BONIFIED BOUNCER', 14, 81, (9))
                    print('RANK B : BONIFIED BOUNCER', 15, 82, (10))
                elseif (death_count >= 30 and death_count < 50) then
                    print('RANK C : CERTIFIED BOUNCER', 12, 81, (0))
                    print('RANK C : CERTIFIED BOUNCER', 13, 82, (7))
                elseif (death_count >= 50 and death_count < 60) then
                    print('RANK D : DARING BOUNCER', 18, 81, (0))
                    print('RANK D : DARING BOUNCER', 19, 82, (7))
                elseif (death_count >= 60 and death_count < 70) then
                    print('RANK F : FAMOUS BOUNCER', 18, 81, (0))
                    print('RANK F : FAMOUS BOUNCER', 19, 82, (7))
                elseif (death_count >= 70 and death_count < 80) then
                    print('RANK G : GOOD BOUNCER', 20, 81, (0))
                    print('RANK G : GOOD BOUNCER', 21, 82, (7))
                elseif (death_count >= 80 and death_count < 90) then
                    print('RANK H : HARDY BOUNCER', 19, 81, (0))
                    print('RANK H : HARDY BOUNCER', 20, 82, (7))
                elseif (death_count >= 90 and death_count < 100) then
                    print('RANK J : JOVIAL BOUNCER', 18, 81, (0))
                    print('RANK J : JOVIAL BOUNCER', 19, 82, (7))
                elseif (death_count >= 100) then
                    print('RANK K : KINDLY BOUNCER', 18, 81, (0))
                    print('RANK K : KINDLY BOUNCER', 19, 82, (7))
                end
            end
            if (game_over_animation >= 800) then
                print('THANKS FOR PLAYING!', 24, 91, 11)
                print('THANKS FOR PLAYING!', 25, 92, 0)
            end
        end
        if (game_over_animation < 1000) then
            game_over_animation = game_over_animation + 1
        end
    end
end

function draw_seed()
    if (seed_captured == true) then
        spr(61, player.x, player.y)
        print('RETURN', 985, 256, 11)
        print('TO', 993, 262, 11)
        print('START', 987, 268, 11)
    end
end

function update_buttons()
    for _, bset in pairs(button_sets) do
        local all_on = true
        for _, button in pairs(bset.buttons) do
            if (box_collision(player.x + 4, player.y + 4, 8, 8, ((button.x * 8) + 4), ((button.y * 8) + 4), 10, 10) and
                button.timeout < 1) then
                if (button.state == false) then
                    button.state = true
                    set_button_sprite(button)
                    sfx(0, -1, 16, 6)
                    if (bset.label == 'blue_goo') then
                        handle_blue_goo_button_activate(button)
                    end
                else
                    if (button.always_on == false) then
                        button.state = false
                        set_button_sprite(button)
                        sfx(0, -1, 24, 6)
                    end
                end
                button.timeout = 20

            end
            if (button.timeout > 0) then
                button.timeout = button.timeout - 1
            end
            if (button.state == false) then
                all_on = false
            end
        end
        if (all_on) then
            if (bset.label == 'seed_door') then
                if (bset.seed_door_open == false) then
                    seed_door_animation = 1
                    bset.seed_door_open = true
                end
            elseif (bset.label == 'blue_goo') then
                if (bset.blue_goo_open == false) then
                    blue_goo_animation = 1
                    bset.blue_goo_open = true
                end
            elseif (bset.label == 'final_door') then
                if (bset.final_door_open == false) then
                    final_door_animation = 1
                    bset.final_door_open = true
                end
            elseif (bset.label == 'laser_switch') then
                if (bset.laser_switch_activated == false) then
                    bset.laser_switch_activated  = true
                    for _,box in pairs(electric_boxes) do
                        if(box.label=='laser_switch_pair')then
                            box.style = 'off'
                        end
                    end
                end
            end
        end
    end
end

function handle_blue_goo_button_activate(button)
    letters_to_draw[(#letters_to_draw + 1)] = button.text
    local computer_tile_1 = position_to_maptile_coord(button.text.x, button.text.y)
    mset(computer_tile_1.x, computer_tile_1.y, 97)
    mset(computer_tile_1.x + 1, computer_tile_1.y, 98)
end

function update_blue_goo()
    if (blue_goo_animation > 0) then
        if (bubble_power_enabled == false) then
            if (blue_goo_animation == 1) then
                mset(28, 57, 96)
            elseif (blue_goo_animation == 15) then
                mset(28, 57, 113)
                mset(28, 58, 113)
            elseif (blue_goo_animation == 30) then
                mset(28, 57, 96)
                mset(28, 58, 96)
                mset(28, 59, 96)
            elseif (blue_goo_animation == 45) then
                mset(28, 57, 113)
                mset(28, 58, 113)
                mset(28, 59, 113)
                mset(28, 60, 113)
            elseif (blue_goo_animation == 60) then
                mset(28, 57, 96)
                mset(28, 58, 96)
                mset(28, 59, 96)
                mset(28, 60, 96)
                mset(28, 61, 112)
            elseif (blue_goo_animation == 75) then
                mset(28, 57, 113)
                mset(28, 58, 113)
                mset(28, 59, 113)
                mset(28, 60, 113)
                mset(28, 61, 114)
                mset(28, 62, 121)
            elseif (blue_goo_animation == 90) then
                mset(28, 57, 96)
                mset(28, 58, 96)
                mset(28, 59, 96)
                mset(28, 60, 96)
                mset(28, 61, 112)
                mset(28, 62, 121)
            end
            blue_goo_animation = blue_goo_animation + 1
            if (blue_goo_animation == 105) then
                blue_goo_animation = 75
            end
            if (blue_goo_animation >= 75 and blue_goo_animation <= 105) then
                check_blue_goo_machine_collision()
            end
            if (blue_goo_animation == 110) then
                sfx(44, -1)
            elseif (blue_goo_animation == 230) then
                blue_goo_animation = -1
                bubble_power_enabled = true
            end
        end
    end
end

function draw_bubble_powerup_get()
    if (blue_goo_animation >= 110 and blue_goo_animation < 130) then
        circ(player.x + 4, player.y + 4, 8, rnd(16))
        circ(player.x + 4, player.y + 4, 7, rnd(16))
    elseif (blue_goo_animation >= 130 and blue_goo_animation < 150) then
        circ(player.x + 4, player.y + 4, 7, rnd(16))
        circ(player.x + 4, player.y + 4, 6, rnd(16))
    elseif (blue_goo_animation >= 150 and blue_goo_animation < 170) then
        circ(player.x + 4, player.y + 4, 6, rnd(16))
        circ(player.x + 4, player.y + 4, 5, rnd(16))
        circ(player.x + 4, player.y + 4, 8, rnd(16))
        circ(player.x + 4, player.y + 4, 7, rnd(16))
    elseif (blue_goo_animation >= 170 and blue_goo_animation < 190) then
        circ(player.x + 4, player.y + 4, 7, rnd(16))
        circ(player.x + 4, player.y + 4, 6, rnd(16))
    elseif (blue_goo_animation >= 190 and blue_goo_animation < 210) then
        circ(player.x + 4, player.y + 4, 6, rnd(16))
        circ(player.x + 4, player.y + 4, 5, rnd(16))
    elseif (blue_goo_animation >= 210 and blue_goo_animation < 230) then
        circ(player.x + 4, player.y + 4, 5, rnd(16))
        circ(player.x + 4, player.y + 4, 4, rnd(16))
    end
end

function check_blue_goo_machine_collision()
    if (box_collision(player.x + 4, player.y + 4, 8, 8, 228, 500, 12, 12) and blue_goo_animation < 110 and
        bubble_power_enabled == false) then
        blue_goo_animation = 110
        mset(28, 57, 2)
        mset(28, 58, 2)
        mset(28, 59, 2)
        mset(28, 60, 2)
        mset(28, 61, 120)
        mset(28, 62, 117)
    end
end

function update_electric_boxes()
    for _, boxes in pairs(electric_boxes) do
        local active_count = (boxes.max_count / 2)
        if (boxes.direction == 'y') then
            if ((boxes.count >= active_count and boxes.style=='osc') or boxes.style=='on') then
                for i = boxes.sy, boxes.ey, 1 do
                    if (boxes.count % 4 == 0) then
                        if (i % 2 == 0) then
                            mset(boxes.sx, i, 56)
                        else
                            mset(boxes.sx, i, 57)
                        end
                    else
                        if (i % 2 == 0) then
                            mset(boxes.sx, i, 57)
                        else
                            mset(boxes.sx, i, 56)
                        end
                    end
                end
                mset(boxes.sx, (boxes.sy - 1), 54)
                mset(boxes.sx, (boxes.ey + 1), 55)
            else
                for i = boxes.sy, boxes.ey, 1 do
                    mset(boxes.sx, i, 2)
                end
                mset(boxes.sx, (boxes.sy - 1), 50)
                mset(boxes.sx, (boxes.ey + 1), 51)
            end
        end
        if (boxes.direction == 'x') then
            if ((boxes.count >= active_count and boxes.style=='osc') or boxes.style=='on') then
                for i = boxes.sx, boxes.ex, 1 do
                    if (boxes.count % 4 == 0) then
                        if (i % 2 == 0) then
                            mset(i, boxes.sy, 58)
                        else
                            mset(i, boxes.sy, 59)
                        end
                    else
                        if (i % 2 == 0) then
                            mset(i, boxes.sy, 59)
                        else
                            mset(i, boxes.sy, 58)
                        end
                    end
                end
                mset(boxes.sx - 1, boxes.sy, 52)
                mset(boxes.ex + 1, boxes.sy, 53)
            else
                for i = boxes.sx, boxes.ex, 1 do
                    mset(i, boxes.sy, 2)
                end
                mset(boxes.sx - 1, boxes.sy, 48)
                mset(boxes.ex + 1, boxes.sy, 49)
            end
        end
        boxes.count = boxes.count + 1
        if (boxes.count > boxes.max_count) then
            boxes.count = 0
        end
    end
end

function update_final_door()
    if (final_door_animation <= 90 and final_door_animation > 0) then
        if (final_door_animation == 1) then
            music(-1)
            sfx(26, -1)
        end
        if (final_door_animation == 30) then
            mset(72, 36, 0)
            mset(73, 36, 0)
            mset(72, 35, 44)
            mset(73, 35, 44)
            mset(123, 34, 0)
            mset(124, 34, 62)
            mset(125, 34, 0)
            mset(123, 33, 44)
            mset(124, 33, 44)
            mset(125, 33, 44)
        end
        if (final_door_animation == 60) then
            mset(72, 35, 0)
            mset(73, 35, 0)
            mset(123, 33, 0)
            mset(124, 33, 61)
            mset(125, 33, 0)
            mset(123, 32, 44)
            mset(124, 32, 44)
            mset(125, 32, 44)

        end
        if (final_door_animation == 90) then
            mset(72, 35, 0)
            mset(73, 35, 0)
            mset(123, 33, 0)
            mset(124, 33, 61)
            mset(125, 33, 0)
            mset(123, 32, 0)
            mset(124, 32, 0)
            mset(125, 32, 0)
        end
        final_door_animation = final_door_animation + 1
    end
end

function update_seed_door()
    if (seed_door_animation <= 90 and seed_door_animation > 0) then
        if (seed_door_animation == 1) then
            music(-1)
            sfx(26, -1)
        end
        if (seed_door_animation == 30) then
            mset(3, 30, 0)
            mset(4, 30, 0)
            mset(3, 29, 44)
            mset(4, 29, 44)
            mset(3, 28, 45)
            mset(4, 28, 45)
        end
        if (seed_door_animation == 60) then
            mset(3, 29, 0)
            mset(4, 29, 0)
            mset(3, 28, 44)
            mset(4, 28, 44)
        end
        if (seed_door_animation == 90) then

        end
        seed_door_animation = seed_door_animation + 1
    end
end

function process_hazard_hit_animation()
    if (hazard_hit_animation == 5) then
        sfx(2)
    end
    if (hazard_hit_animation > 5 and hazard_hit_animation < 10) then
        pal(8, 2)

    elseif (hazard_hit_animation > 10 and hazard_hit_animation < 15) then
        pal(2, 5)

    elseif (hazard_hit_animation > 20) then
        pal(8, 1)
    end
end

function _draw()
    cls()
    draw_map()
    if (player.hazard_hit == false) then
        if (player.debounce) then
            pal(8, 9)
        elseif btn(2) and bubble_power_enabled then
            pal(8, 12)
        else
            pal()
        end
    end
    draw_slime()
    draw_letters()
    draw_bubble_powerup_get()
    draw_checkpoints()
    handle_game_over_animation()
    spr(player.ball_sprite_index, player.x, player.y, 1, 1, player.ball_sprite_flip_x, player.ball_sprite_flip_y)
    draw_seed()
    if (player.hazard_hit) then
        process_hazard_hit_animation()
    end

end

function draw_letters()
    for _, letter in pairs(letters_to_draw) do
        print(letter.letter, letter.x, letter.y, letter.color)
    end
end

-- x_start,y_start,x_end,y_end,max_count,animation_count,sprite_x,sprite_y
slime_drop_in_frames = 6
slime_drop_in_frames_one_third = flr(slime_drop_in_frames / 3)
slime_drop_in_frames_two_third = (flr(slime_drop_in_frames / 3) * 2)

function slime_emitters()
    slime_sprites_to_draw = {}
    for i, slime in ipairs(slime_emitter_locations) do
        local x_tile_start, y_tile_start, x_tile_end, y_tile_end, max_count, animation_count = unpack(slime)
        animation_count = animation_count + 1
        if (animation_count > max_count) then
            animation_count = 0
        end
        local slime_sprite = slime_sprite_indexes[1]
        local real_space_tiles = ((y_tile_end - y_tile_start) + 1)
        local current_y_tile = flr(animation_count / slime_drop_in_frames)
        local sprite_x = -1
        local sprite_y = -1
        -- only worry about slime drops which are visible
        if (current_y_tile <= (real_space_tiles + 1)) then
            local frame_remainder = animation_count % slime_drop_in_frames
            if (current_y_tile == (real_space_tiles + 1)) then
                sprite_x = x_tile_end * 8
                sprite_y = y_tile_end * 8
                if (frame_remainder < slime_drop_in_frames_one_third) then
                    slime_sprite = slime_sprite_indexes[2]
                elseif ((frame_remainder >= slime_drop_in_frames_one_third) and
                    (frame_remainder < slime_drop_in_frames_two_third)) then
                    slime_sprite = slime_sprite_indexes[3]
                else
                    slime_sprite = 0
                end
            else
                sprite_x = x_tile_start * 8
                if (frame_remainder < slime_drop_in_frames_one_third) then
                    sprite_y = (y_tile_start * 8) + (8 * (current_y_tile - 1))
                elseif ((frame_remainder >= slime_drop_in_frames_one_third) and
                    (frame_remainder < slime_drop_in_frames_two_third)) then
                    sprite_y = (y_tile_start * 8) + (8 * (current_y_tile - 1)) + 2
                else
                    sprite_y = (y_tile_start * 8) + (8 * (current_y_tile - 1)) + 4
                end
            end
            add(slime_sprites_to_draw, {
                x = sprite_x,
                y = sprite_y,
                sprite = slime_sprite
            })
            if (box_collision(player.x + 4, player.y + 4, player.width, player.height + 4, sprite_x + 4, sprite_y, 4, 6)) then
                player.hazard_hit = true
                hazard_hit_animation = 0
            end
        end
        slime[6] = animation_count
        slime_emitter_locations[i] = slime
    end
end

function set_button_sprite(button)
    if (button.state == true) then
        mset(button.x, button.y, 47)
    else
        mset(button.x, button.y, 46)
    end
end

function draw_slime()
    for _, obj in pairs(slime_sprites_to_draw) do
        spr(obj.sprite, obj.x, obj.y, 1, 1)
    end
end

function draw_checkpoints()
    for i, checkpoint in ipairs(checkpoint_locations) do
        if (current_checkpoint == i) then
            spr(checkpoint_sprites[2], checkpoint[1], checkpoint[2], 1, 1)
        else
            spr(checkpoint_sprites[1], checkpoint[1], checkpoint[2], 1, 1)
        end
    end
end

function draw_map()

    if (player.y >= 0 and player.y < 128) then
        camera_offset_y = 0
        if (music_pattern_playing ~= 1 and game_over == false) then
            music(1, -1)
            music_pattern_playing = 1
        end
    elseif (player.y >= 128 and player.y < 254) then
        camera_offset_y = 128
        if (music_pattern_playing ~= 2) then
            music(16, -1)
            music_pattern_playing = 2
        end
        pal(12, 5)
    elseif (player.y >= 254 and player.y < 512) then
        pal(12, 1)
        if (music_pattern_playing ~= 3) then
            music(32, -1)
            music_pattern_playing = 3
        end
        if (player.y <= 297) then
            camera_offset_y = 254
        elseif (player.y >= 468) then
            camera_offset_y = 384
        elseif (player.y > camera_y_bottom_boundry) then
            camera_offset_y = (player.y - 84)
            camera_y_bottom_boundry = player.y
            camera_y_top_boundry = camera_y_bottom_boundry - 40
        elseif (player.y < camera_y_top_boundry) then
            camera_offset_y = (player.y - 44)
            camera_y_top_boundry = player.y
            camera_y_bottom_boundry = camera_y_top_boundry + 40
        end
    end

    if (player.x < 127 and game_over == false) then
        camera_offset_x = 0
        music(-1, -1)
        music_pattern_playing = -1
    elseif (player.x >= 127 and player.x < 164) then
        camera_offset_x = 120
    elseif (player.x > camera_x_front_boundry and player.x <= 980) then
        camera_offset_x = (player.x - 84)
        camera_x_front_boundry = player.x
        camera_x_back_boundry = camera_x_front_boundry - 40
    elseif (player.x < camera_x_back_boundry and player.x >= 128) then
        camera_offset_x = (player.x - 44)
        camera_x_back_boundry = player.x
        camera_x_front_boundry = camera_x_back_boundry + 40
    elseif (player.x > 980) then
        camera_offset_x = 896
        camera_x_back_boundry = 940
    end

    -- log('back:' .. camera_x_back_boundry .. ' front:' .. camera_x_front_boundry)
    if (camera_x_front_boundry < 212) then
        camera_x_front_boundry = 212
    end
    if (camera_x_back_boundry < 0) then
        camera_x_front_boundry = 0
    end

    camera(camera_offset_x, camera_offset_y)
    map()
end





__gfx__
00000000cccccccccccccccccccccccccccccccccccccccccccccccc00222200002222000022220000222200000000000000000000000000cccccccccccccccc
00000000cccccccccccccccccccccccccccc7777ccccccccccccccc5028888200288882002888820028888200000000000000000000000007777cccccccccccc
00000000cc77777cccccccccccccccccc7777777cccccccccccccccc288888822888888228778882288877820022220000000000000000007777777ccc777777
00000000c77777ccccccccccccccccccccc77777ccccccccccccccc528888882288888822878888228888782028888200222222000000000777777ccc7777777
00000000cccccccccccccccccccccccccccccccccccccccccccccccc28888782287888822888888228888882288888822888888202222220cccccccccc777777
00000000ccccccccccccccccccccccccccccccccccccccccccccccc528887782287788822888888228888882288888822888888228888882ccccccccccccccc7
00000000cccccccccccccccccccccccccccccccccccccccccccccccc02888820028888200288882002888820288888822888888288888888cccccccccccccccc
00000000cccccccccccccccc5c5c5c5ccccccccc55555555c5c5c5c500222200002222000022220000222200022222200222222022222222cccccccccccccccc
cccccccccccccccc66666666666666666666666666666666ccccccccc5c5c5c55c5c5c5c5c5c5c5c5c5c5c5c000022200000222000000282cccccccc55555555
5cccccccccccccc5606606666066766066606666066666765ccccccccccccccccccccccccccccccccccccccc0002888200028882000028827777777755555555
cccccccccccccccc66666667666666666666667666660666ccccccccccccccc55ccccccccccccccccccccccc0028888200028882000028827777777755555555
5cccccccccccccc5676666666666066766766666667666665ccccccccccccccccccccccccccccccccccccccc0028888200028882000028827777777756566566
cccccccccccccccc66606660666666666666676666666606ccccccccccccccc55ccccccccccccccccccccccc0028888200028882000028827777777765565656
5cccccccccccccc5666666666667666666066666606676665ccccccccccccccccccccccccccccccccccccccc0028888200028882000028827777777756656665
cccccccccccccccc66676606606660667666660666666666ccccccccccccccc55ccccccccccccccccccccccc000288820002888200002882cccccccc66565656
5c5c5c5cccccccc5666666666666666666666666666666665ccccccccccccccccccccccccccccccc5c5c5c5c000022200000222000000282cccccccc65666666
000300000000000000000000ca9a9a9c6d6d6d6ddddd6d6dd6d6ddddd666666dddddddddd6cdc6cdd666666d76767676ddddddddddddddddd8d8d8d8d8d8d8d8
000b08000000000000000000a98888a966666666dad6666666666dad66666666daaaaaad6c6c6c6c6666666666666667dddddddddddddddd8aaaaaad8aaaaaad
003bb0000000000000000000988ee88a66666666dad6666666666dadd666666ddddddddd6cd6ccc6d666666d7666666698989898ddddddddda5555a8dabb7ba8
00bbb30000000b0000000000a8ee7e8966666666dad6666666666dad66666666d666666d6ccc6dc66666666666666667dddddddddddddddd8a5555ad8abbb7ad
00bbbb00b00000000000000098eeee8a66666666dad6666666666dadd666666d66666666c6cd6cc6d666666d7666666666666666ddddddddda5555a8dabbbba8
003bb3000000b000000000b0a88ee88966666666dad6666666666dadddddddddd666666ddc6cc6c6666666666666666700000000dddddddd8a5555ad8abbbbad
000330000003000b000000009a88889a66666666dad6666666666daddaaaaaad6666666666c6666dd666666d7666666600000000dddddddddaaaaaa8daaaaaa8
00000000bb3b33b3b33bb3b3c9a9a9ac6d6d6d6ddddd6d6dd6d6ddddddddddddd666666ddcdcdcdc666666666767676700000000dddddddd8d8d8d8d8d8d8d8d
6666666cc666666666666666cc7cc7cc6666666cc666666666666666cba7a7bccb9999bccb9999bcccccccccccccccccbbbbbbbb0000000077777777cc5ccccc
6888886cc6eeeee668877886666666666aaaaa6bb6bbbbb66aa77aa666666666c399793cc399793c3b3b3b3b3b3b3b3bbbbbbbbb0000000066666666cc5ccccc
68777767767777e6687777866e7887e66a77776a767777b66a7777a66b7aa7b6cb9999bccb7999bc99997999999997993bbbbbb30000b00066666666cc5ccccc
677eee6cc6888776687ee7866e7887e6677bbb67a6aaa7766a7bb7a66b7aa7b6c379993cc399993c9999999999799999533b33340004b0000655556055555555
677eee6cc6888776687ee7866e7887e6677bbb6a76aaa7766a7bb7a66b7aa7b6cb9999bccb9999bc9799997999999979224325240004400006566560ccccc5cc
68777767767777e6687ee7866e7777e66a777767a67777b66a7bb7a66b7777b6c399993cc397993c9999999979999999242425420000000006566560ccccc5cc
6888886cc6eeeee6666666666ee77ee66aaaaa6bb6bbbbb6666666666bb77bb6cb9979bccb9999bc3b3b3b3b3b3b3b3b222424240000000006566560ccccc5cc
6666666cc6666666cc7cc7cc666666666666666cc6666666cb7a7abc66666666c399993cc399973ccccccccccccccccc44554554000000000656656055555555
cccccccccccccccccc22c2cccc22c2cccc22c2cccc22c2cccccccccccccc2c22cccccccc00666600007777006dd6d66dbbbbbbbbcccccc56cccccc6666666666
cccccccccccccccccc22c2222222c2cccc22c2cccc22c2cccccccccccccc2c225cccccc50668866007722770666d66d6bbbb3bbbccccc566cccc666666606665
cccccccccccccccccc22c222222cc2cccc22c2cccc22c2ccccccccccccc2cc22cccccccc6688886677288277766d66d63bbbbbb3cccc5666cc6666666666665c
cccccccccccccccccc22cccccccc2ccccc22c2cccc22c2ccccccccccccc2c22c5cccccc5688888867288782766d6dd66633b3b36ccc5667677666666666665cc
ccc22222222ccccccc22c222222cc2cccc22c2cccc22c2cccc22c2ccccc2c22ccccccccc68888886728888276d6db6d663636366cc5666667777766667665ccc
cc2222222222cccccc22c2222222c2cccc22cc22222cc2cccc22c2cccc2cc22c5cccccc5aa9999aaaa9999aad66636d666636376c5666666cc7777766665cccc
cc22cccccccc2ccccc22c2cccc22c2cccc22ccccccccc2cccc22c2cccc2c22ccccccccccaaa99aaaaaa99aaa666b3b6d6766636656660666cccc7777665ccccc
cc22c222222cc2cccc22c2cccc22c2ccccc2222222222ccccc22c2cccc2c22cc5cccccc50aaaaaa00aaaaaa06bb3bbb66666666666666666cccccc7765cccccc
cc22c2cccc22c2cccc22c2cccc22c2cc22c2ccccccccccccccccccccc22cc2cccccccccc22d22222ccc77ccc66cccccc65cccccc666666667766666666666666
cc22c2cccc22c2cccc22c2cccc22c2cc22c2cccccccccccccccccccc22cc2ccc5cccccc522d22222ccc77ccc6666cccc665ccccc676666767776666656676666
cc22c2cccc22c2cccc22c2cccc22c2cc22cc2cc2cccccccccccccccc2cc2cccccccccccc22d22222cc6677cc666666cc6665cccc66666666c776666cc5666666
cc22c2cccc22c2cccc22c2cccc22c2ccc22c2c22cccccccccccccccccc2ccccc5cccccc5ddddddddcc6677cc6666667766665ccc66666666c777666ccc566606
cc22c2cccc22c2cccc22cc22222cc2ccc22c222c2222cccc22c2ccccc2cccccccccccccc22222d22c666777c66677777606665cc66660666cc7766ccccc56666
cc22c2cccc22c2cccc22ccccccccc2ccc22cc2cc2222cccc22c2cccc2ccccccc5cccccc522222d22c666677c677777cc6666665c66666666cc7766cccccc5666
cc22c2cccc22c2cccc22cccccccc2ccccc22ccc2cccccccc22c2cccccccccccccccccccc22222d22666667777777cccc6666766560666676ccc77cccccccc566
cc22c2cccc22c2ccccc222222222cccccc22cc2c2222cccc22c2cccccccccccc5c5cc5c5dddddddd6666667777cccccc6666666666666666ccc77ccccccccc56
cccc939cdddddddddddddddddddddddddddddddd225222222242222442422224dd3333dd22622222cccccc526711117667111176dddddddd25cccccc55555555
cccc9b9cd11111111111111dd11111111111111d225222222452424224422242d333333d22622222ccccc5226111111661111116d989898d225ccccc22522225
cccc939cd16333333366661dd16111111166661d2252222222442424224424243336666322622222cccc52226117711661177116dddddddd2225cccc2252225c
cccc9b9cd1633333336aa61dd16111111160061d5555555554555555554555543366666666666666ccc5dddd617117166171171661711716dddd5ccc555555cc
cccc939cd1633333336aa61dd16111111160061d22222522442225422242252433bb666622222622cc522d2267111176671111766711117622d225cc22225ccc
cccc9b9cd16333333366661dd16111111166661d22222522224244222424254233bbb66622222622c5222d22dddddddd611111166111111622d2225c2225cccc
cccc939cd11111111111111dd11111111111111d222225222224254422242424d33bb66d2222262252222d22d898989d611771166117711622d22225225ccccc
cccc9b9cd16666666666661dd16666666666661d555555555545455544554554dd3333dd66666666dddddddddddddddd6171171661711716dddddddd25cccccc
cccc939ccccc9b9ccccc9b9cd16666666666661d6d6d6d6d4224222422424222cccccccc95959595c7cc7c7ccccbbccccccccccc22225225cccccccc24522224
cccc9b9ccccc939ccccc939c5166666666666615dd0000d64225424222242222cccccccc55bbbb59c77c77cccccbbccccccccccc52225225555555cc24522242
cccc939ccccc9b9ccccc9b9c61111111111111166000000d2425424222242222cccccccc9bbbbbb5777777c7cbcbbcccccccccccc52255556666665c22424422
ccc77777cccc939cccc777776166666666666616d00dd0065455545555454455ccc777775bbaabb9c77aa77cccbbbccccccccccccc5252256666766555545545
cccd6666cccc9b9ccccd66666166666666666616600dd00d2244454224224542cccd66669bbaabb5779aaa77ccbbbccccbccbccbccc552256666666522242542
cccd6bb6cccc939ccccd6aa65166666666666615d00000062424252442422424cccd60065bbbbbb9c7999a7cbccbbbcbcbcbbccbcccc52255555666522424522
cccd6bb6cccc9b9ccccd6aa6d11111111111111d6d0000dd4222454222422524cccd600695bbbb557777777cbbcbbccbbbcbbbcbccccc525ccc5666524222442
cccd6666cccc939ccccd6666ddddddddddddddddd6d6d6d65554554555545555cccd666659595959c7c7b7ccbbbbbbbbbbbbbbbbcccccc55ccc5555554554554
6666a20000a29595959595202020206766b520202020202020767676202020202020202020202020202020922020d76723667623677723665656666777677767
77677767776777667666762020202020202020202020202020202020202020202020202020202020202020202020202020202020202050502020b2d2d2d2b256
7666a20000a295959595e5202020207777b520202020202020567777202020202020202020202020202020322020202020202020202020202056323232323256
668276827682766777567720202020202020202020202020202020202020202020202050502020202020202020205050202020202050f3f32020b2d286d2b256
7766a20000a2959595e520202020205677b5202020a5a520206676762020a6f7e620202020202092202020322020202020202020202020202020202020202056
56e276e276e27667565677202020202020202020202020202020202020202020202050f3f3202020202020202050f3f32020202020f3f3202020b2c2c2c2b256
7666a20000a29595e52020207620207756b52020e467672020565603202013f7f7f7f76666202032202020322020202020202020202020202056667632202020
20202020202020b286d2b22020202020202020202020202020202020202020202020f3f3202020202020202020f3f32020202020202020202092424242424242
7766a20000a295e5202020207720207656b52020e47676202066667720206777566777f756202032202020202020202020202020202020202056567632202020
20202020202020b2c2c2b22020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202092929292926777
7666a20000a2e520202020207620205667b52020e4766720205667562020667666765677f720202020202020202066f733667633c37733667656565632202032
c376e266e266e266766676202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020a6f7766677
7766a20000a22020202020327720207666b52020e45666202020202020206777677766766676c3c3c35676766656f76656567666567777677756565632323276
56667267726672567656562020202020202020202020505020202020202020202020202020202020202020202020202020202020202020202020a6f7f7767756
7695a20000a22020202020767620207756b52020e456f72020202020202066765656677756565656677777667676566676665667667677677756567767776777
77677767776777677756f62020a5a5a5202020202050f3f320202020929292922020929292202020202020202020202020202020202020202020f77767765656
9595a20000a22020202020927720205666762020667676f756c3c3c3566667775656f62020202020202020202020202020202020202020202020202020202020
202020202020202020202020a6f766f7e620202020f3f320202020205656666620a6f75677929292929292a5a5a5a5a5a5a52020202020202020672020202056
9595a20000a2202050502020762020776756202067567767776777667667777756f6202020202020505020202020202020202020202020202020202020202020
5050202020202020202020a6f7765666f7e6202020202020202020205656567720f7565676667666766756565656565656f7e620202020202020e52020202067
7795a20000a22050f3f32020772020762020202020202050f3f32020202020202020202020202050f3f32020a5a5a5a5a5a5a5a5a52020202020202020202050
f3f32020202020202020a6f77756e25656f7e62020202020202020205677765620d777767667776777676666766656565667f720202020202020202066762066
7666a20000a220f3f32020207620207720202020202020f3f32020202020202020202020202020f3f320202066424242424242626620202020202020202020f3
f32020202020202020a6f767772020207756f7e62020202020202020777677562020202020202020202020202020202056567720202020202020202067772056
7766a20000a2202020202020772020762020202020202020202020202020202020202020202020202020202067e22020202020e4672020202020202020202020
20202020202020202077565656202020766776562020202020202020d7776656e620202020202020202020202020202020e27620202020202020202067772067
7676a20000a220202020202076202067202020202020202020202020202020202020203220202020202020206742622020202082672020202020202020202020
2020202020202020207756660320202013767776202020202032202020d7677676565666f7e62020202020202020202056f77720202020202020202066762056
7776a20000a220202020202077202076202020202020202020202020202020202020202020202020202020205656a220202020a2662020202020202020202020
202020202020202020666676202020202077777720202020202020202020d7666777676777f77767c367667667c37756f7667620202020505020202067562077
7695a20000a262202020202076202077a5a5a5a5a5a5a52020202020202020202020202020202020202020202076a220202020a267a5a5a5a5a5202020202020
2020a5a5a5a5a5a5a567677720202020206777762020202020202020202020d7667667677766565656566777665676565667f620202050f3f320202066562066
7776a20000a292202020202077202076667676766777f62020202020202020202020205050202020202020202076a220202020a2667667776777202020202020
202056667666766676667603202020202013667620202020202020202020202020202020202020202020202020202020202020202020f3f32020202067562067
7676a20000a29220202020207620207732202020202020202092202020202020202050f3f3202020202020202076a22020205242424242426223202020202020
202020202020e520e567f62020202020202067772020202020202020202020202020202020202020202020202020202020202020202020202020202067762056
7776a20000a22020202020327720207656202056567766f776a22020202020202020f3f320202020202020202056a22020202020202020202020202020202020
2020a6f756202020202020202020202020206676202020202020202020202020202020c3c3c3c3c3c3c3c3c38220202020202020202020202020202067772056
7695a20000a22020202020207620207732202020202020e477a22020202020202020202020202020202020202056a22020202020202020202020202020505020
2020f77656202020202020202020202020206756202020202020202020202020202020d73232323232666667a220202020202020202020202020202056672066
7776a20000a220205050202077202067667666765620202076a22020202020202020202020202020202020202056729292924242424242426233202050f3f320
20206777772020202020a6f77666667666766756202020202020202020202020202020202020202020d76767a220202020202020202020202020202056672067
7666a20000a22050f3f3202076202077e220202020202020777220202020202020202020202020202020202020565620202066766676667666762020f3f32020
20205667773276327667f7677667677766777677202020202020202020202020202020a666763220202020202020202020202020202020202020202067772076
7795a20000a220f3f32020207720207666767666765656767676f7e6202020202020203220202020202020202020202020202020202020202020202020202020
2020d766766676666666666756565656567666f6202020202032202020202020202020d756763220202020202020202020202020202020202020a52076672056
7695a20000a220202020209276202077673646364636463646364677202020202020202020202020202020202020202020202020202020202020202020202020
202020202020202020202020202020202020202020202020202020202020202020202020202020202032c356a220202020202020202020202020762076662056
7795a20000a220202020209277202076563747374737473747374776e72020202020202020202020202020202020202020202020202020202020202020202020
2020202020202020202020202020202020202020202020202020202020505020202020a63232323232766656a220202020202020202020202020672077562056
7695a20000a220202020a696762020775656566776677667777677f6202020202020202020202020202020202020202020202020202020202020202020202020
2020202020202020202020202020202020202020202020202020202050f3f3202020205656776777677777777220202020202020202020202020762076562067
7795a20000a2202020e4969577202076202020505020202020202020202020202020202020205050202020202020202020202020202020202050502020202020
20202020202020202020505020202020202020202020202020202020f3f320202020202020202020202020202020202020202020505020202020662077762076
7695a20000a220202020667676202077202050f3f32020202020202020202020202020202050f3f32020202020202020202020202020202050f3f32020202020
20202020202020202050f3f320202020202020202020202020202020202020202020202020202020202020202020202020202050f3f320202020672032772066
76e572000072202020209586772020762020f3f32020202020202020202020202020202020f3f32020202020202020202020202020202020f3f3202020202020
202020202020202020f3f320202020202020202020202020202020202020202020202020202020202020202020202020202020f3f32020202020762020662077
76202000002020202020956676202020202020202020202020202020872020202020202020202020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020772020672066
77202000002020202020766696e62020202020202020202020202020572020202020202020202020202020202020202020202020202020202020202020202020
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202077763277e267
667666f2f27666766676666676966677667656767677565676666767767656565656565667766667677667565666676776677767665656565656766676667667
66765656566676667666766766565656776676667666765656565656677766766656565667667677677766766676665656666666766676776756567666766676
__label__
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
60660666606606666066766060667660666066660666667660660666606676606660666606666676606606666066766066606666066666766066066660667660
66666667666666676666666666666666666666766666066666666667666666666666667666660666666666676666666666666676666606666666666766666666
67666666676666666666066766660667667666666676666667666666666606676676666666766666676666666666066766766666667666666766666666660667
66606660666066606666666666666666666667666666660666606660666666666666676666666606666066606666666666666766666666066660666066666666
66666666666666666667666666676666660666666066766666666666666766666606666660667666666666666667666666066666606676666666666666676666
66676606666766066066606660666066766666066666666666676606606660667666660666666666666766066066606676666606666666666667660660666066
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
666666665c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5cc5c5c5c566666666
60660666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc06666676
666666675cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566660666
67666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66766666
666066605cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566666606
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc60667666
666766065cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566666666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
066666765ccccccccccccccccccccccccccccccccccccccccccccccc77777777777777777777ccccccccccccccccccccccccccccccccccccccccccc506666676
66660666cccccccccccccccccccccccccccccccccccccccccc77777777777777777777777777777ccccccccccccccccccc77777ccccccccccccccccc66660666
667666665cccccccccccccccccccccccccccccccccccccccc77777777777777777777777777777ccccccccccccccccccc77777ccccccccccccccccc566766666
66666606cccccccccccccccccccccccccccccccccccccccccc7777777777777777777777cccccccccccccccccccccccccccccccccccccccccccccccc66666606
606676665cccccccccccccccccccccccccccccccccccccccccccccc77777777777777777ccccccccccccccccccccccccccccccccccccccccccccccc560667666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
666666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566666666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
606606665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc506666676
66666667cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66660666
676666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566766666
66606660ccccccccccc22222222cccccccc22222222ccccc222ccccccc22c2ccccc22222222cccccccc222222222cccc22c2cccccc22c2cccccccccc66666606
666666665ccccccccc2222222222cccccc2222222222cccc2222cccccc22c2cccc2222222222cccccc2222222222cccc22c2cccccc22c2ccccccccc560667666
66676606cccccccccc22cccccccc2ccccc22cccccccc2ccccccc2ccccc22c2cccc22cccccccc2ccccc22cccccccccccc22c2cccccc22c2cccccccccc66666666
666666665ccccccccc22c222222cc2cccc22c222222cc2cc222cc2cccc22c2cccc22c222222cc2cccc22c2222222cccc22c2cccccc22c2ccccccccc566666666
66666666cccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccc22c2ccccc22cc2cccccccccc66666666
066666765ccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccc22c2cccc22cc2cccccccccc506666676
66660666cccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccc22cc2cc22cc2cccccccccccc66660666
667666665ccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2ccccccccccc22c2c22cc2cccccccccccc566766666
66666606cccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2ccccccccccc22c222cc2cccccccccccccc66666606
606676665ccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2ccccccccccc22cc2cc2cccccccccccccc560667666
66666666cccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22ccc2cccccccccccccccc66666666
666666665ccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22cc2cccccccccccccccc566666666
66666666cccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2cccccccccccccccccc66666666
066666765ccccccccc22c2222222c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2ccccccccccccccccc506666676
66660666cccccccccc22c222222cc2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2cccccccccccccccccc66660666
667666665ccccccccc22cccccccc2ccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2ccccccccccccccccc566766666
66666606cccccccccc22c222222cc2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2cccccccccccccccccc66666606
606676665ccccccccc22c2222222c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2ccccccccccccccccc560667666
66666666cccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2cccccccccccccccccc66666666
666666665ccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2ccccccccccccccccc566666666
66666666cccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2cccccccccccccccccc66666666
606606665ccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2ccccccccccccccccc506666676
66666667cccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2cccccccccccccccccc66660666
676666665ccccccccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccccccccccc22c2ccccccccccccccccc566766666
66606660cccccccccc22cc22222cc2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cccc22c2cc2222cccccc22c2cccccccccccccccccc66666606
666666665ccccccccc22ccccccccc2cccc22cc22222cc2cccc22cc22222cc2cccc22c2cccc22c2cccc22cc222222cccccc22c2ccccccccccccccccc560667666
66676606cccccccccc22cccccccc2ccccc22ccccccccc2cccc22ccccccccc2cccc22c2cccc22c2cccc22cccccccccccccc22c2cccccccccccccccccc66666666
666666665cccccccccc222222222ccccccc2222222222cccccc2222222222ccccc22c2cccc22c2ccccc222222222cccccc22c2ccccccccccccccccc566666666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
066666765cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc506666676
66660666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66660666
667666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566766666
66666606cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666606
606676665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc560667666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
666666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566666666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
606606665ccccccccccccccccccc77777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc506666676
66666667ccccccccccccccccc77777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66660666
676666665cccccccccccccccccc77777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566766666
66606660cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666606
666666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc560667666
66676606cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
666666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566666666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
606606665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566606666
66666667cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666676
676666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566766666
66606660cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666766
666666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566066666
66676606cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc76666606
666666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566666666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
666066665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc560660666
66666676cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222cccccccccccccccccccccccccccccccccccccccccccccccccc66666667
667666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccc288882cccccccccccccccccccccccccccccccccccccccccccccccc567666666
66666766cccccccccccccccccccccccccccccccccccccccccccccccccccccccc28888882cccccccccccccccccccccccccccccccccccccccccccccccc66606660
660666665ccccccccccccccccccccccccccccccccccccccccccccccccccccccc28888882ccccccccccccccccccccccccccccccccccccccccccccccc566666666
76666606cccccccccccccccccccccccccccccccccccccccccccccccccccccccc28888782cccccccccccccccccccccccccccccccccccccccccccccccc66676606
666666665ccccccccccccccccccccccccccccccccccccccccccccccccccccccc28887782ccccccccccccccccccccccccccccccccccccccccccccccc566666666
66666666ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc288882ccccccccccccccccccccccccccccccccccccccccccccccccc66666666
606606665ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2222ccccccccccccccccccccccccccccccccccccccccccccccccc566606666
66666667cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666676
676666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566766666
66606660cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666766
666666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566066666
66676606cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc76666606
666666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566666666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
066666765cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc560660666
66660666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666667
667666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc567666666
66666606cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66606660
606676665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566666666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66676606
666666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566666666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666666
606676605cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566606666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666676
666606675cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566766666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66666766
666766665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566066666
60666066cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc76666606
666666665cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc566666666
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5c5c5c5c
606676605ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
666606675ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
66666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
666766665ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
60666066cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
666666665c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5ccccccccccccccccc5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c
66666666666666666666666666666666666666666666666666666666555555555555555566666666666666666666666666666666666666666666666666666666
66606666606606666066766066606666066666766066066660667660555555555555555560660666606676606066066660667660666066660666667666606666
66666676666666676666666666666676666606666666666766666666555555555555555566666667666666666666666766666666666666766666066666666676
66766666676666666666066766766666667666666766666666660667565665665656656667666666666606676766666666660667667666666676666666766666
66666766666066606666666666666766666666066660666066666666655656566556565666606660666666666660666066666666666667666666660666666766
66066666666666666667666666066666606676666666666666676666566566655665666566666666666766666666666666676666660666666066766666066666
76666606666766066066606676666606666666666667660660666066665656566656565666676606606660666667660660666066766666066666666676666606
66666666666666666666666666666666666666666666666666666666656666666566666666666666666666666666666666666666666666666666666666666666

__gff__
0000000000000001010101010101000000000202020200000000000101010002000000800202020202040200020282820202020202020202040404040a0000000000000000000000000000020a200402000000000000000000020404104004020000000000020202024020404040100200000000000202020002000000020240
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
12121313141512131415121314151213141512131213141512131412131414121314121213141512591512131213141512135e5e5e5e151213145e5e5e5e151212135e5e5e5e14151213595912131213121312131213141514141259141512131415121213141512131213141515121314151213141512131415121314151213
121819191919191919191919191917151819191919191919191919191919191917141819191917125914181919191919191902020202191919190202010219191919020202021919194e595914181919191a1a1a1a1a191919171459134f19191a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a19191713
1516020202020f1e1e0e020201021115160202010202020202020202020203021113160103021112591316020202020202020202020202020102020202020202020202020202040e024e5959595916024e131312135d5c02021114595b020211141512131415121314151213141512131412121314121314151213125c021113
12164041404141464041405556461115160202020202020f1e0e02020211131611131611131611125912160203030303030303020202020202020202020202020202020202020202024e5959595916024e13121213144f0202111459135c03031a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1919195f1515181a1a1a1a1a19021115
15165051505151505150500254571115160202030303030303030303030614161115161112161112591316111414141414145d5c020202020202020f1e1e1e1e0e0202020202020202021919191902024e121212595902020211145913125d141512131415121314151512131415155d5c0202111515484b4b15125d5c021114
1516424350515150515050025002111516021113141512131415121314151316111316111316111259141602191919191917145d5c0202020202020202020202020202020202020202020202020202024e1212595902020202111459131213124b4b13144b4b1213134b4b1313141314135c0211151516191919195f15161113
121652534445444550504455500211151602021919191919191919191917121611131611151611125915100303030302021114145d5c02020202020202020202020202020202020202020202020203034e1213590202020202111359151819190202191902021919190202191919191919190211151516020202021113161112
15160202020202020202020202021115160202020202020202020202021115161114161114161112151514151514141602111414145d5c020202020202020202030202020202020202020202034d5d1512125b02020202030306135915160202020202020f0e020202020202041e1e0e02020211151516020202021112161115
121602040e020202020202020202111516020202020202020202020202111416111316111316021a1a1a191714595b020211145913145d5c020202020202024d5d5c0202020202020202024d5d5d14151515145c02024d1314151359151602020202020202020202020202020202020202020211151510020203031112161114
121602020202020202020202020211141003030303030303030303020211131611131611121611121515161113595b03031114595914145d5c02020202024d5d135d5c020202020202024e5d1413141314134b4f0211145959595959141602020202020202020202114c4c160202020202024d5d141512161115124814161113
14160202020202020202020202021112121314151213141213141516021112161115161115161112591216111259141414481259595913135d5c0202024d5d1213145d5c0202020202034e1314134f191919190202111359595959144f02020201020202020202021115141602020202024d5d14141414161114594814101113
1216020202020202020202020202111418191919191919191919190202111516111316111216111259141611155959591448155959595914125d5c024d5d12131213145d5c0202024d5d1213135b020202020303030613595959134f02020202020202114c4c160211131416020202024d5d1414131415161114594814145a13
151602020202020202020202020211121602020202020202020202020211141611131611141611125913161114121314154813595959595915155d5d5d13144b141513145d5c030615151413145b0202024d14131415155959134f02020202020202021115141602111314160202024d5d141414141414161114594815141213
13160202020202020202020202021114160202020202020202020202021113160219021113161112591510031919191a1a11135959595959591512131415121314151412135d5d1213151413145b02020215121312131415124f02020202020202020211141516021115141602024d5d14141313141514161114594815141212
1310030303030302020303030303031a030303030303030303030303030612100303030612100612591413135a5a5a1314581312131415121314151213141512131415121314151213121314155b030303031a1a1a1a1a1a1a0303030303064c4c1003061412100306131416034d5d1414141413131415161114594814141212
141213141512131f1f12131213141514151312121314151213141214131412131313121314151212591412121314151213141512121314151212131213141512131415121314151213141513131312131415131313131313121314151213141513141415121314151213144c125d141512131415141414161114594814151212
595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959594b59595959594b595959595959595959595912161112594814151414
595959595959595e5e59595959595959590202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202027d326f022524242424242424242424242426020202595916191919191902191919191919191919175912161112594813151514
59590202020202020202020202025959590202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202024d5d14141213141512131412131415020202595902020202020202020202020202020202115915161112594813141314
595902020202020202020202020259595b02026a6959595959595959595959595959595959595959595959595959595959595959595959595959696e0202020202020202020202020202020202020202145d14020202020202020202020202020202595916020202020202020202020202020202115915161112594813151414
592e0202020202020202020202022e595b020259595959595959595959595959595959595959595959595959595959595959595959595959595959690202020202020202020202020202020202020202141475020202020202020202020202020202595916020303030303030303030303030302115912161112594813141314
595902020202020202020202020259696e0202020202020202020202020202020202020202020202020202020202020202020202020202020259595902020202020202020202020202020202020202021414140202025a02020202025a020202020259591611131413154c14131314131413131611591516111259165f151514
59590202020202020202020202025959695959595959595959595959595959595959595959595959595959595959595959595959595959020259595902020202020202020202020202020202020202025f13141314154b141213141213124f0202025959161159595959595959595959595959161159121611125916025e5e14
5959020202020202020202020202595959292929292929292929292929292929020202020202020202020202020202020202020202020202025959590202020202020202020202020202020202020202020202020202020202020202020202020202595916115959595959696959595969695916115914161112591602021114
595902020202020202020202020259595902020202020202020202020202020202020202020202020202020202020202020202020202020202595959020202020202020202020202020202020202020202020202020202020202020202020202026a695916115959595959595959595959595916115914161112591602021114
595902020202020202020202020259595902020202020202020202020202020202020202020202020202020202020202020202020202020202595959020202020223020202020202230202020202020202020202020202026a6959595959595959695959160219191919191919191919195959161159154c4c12591003021114
5959292929290202020202020202595959020202020202020202020202020202020202020202020223020202020202022302020228020202025959590202020202020202020202020202020202020202020202020202020259595959595959595959595910020202020202020202020202595916115914151213595959161114
59592b2b2b2b020202020202020259595902020202020202020202020202020202020202020202020202020202020202020202022a02020202595959020202020202020202020202020202020202020202020202020202020202020202020202020259594b141314135a5a141314130202595916115959595959595959161114
59592b682d2b020202020202020259595902020202020202020202020202020202020202020202020202020228020202020202022a020202025959590202020202020202020202020202020202020202020202020202020202020202020202020202595959595959595959595959590202595916021919191919191919021159
59592b2d2d2b0202020202020202020202026a2302020202020202020202236e0202020202020202020202022a020202020202022a02020202595959020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020259696e030303030303030303036a69
59592b2c2c2b0202020202020202020202025923235a5a5a2323235a5a23235902020202594c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c5902025959595a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a33696e020202020202020202020202020202026a595959595959595959595959595959595969595959595959595959596959
5959280000285959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959
__sfx__
010400000c5510e55113551155510050100501005010050115551115510e5510c55100501005010000000000243522635228352293522b3522d35200000000002d3512b351293512835126351243510000000000
010400001813015130181301513018130211003010021100241301a1001c100131001a1303510039100391001c1303910008100051002113015100211301d100211301d1000c1000c1001a100111000310003100
01040000210522105221052210520c002190020c0020c002110521105211052110520c002150020c0020c0020e0520e0520e0520e0520c002300020c0020c0020c0520c0520c0520c0520e0000e0000e00000000
011000000c0330000300003000031163300003000030c000000030c03300003116330000300003000030c033000030000300003116330000300003000030c000000030c0330c000116330c733113000000000000
011000000c033000030000300003116330000300003000030c000000030c13300003116330000300003000030c033000030c00000003116330000300003000030c033000030c0330c000116330c7330c00000000
011000000013002130001000910005130021000010002100001300000009100091300910000130051300010005130051000513002130051000e10000130000000013009100000000213000130001000910000000
011000000013002130001000910005130021000010002100001300000009100091300910000130021300010000130001000213005130051000510002130000000013000000001300210007130001300910000000
0110000000532005320053200532005320053200532005320553205532055320553205532055320553205532025320253202532025320253202532025320e5320953209532095320953209532095320953209532
011000000c5320c5320c5320c5320c5320c5320c5320c532055320553205532055320553205532055320953202532025320253202532025320253202532055320053200532005320053200532005320053200532
01100000211212112121121211311f1211f1211f1311f100181000c1301d1000e1301113021100211001513000000000000000015130000000c1300e1301113000000181300000000000181300c1300000000000
01100000101311013113131131311110011100151301513100000131300000015130111300000000000181300000013130000001113000000000001113011130000000e130000001313000000000001813000000
011000000c1302110121101211010c1301f1011f1011f100181000c1301d1000e1301113021100211001513000000000000000015130000000c1300e1301113000000181300000000000181300c1300000000000
011000000c1302110121101211010c1301f1011f1011f100151300c1001510015100131301513018130151000c130000000000011130000000c1000e1301013015130181000c130000000c1300e1300000000000
011000000c1302110121101211010c1001f1001f1011f1000c1000c1001d10015100111000c1000e100151000c100000000000005100000000c1000e100101000c100211010c1000c10021101001000000000000
311000001563300000000000000000000000000000000000156330000000000000000000000000000000000015633000000000000000000000000000000000001563300000216000000009600000002160000000
311000001563300000000000000009143000000000000000156330000000000000000914300000000000000015633000000000000000091430000000000000001563300000216000000009143000002160000000
311000000c7500f7000e750007000f7500c700117500c7000f750137000e750007000c7500c7500c7500c7000c7500f7000e750007000f7500c700117500c7000f750137000e750007001375212752137520c700
311000000c7500f7000e750007000f7500c700117500c7000f750137000e750007000c7500f700137500c700117500f7000f750007000e7500c7000c7500c7000e750137000f750007001175213752137520c700
311000000c7500f7000e750007000f7500c700117500c7000f750137000e750007000c7500f700137500c700117500f7000f750007000e7500c7000c7500c7000e750137000f7520e7520f7520f7520c7000c700
31100000156330c7310e7310f731091430000000000000001563300000000000000009143000000000000000156330c7310e7310f731091430000000000000001563300000216000000009143000002160000000
c5100000187202472000700247201b720247201b7200f700187202472000700247201b7200c700037000f700187202472000700247201b720247201b7200f700187202472000700247201b720007000070000700
c51000001a7202672000700267201d720267201d720007001a7202672000700267201d7200e70005700007001a7202672000700267201d720267201d720007001a7202672000700267201d720007000070000700
c5100000187202472000700247201b720247201b7200f700187202472000700247201b7200c700037000f700187202472000700247201b720247201b7200f700187202472000700247201f7201f7201f72000700
c51000001a7202672000700267201d720267201d720007001a7202672000700267201d7200e70005700007001a7202672000700267201d720267201d720007001a72026720007002672024720247202472000700
c5100000187202472000700247201b720247201b7200f700187202472000700247201b7200c700037000f700187002470000700247001b700247001b7000f700187002470000700247001f7001f7001f70000700
c51000001a7202672000700267201d720267201d720007001a7202672000700267201d7200e70005700007001a7002670000700267001d700267001d700007001a70026700007002670024700247002470000700
310c00000c15318153241530f1030f1030f1030e1030e10318153181530c1530c1530c15311103151030c1030c1530c153101030c1530c153161030c1530c1530c1530c15312103181530c1530c1000c1530c153
191200000e0330000000000000000e0330000000000000000e0330000000000000000e0330000000000000000e0330000000000000000e0330000000000000000e0330000000000000000e033000000000000000
191200000e0330000000000000000e0330000000000000000e0330000000000000000e0330000000000000000e0330000000000000000e0330000000000000000e0330000000000000000e000000000000000000
191200000e0331a4001a623000000e0331a6001a623000000e0331a4001a623000000e0331a6001a623000000e0331a4001a623000000e0331a6001a623000000e0331a4001a623000000e0331a6001a62300000
091200001122011400124001140011400114000040000400004000040000400004000040000400004000040011220114001140011400114001140011400114001140011400114001140010400114001340011400
011200001142011420144201442016420164201642018420164201642014420144201142011420114200000011420114201442014420164201642016420184201642016420164200000000000114001140011400
011200001142011420144201442016420164201642018420164201442011420114201442014420144201442011420114200f4200f4200f4200f42010420104201142011420114201142011400114000000000000
011200001d4201d4201d4201d420184201842018420184201b4201b4201b4201b420184201842018420184201d4201d42018420184201b4201b42018420184201f4201f4201d4201d4201b4201b4201842018420
011200001d4201d4201d4201d420184201842018420184201b4201b4201b4201b420184201842018420184201d4201b42018420184201642016420184201b4201842018420144201442011420114201142011400
011200000532000000000000000000000000000000000000000000000000000000000000000000000000000005320000000532000000000000000000000000000000000000000000000000000000000000000000
011200000532000000000000000005320000000000000000053200000000000000000532000000000000000005320000000530000000053200000000000000000532000000000000000005320000000000000000
191200000e023000001a623000000e0231a4001a623000000e023000001a623000000e0231a5001a623000000e023000001a623000000e0231a7001a623000000e023000001a623000000e023000001a60000000
011200000532000000053200000005320000000532000000053200000005320000000532000000053200000005320000000532000000053200000005320000000532000000053200000005320000000532000000
011200001142511425114251640511422114051142511425114051142511425144051142211422114051140511425114251142516405114221140511425114251140511425114251440511422114220040500405
011200001142505225114250000005322000001142505225053001142505325000001142205322053000000011425052251142500000053220000011425052250520011425053250000011422053221142200000
011200001d4251d4251d425224051d4221d4051d4251d4251d4051d4251d425204051d4221d4221d4051d4051d4251d4251d425224051d4221d4051d4251d4251d4051d4251d425204051d4221d4220040500405
011200000532505325053250532505325053250532505325053250532505325053250532505325053250532505325053250532505325053250532505325053250532505325053250532505325053250532505325
011200000542505425054250040505425004050542505425054050542505425004050542505425054050542505425054250542500405054250040505425054250540505425054250040505425054250542505400
211000001b532225322a532305323353237532395323b5323b5323853235532325322e532295322553220532235322553227532285322953229532225321d5321153213532135321553217532165321653216532
01120000291222912229100000022910029100291002912229100291222912229100291000000200002000022912229122000020000229100291000000229122291002912229100291251d125291252910000002
01120000291222912229100000022910029100291002912229100291222910029125291252912500002000022912229122000020000229100291000000229122291002912229100291251d125291252910000002
0112000024125261252812529125291252912500005000052412526125281252912529125291250000500005241252612528125291252b125291252b125291252412528125281252612500005260252810026025
01120000241252612528125291252d125291250010500105241252612528125291252d1252912500105001052412526125281252912528125291252d1252d1252b12528125291252d12526000261252900029125
011200001162505625056250562505625056250562505625056250562505625056250562505625056250562505625056250562505625056250562505625056250562505625056250562505625056250562500000
011000000c033000000000000000006350e0000c000000000c033000000000000000006350000000000000000c0330c0000c00000000006350c00000000000000c03300000000000000000635000000000000000
011000000000500005000050000500645000050000500005000050000500005000050064500005000050000500005000050000500005006450000500005000050000500005000050000500645000050000500005
0110000000215132151321513215132150e2000000000000002151821518215182150c21511200112001120000215182150c200242150c20018215000000c2150c21500215002150021500215000000000000000
01100000182251a2251c2251d2251c2250e2000000000000002250c2250c2250c2250c225112001120011200182251a2250c2001c2250c2001d225000001c2250c2250c2250c2250c2250c225000000000000000
011000001f2251d2251c2251a225182251a1001c1001f100002250c2250c2250c2250c2251120011200112001f2251d2250c2001c2250c2001a22500000182250c2250c2250c2250c2250c225000000000000000
0110000000225182251822518225182250e2000000000000002250c2250c2250c2250c22511200112001120000225182250c200242250c20018225000001822524225182250c2250022500225000000000000000
010a000028512215121c51213512275122f512275121f512155120c512135122451225512155121a5122a51233512265120e5121c5122b512185121951226512195121e5122b51221512175121c5121951218512
__music__
01 030d4444
00 040d4444
00 03054444
00 03064344
00 03054444
00 03064444
00 04454744
00 03050744
00 03060844
00 030b0744
00 030a0844
00 03090744
00 040a0844
00 03094544
00 030a4844
02 040c4644
01 0e424344
00 13424344
00 0e105344
00 0e114344
00 0e104344
00 0f124344
00 0f104344
00 0f114344
00 0f101444
00 0f111444
00 0f101544
00 0f111544
00 13101644
00 0f111844
00 13101744
02 0f111944
01 1b424344
00 1b1e4344
00 1c1e4344
00 1d1f2344
00 25202344
00 1d1f2444
00 1d202444
00 1d212444
00 1d222444
00 1d1f2444
00 1d202444
00 1d1f2644
00 1d202644
00 1d276644
00 1d286844
00 1d282969
00 1d2a2969
00 1d1f2a44
00 1d202a44
00 1d1f2a2d
00 25202a2e
00 1d1f2b44
00 25202b44
00 1c286b44
02 1b286b44
01 32734344
00 32747444
00 32357444
00 32367444
00 32343544
00 32343644
02 32377444

