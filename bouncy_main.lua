-- pico8_import utilities.lua
function _init()
    log('bouncy init called')
    terrain_flag = 0x2
    bubble_power_enabled = false
    hazard_flag = 0x4
    top_only_hazard_flag = 0x8
    sloped_terrain_l_flag = 0x10
    sloped_terrain_r_flag = 0x20
    top_only_collision_flag = 0x40
    last_slope_flag_used = sloped_terrain_l_flag
    current_checkpoint = 2
    rolling_ball_index_count = 1
    checkpoint_locations = {{136, 24}, {345, 16}}
    checkpoint_sprites = {73, 74}
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
    ground_friction = 0.3
    air_friction = 0.2
    gravity = 0.3
    relativity_gravity = 0.1
    resolution = 0.1
    camera_x_front_boundry = 212
    camera_x_back_boundry = 0
    hazard_hit_animation = 0
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
        debounce = false
    }
    player = shallow_copy(player_defaults)

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
    if btn(2) and bubble_power_enabled then
        player.speed_y = player.speed_y - (gravity + resolution)
        if (player.speed_y <= (vertical_add_energy_limit * -1)) then
            player.speed_y = vertical_add_energy_limit * -1
        end
    end
    if btn(4) then
        player.debounce = true
    else
        player.debounce = false
    end
    if btn(5) then
        player.hazard_hit = true
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

function reset_player()
    pal()
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
    cls()
    draw_map()

    update_framecount()
    if (player.hazard_hit) then
        hazard_hit_animation = hazard_hit_animation + 1
        if (hazard_hit_animation > 30) then
            reset_player()
        end
    else
        get_user_input(player)
        move_x(player)
        move_y(player)
        non_physical_collisions()
        apply_friction(player)
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
    
    
    if (player.hazard_hit == false) then
        if (player.debounce) then
            pal(8, 9)
        elseif btn(2) and bubble_power_enabled then
            pal(8, 12)
        else
            pal()
        end
    end
    draw_checkpoints()
    spr(player.ball_sprite_index, player.x, player.y, 1, 1, player.ball_sprite_flip_x, player.ball_sprite_flip_y)

    if (player.hazard_hit) then
        process_hazard_hit_animation()
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
    if (player.x < 127) then
        camera_offset_x = 0
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
    end

    -- log('back:' .. camera_x_back_boundry .. ' front:' .. camera_x_front_boundry)
    if (camera_x_front_boundry < 212) then
        camera_x_front_boundry = 212
    end
    if (camera_x_back_boundry < 0) then
        camera_x_front_boundry = 0
    end

    camera(camera_offset_x, 0)
    map()
end

