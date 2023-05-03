-- Utilities for LUA programming
frame_counter = 0
debug = true

function log(text)
    if debug then
        printh(text, "log")
        -- printh(time() .. " " .. text, "log")
    end
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
        local p1_map_tile = position_to_maptile_coord(p1.x, p1.y + p1.height_mod + (direction * i))
        local p2_map_tile = position_to_maptile_coord(p2.x, p2.y + p2.height_mod + (direction * i))
        local p1_flag = fget(mget(p1_map_tile.x, p1_map_tile.y))
        local p2_flag = fget(mget(p2_map_tile.x, p2_map_tile.y))
        if (p1_flag == collision_flag or p2_flag == collision_flag) then
            result.collision = true
            result.collision_y = p1.y + (direction * i)
            break
        else
            result.last_non_collision_y = p1.y + (direction * i)
        end
    end

    return result
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
        p1.x, p1.y, p1.width_mod = obj.x, obj.y + 1, 0
        p2.x, p2.y, p2.width_mod = obj.x, (obj.y + obj.height - 1), 0
    elseif (direction == 1) then
        p1.x, p1.y, p1.width_mod = obj.x, obj.y + 1, obj.width - 0.5
        p2.x, p2.y, p2.width_mod = obj.x, (obj.y + obj.height - 1), obj.width - 0.5
    end

    for i = 0, distance, resolution do
        local p1_map_tile = position_to_maptile_coord(p1.x + p1.width_mod + (direction * i), p1.y)
        local p2_map_tile = position_to_maptile_coord(p2.x + p2.width_mod + (direction * i), p2.y)
        local p1_flag = fget(mget(p1_map_tile.x, p1_map_tile.y))
        local p2_flag = fget(mget(p2_map_tile.x, p2_map_tile.y))
        if (p1_flag == collision_flag or p2_flag == collision_flag) then
            result.collision = true
            result.collision_x = p1.x + (direction * i)
            break
        else
            result.last_non_collision_x = p1.x + (direction * i)
        end
    end

    return result
end

