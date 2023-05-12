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

