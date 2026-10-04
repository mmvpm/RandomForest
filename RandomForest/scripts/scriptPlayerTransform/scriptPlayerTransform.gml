/// Starts a controller-requested, one-shot skin change from stable ground.
function funPlayerBeginStoryTransform(target_dark, on_complete, on_cancel = undefined) {
    if (!self.is_on_ground or self.state == player_states.stomp
        or self.state == player_states.story_transform or self.state == player_states.teleport
        or self.state == player_states.hurt or self.state == player_states.die
        or self.state == player_states.attack) return false
    self.transform_target_dark = target_dark
    self.transform_complete = on_complete
    self.transform_cancel = on_cancel
    funPlayerChangeState(player_states.story_transform)
    return true
}

/// Begins an anchored transformation whose frames contain the jump themselves.
function funPlayerTransformStart() {
    self.current_xspeed = 0
    self.current_yspeed = 0
    self.jump_buffer_counter = 0
    self.fall_buffer_counter = 0
    self.transform_progress = 0
    self.transform_impact_created = false
    self.transform_ground_y = self.y
    self.transform_rectangles = [[10, 50, 18, 64], [11, 52, 17, 64], [11, 55, 17, 64], [10, 57, 18, 64], [9, 57, 18, 64], [9, 57, 17, 64], [9, 57, 17, 64], [10, 57, 17, 64], [10, 57, 17, 64], [10, 57, 17, 64], [10, 56, 18, 64], [11, 41, 16, 64], [7, 22, 16, 34], [6, 15, 12, 28], [6, 11, 13, 24], [6, 10, 14, 22], [6, 10, 15, 21], [6, 10, 15, 20], [6, 10, 15, 20], [6, 10, 15, 20], [6, 11, 15, 20], [6, 13, 16, 20], [7, 15, 17, 26], [9, 17, 16, 36], [10, 45, 16, 64], [10, 58, 17, 64], [9, 59, 18, 64], [9, 58, 17, 64], [9, 57, 17, 64], [10, 57, 17, 64], [10, 57, 17, 64], [10, 56, 17, 64], [10, 54, 18, 64], [10, 52, 18, 64], [10, 50, 18, 64], [10, 49, 18, 64], [10, 49, 18, 64], [10, 49, 18, 64]]
    self.image_speed = 0
    self.image_index = 0
    self.mask_index = sPlayerTransformMask
    if (self.state == player_states.stomp) {
        self.sprite_index = self.is_dark ? sPlayerDarkStomp : sPlayerLightStomp
        self.transform_complete = undefined
        self.transform_cancel = undefined
    } else {
        self.sprite_index = self.transform_target_dark ? sPlayerLightTransform : sPlayerDarkTransform
    }
    funPlayerStartTransformFx()
}

/// Converts the authored frame's body rectangle into world pixel coordinates.
function funPlayerTransformBodyBounds(frame) {
    var rect = self.transform_rectangles[frame]
    var x1 = self.x + (rect[0] - 12) * self.image_xscale
    var x2 = self.x + (rect[2] - 12) * self.image_xscale
    return [min(x1, x2), self.y + (rect[1] - 65) * self.image_yscale,
        max(x1, x2), self.y + (rect[3] - 65) * self.image_yscale]
}

/// Sweeps every moving body edge in one-pixel steps through solid geometry.
function funPlayerTransformBlocked(old_rect, new_rect) {
    var steps = 1
    for (var edge = 0; edge < 4; ++edge) steps = max(steps, ceil(abs(new_rect[edge] - old_rect[edge])))
    var solids = ds_list_create()
    var count = collision_rectangle_list(min(old_rect[0], new_rect[0]), min(old_rect[1], new_rect[1]),
        max(old_rect[2], new_rect[2]), max(old_rect[3], new_rect[3]), oSolid, false, true, solids, false)
    var blocked = false
    for (var step_index = 1; step_index <= steps; ++step_index) {
        var rect = array_create(4)
        for (var edge = 0; edge < 4; ++edge) rect[edge] = round(lerp(old_rect[edge], new_rect[edge], step_index / steps))
        for (var i = 0; i < count; ++i) {
            var obstacle = solids[| i]
            if (rect[2] < obstacle.bbox_left or rect[0] > obstacle.bbox_right
                or rect[3] < obstacle.bbox_top or rect[1] > obstacle.bbox_bottom) continue
            if (obstacle.object_index == oJumpThru) {
                if (new_rect[3] > old_rect[3] and old_rect[3] < obstacle.bbox_top
                    and rect[3] >= obstacle.bbox_top) blocked = true
            } else if (obstacle.is_solid) {
                blocked = true
            }
            if (blocked) break
        }
        if (blocked) break
    }
    ds_list_destroy(solids)
    return blocked
}

/// Restores ordinary movement at the body position of the last safe frame.
function funPlayerTransformAbort() {
    funPlayerStopTransformFx()
    var body_rect = funPlayerTransformBodyBounds(floor(self.image_index))
    var body_bottom = body_rect[3]
    var cancel = self.transform_cancel
    self.y = body_bottom + 1
    self.mask_index = -1
    self.image_speed = 1
    self.sprite_index = funPlayerSkinSprite(sPlayerFall)
    self.image_index = 0
    // A crouched airborne body grows into the ordinary fall mask on cancellation.
    // Resolve only overhead overlap, one pixel downward, never below the original floor.
    while (self.y < self.transform_ground_y and funPlayerCollideWithSolid(self.x, self.y)) {
        self.y += 1
    }
    self.current_yspeed = 0
    self.jump_buffer_counter = 0
    self.transform_complete = undefined
    self.transform_cancel = undefined
    funPlayerChangeState(player_states.fall)
    if (cancel != undefined) cancel()
}

/// Advances checked body frames, emits one impact, then releases player control.
function funPlayerTransformLogic() {
    var previous_frame = floor(self.image_index)
    var old_rect = funPlayerTransformBodyBounds(previous_frame)
    self.transform_progress += sprite_get_speed(self.sprite_index) / game_get_speed(gamespeed_fps)
    self.image_index = min(37, floor(self.transform_progress))
    if (funPlayerTransformBlocked(old_rect, funPlayerTransformBodyBounds(floor(self.image_index)))) {
        self.image_index = previous_frame
        funPlayerTransformAbort()
        return
    }

    // Damage remains interruptible, but other combat inputs cannot replace this state.
    var critical = funPlayerDetectCriticalState()
    if (critical == player_states.hurt) {
        funPlayerTransformAbort()
        funPlayerChangeState(player_states.hurt)
        return
    }

    if (self.state == player_states.stomp and self.image_index >= 24 and !self.transform_impact_created) {
        self.transform_impact_created = true
        self.stomp_cooldown_counter = round(global.campaign_abilities_config.stomp_cooldown_seconds * game_get_speed(gamespeed_fps))
        var wave = instance_create_depth(self.x, self.transform_ground_y, self.depth - 1, oPlayerStompWave)
        wave.max_radius = self.stomp_radius
        audio_play_sound(soundPlayerLanding, 1, false)
        funCameraShake(8)
    }

    if (self.transform_progress >= 38) {
        funPlayerStopTransformFx()
        var complete = self.transform_complete
        if (self.state == player_states.story_transform) self.is_dark = self.transform_target_dark
        self.mask_index = -1
        self.image_speed = 1
        self.image_index = 0
        self.current_yspeed = 0
        self.sprite_index = funPlayerSkinSprite(sPlayerIdle)
        self.transform_complete = undefined
        self.transform_cancel = undefined
        funPlayerChangeState(player_states.idle)
        if (complete != undefined) complete()
    }
}
