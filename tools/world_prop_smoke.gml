/// Initializes a save-free fixture covering authored groups and all lighting variants.
function funThemeSmokeCreate() {
    self.stage = 0
    self.frames = 0
    self.theme_index = 0
    self.pending_shot = ""
    global.current_level = 10
    global.is_training_completed = true
}

/// Builds one small generated room without adding production levels or catalog entries.
function __funPropSmokeOpen() {
    var rows = array_create(30, string_repeat(".", 60))
    rows[27] = string_repeat(".", 12) + "@" + string_repeat(".", 47)
    rows[25] = string_repeat(".", 50) + "O" + string_repeat(".", 9)
    rows[28] = string_repeat("#", 60)
    rows[29] = string_repeat("X", 60)
    var cells = []
    for (var column = -9; column <= 3; ++column) array_push(cells, [column, -5])
    var data = {width:60, height:30, map:rows, style:{profile:"forest",seed:17,grass_chance:0},
        star_times:{three_stars:60,two_stars:120}, props:[
            {id:"table",type:"morning_table",x:180,y:336,mirrored:false,solids:cells},
            {id:"bridge",type:"two_route_bridge",x:444,y:336,mirrored:true,solids:[[0,-1],[1,-1]],opacity:50,platform_layer:"below"},
            {id:"house",type:"window_hut",x:636,y:336,mirrored:false,solids:[],opacity:0,platform_layer:"above"},
            {id:"jump_table",type:"morning_table",x:336,y:336,mirrored:true,solids:[],jump_thrus:cells}
        ]}
    global.playing_level = 10 + self.theme_index * 10
    global.generated_level_data = funDecodeGeneratedLevelMap(data)
    var validation = funValidateGeneratedLevel(global.generated_level_data)
    if (!validation.is_valid) show_error(validation.error, true)
    global.playing_level_star_times = data.star_times
    room_goto(rGeneratedLevel)
}

/// Exercises real solid collisions, restart stability and native theme selection.
function funThemeSmokeStep() {
    self.frames++
    if (self.frames < 10) return
    if (self.stage == 0) {
        __funPropSmokeOpen()
        self.stage = 1
        self.frames = 0
        return
    }
    if (room != rGeneratedLevel) return
    if (self.stage == 1) {
        if (instance_number(oWorldProp) != 4) show_error("Prop instances were lost.", true)
        if (instance_number(oJumpThru) != 1 || oJumpThru.x != 312 || oJumpThru.y != 306 || oJumpThru.bbox_right - oJumpThru.bbox_left + 1 != 78) show_error("Prop jump-through run was not reflected and merged correctly.", true)
        if (layer_get_depth(layer_get_id("WorldProps")) != 350) show_error("Incorrect prop layer.", true)
        if (layer_get_depth(layer_get_id("WorldPropsBehind")) != 450) show_error("Incorrect prop layer behind platforms.", true)
        with (oWorldProp) {
            if (x == 180 && (image_alpha != 1 || depth != 350)) show_error("Legacy prop appearance changed.", true)
            if (x == 444 && (image_alpha != 0.5 || depth != 450)) show_error("Prop appearance was not applied.", true)
            if (x == 636 && (image_alpha != 0 || depth != 350)) show_error("Zero opacity was not applied.", true)
        }
        if (!position_meeting(180, 306, oSolid)) show_error("Prop floor was not built.", true)
        if (!position_meeting(433, 330, oSolid) || position_meeting(445, 330, oSolid)) show_error("Mirrored collision is incorrect.", true)
        if (position_meeting(636, 200, oSolid)) show_error("Background art unexpectedly collides.", true)
        var definition = funWorldPropDefinition("morning_table")
        var day_sprite = asset_get_index(definition.variants.day.sprite)
        var theme = funCurrentLevelTheme()
        if (funThemeSprite(day_sprite, theme) != asset_get_index(variable_struct_get(definition.variants, theme).sprite)) show_error("Wrong prop palette.", true)
        oPlayer.x = 180
        oPlayer.y = 306
        oPlayer.current_xspeed = 0
        oPlayer.current_yspeed = 0
        self.stage = 2
        self.frames = 0
        return
    }
    if (self.stage == 2 && self.frames >= 35) {
        if (abs(oPlayer.y - 306) > 1) show_error("Player fell through the prop floor.", true)
        self.pending_shot = "props-" + funCurrentLevelTheme()
        surface_save(application_surface, self.output_directory + self.pending_shot + ".png")
        show_debug_message("PROP_SURFACE_SAVED " + string(file_exists(self.output_directory + self.pending_shot + ".png")))
        with (oPlayer) funPlayerChangeState(player_states.prejump)
        instance_create_layer(144, 282, "Instances", oPlayerTapSword, {
            current_angle:270, image_angle:270, shift_of_player_y:10
        })
        self.stage = 3
        self.frames = 0
        return
    }
    if (self.stage == 3) {
        if (self.frames == 10) {
            if (oPlayer.y >= 306) show_error("Player could not jump from the prop.", true)
            if (!instance_exists(oPlayerTapSword) || oPlayerTapSword.current_speed != 0) show_error("Sword did not stop on the prop.", true)
            with (oPlayer) {
                if (!funPlayerTapToEmptyPlace() || funPlayerCollideWithSolid(x, y)) show_error("Teleport entered the prop solid.", true)
                funPlayerTapSwordDestroy(false)
            }
        }
        if (self.frames < 45) return
        if (abs(oPlayer.y - 306) > 1) show_error("Player did not land back on the prop.", true)
        room_restart()
        self.stage = 4
        self.frames = 0
        return
    }
    if (self.stage == 4) {
        if (instance_number(oWorldProp) != 4 || instance_number(oJumpThru) != 1 || !position_meeting(180, 306, oSolid)) show_error("Restart changed prop groups.", true)
        oPlayer.x = 336
        oPlayer.y = 336
        oPlayer.current_xspeed = 0
        oPlayer.current_yspeed = 0
        with (oPlayer) funPlayerChangeState(player_states.prejump)
        self.stage = 5
        self.frames = 0
        return
    }
    if (self.stage == 5) {
        if (self.frames == 10 && oPlayer.y >= 306) show_error("Prop jump-through blocked a jump from below.", true)
        if (self.frames < 45) return
        if (abs(oPlayer.y - 306) > 1) show_error("Player did not land on the prop jump-through.", true)
        // The Down input uses this exact buffer; exercise the existing one-way logic.
        oPlayer.fall_buffer_counter = oPlayer.fall_buffer_max + 1
        self.stage = 6
        self.frames = 0
        return
    }
    if (self.stage == 6) {
        if (self.frames < 20) return
        if (abs(oPlayer.y - 336) > 1) show_error("Player could not drop through the prop jump-through.", true)
        self.theme_index++
        if (self.theme_index == 4) {
            show_debug_message("WORLD_PROP_SMOKE_PASS: palettes, platform layers, opacity/defaults, solid and jump-through runs, jump from below, landing, drop-through, sword, teleport, restart")
            game_end()
            return
        }
        self.stage = 0
        self.frames = 0
    }
}

/// Saves fully rendered scenes without interacting with the user's desktop.
function funThemeSmokeDraw() {
    if (self.pending_shot == "") return
    screen_save(self.output_directory + self.pending_shot + ".png")
    self.pending_shot = ""
}
