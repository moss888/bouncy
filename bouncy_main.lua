-- pico8_import utilities.lua
function _init()
    log('bouncy init called')
    terrain_flag = 2
    rolling_ball_index_count = 1
    rolling_ball_indexes = {7, 8, 9, 10}
    x_squish_ball_indexes = {27, 28, 29}
    y_squish_ball_indexes = {11, 12, 13}
    horizontal_add_energy = 0.9
    vertical_add_energy = 1.8
    bounce_loss_ratio = 0.8
    debounce_ratio = 0.5
    vertical_add_energy_limit = 8
    horizontal_add_energy_limit = 5
    stored_energy_limit = 8
    friction = 0.4
    gravity = 0.3
    resolution = 0.1
    camera_x_front_boundry = 212
    camera_x_back_boundry = 0
    player = {
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
        debounce = false

    }

end

function get_user_input(player)
    if btn(0) then
        player.speed_x = player.speed_x - horizontal_add_energy
        if (player.speed_x <= (horizontal_add_energy_limit * -1)) then
            player.speed_x = (horizontal_add_energy_limit * -1)
        end
    end
    if btn(1) then
        player.speed_x = player.speed_x + horizontal_add_energy
        if (player.speed_x >= horizontal_add_energy_limit) then
            player.speed_x = horizontal_add_energy_limit
        end
    end
    if btn(3) then
        player.speed_y = player.speed_y + vertical_add_energy
        if (player.speed_y >= vertical_add_energy_limit) then
            player.speed_y = vertical_add_energy_limit
        end
    end
    if btn(4) or btn(5) then
        player.debounce = true
    else
        player.debounce = false
    end

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

function move_y(player)

    if (player.dump_stored_speed_y) then
        player.speed_y = player.speed_y + player.stored_speed_y
        player.stored_speed_y = 0
        player.dump_stored_speed_y = false

        local abs_speed = abs(player.speed_y)
        if (abs_speed > gravity) then
            if (abs_speed < (stored_energy_limit / 3)) then
                sfx(0, -1, 0, 2)
            elseif (abs_speed >= (stored_energy_limit / 3) and abs_speed < ((stored_energy_limit / 3) * 2)) then
                sfx(0, -1, 0, 5)
            elseif (abs_speed >= ((stored_energy_limit / 3) * 2)) then
                sfx(0, -1, 0, 10)
            end
        end
    end

    if (player.speed_y > 0 or player.speed_y < 0) then
        player.dy = player.dy + player.speed_y
        if (sign(player.dy) == 1 and player.stored_speed_y > 0) then
            player.dump_stored_speed_y = true
        end
    end

    local collision_result = check_map_collision_y(player, terrain_flag, resolution)

    if (collision_result.collision == true) then

        player.colliding_y = true
        player.y = collision_result.collision_y
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
        player.dy = player.y
        player.speed_y = 0
    else
        player.colliding_y = false
        player.y = player.dy
    end

end

function move_x(player)

    if (player.stored_speed_x ~= 0) then
        if (sign(player.speed_x) == sign(player.stored_speed_x) or player.speed_x == 0) then
            player.dump_stored_speed_x = true
        elseif(sign(player.speed_x) ~= sign(player.stored_speed_x) and abs(player.speed_x) > 1) then
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
                sfx(0, -1, 18, 2)
            elseif (abs_speed >= (stored_energy_limit / 3) and abs_speed < ((stored_energy_limit / 3) * 2)) then
                sfx(0, -1, 18, 5)
            elseif (abs_speed >= ((stored_energy_limit / 3) * 2)) then
                sfx(0, -1, 18, 10)
            end
        end
    end

    if (player.speed_x > 0 or player.speed_x < 0) then
        player.dx = player.dx + player.speed_x
    end

    set_ball_sprite_index()

    local collision_result = check_map_collision_x(player, terrain_flag, resolution)

    if (collision_result.collision == true) then
        player.colliding_x = true
        if (collision_result.last_non_collision_x ~= nil) then
            player.x = collision_result.last_non_collision_x
        else
            player.x = collision_result.collision_x
        end

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
        player.dx = player.x
        player.speed_x = 0
    else
        player.colliding_x = false
        player.x = player.dx
    end

end

function apply_friction(player)
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

    player.speed_y = player.speed_y + gravity

    if (player.speed_y > vertical_add_energy_limit) then
        player.speed_y = vertical_add_energy_limit
    end
end

function _update()
    update_framecount()
    get_user_input(player)
    move_x(player)
    move_y(player)
    apply_friction(player)
end

function _draw()
    cls()
    draw_map()
    if (player.debounce) then
        pal(8, 9)
    else
        pal()
    end
    spr(player.ball_sprite_index, player.x, player.y, 1, 1, player.ball_sprite_flip_x, player.ball_sprite_flip_y)
end

function draw_map()
    if (player.x < 128) then
        camera_offset_x = 0
    elseif (player.x >= 128 and player.x < 164) then
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
    end
    
    log('back:'..camera_x_back_boundry..' front:'..camera_x_front_boundry)
    if(camera_x_front_boundry < 212) then
        camera_x_front_boundry = 212
    end
    if(camera_x_back_boundry < 0) then
        camera_x_front_boundry = 0
    end
    
    camera(camera_offset_x, 0)
    map()
end

