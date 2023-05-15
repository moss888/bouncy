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

