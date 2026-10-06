/// Returns the full text's actual ink bounds, including its one-pixel outline.
function funWallMemoryBounds(anchor) {
    var ink = anchor.ink_bounds
    return [anchor.memory_left + ink[0], anchor.memory_top + ink[1],
        anchor.memory_left + ink[2], anchor.memory_top + ink[3]]
}

/// Protects screen edges and the top-left health/coin HUD before activation.
function funWallMemoryInsideView(bounds, view_x, view_y, view_width, view_height) {
    if (bounds[0] < view_x + 4 or bounds[1] < view_y + 4
        or bounds[2] > view_x + view_width - 4 or bounds[3] > view_y + view_height - 4) return false
    return bounds[0] >= view_x + 110 or bounds[1] >= view_y + 48
}

/// Uses the authored centre, independently of text width and typing progress.
function funWallMemoryDistance(anchor, player_x, player_y) {
    return point_distance(player_x, player_y, anchor.x, anchor.y)
}

/// Records the last letter once while retaining the current reading window.
function funWallMemoryFinishTyping(anchor) {
    anchor.phase = "hold"
    anchor.phase_elapsed = 0
    funWallMemoryMarkRead(anchor.read_key)
}

/// Starts one typewriter reveal and its quiet memory cue.
function funWallMemoryStart(anchor) {
    anchor.phase = "typing"
    anchor.phase_elapsed = 0
    anchor.revealed = min(1, anchor.glyph_count)
    audio_play_sound(soundWallMemoryReveal, 0, false)
    if (anchor.revealed >= anchor.glyph_count) funWallMemoryFinishTyping(anchor)
}

/// Completes typing offscreen; fading is allowed only after the reading window.
function funWallMemoryAdvance(anchor, seconds, inside_view, distance) {
    var settings = global.wall_memory_config.defaults
    if (anchor.phase == "typing") {
        anchor.revealed = min(anchor.glyph_count, anchor.revealed + settings.characters_per_second * seconds)
        if (anchor.revealed >= anchor.glyph_count) funWallMemoryFinishTyping(anchor)
        return;
    }
    anchor.phase_elapsed += seconds
    if (anchor.phase == "hold" and anchor.phase_elapsed >= settings.hold_seconds
        and (!inside_view or distance > settings.leave_distance)) {
        anchor.phase = "fade"
        anchor.phase_elapsed = 0
    }
    if (anchor.phase == "fade" and anchor.phase_elapsed >= settings.fade_seconds) {
        anchor.phase = "consumed"
        anchor.phase_elapsed = 0
    }
}

/// Gates spawn-adjacent memories behind the first voluntary movement action.
function funWallMemoryMovementStarted(controller) {
    if (controller.movement_started) return true
    if (!instance_exists(oTimeCounter) or !oTimeCounter.may_count) return false
    controller.movement_started = keyboard_check(global.key_move_left)
        or keyboard_check(global.key_move_right) or keyboard_check(global.key_jump)
        or keyboard_check(global.key_fall)
    return controller.movement_started
}

/// Activates the nearest unread place while preserving simultaneous text limits.
function funWallMemoryUpdateController(controller) {
    if (!controller.ready) funWallMemoryAssignAnchors(controller)
    if (!instance_exists(oPlayer)) return;
    if (oPlayer.health <= 0 or oPlayer.state == player_states.die) return;
    if (!funWallMemoryMovementStarted(controller)) return;
    var cam = view_camera[0]
    var view_x = camera_get_view_x(cam), view_y = camera_get_view_y(cam)
    var view_width = camera_get_view_width(cam), view_height = camera_get_view_height(cam)
    var candidates = [], active = 0
    var settings = global.wall_memory_config.defaults
    var seconds = 1 / game_get_speed(gamespeed_fps)
    for (var i = 0; i < array_length(controller.anchors); ++i) {
        var anchor = controller.anchors[i]
        if (!instance_exists(anchor) or !anchor.ready or anchor.phase == "consumed") continue
        var inside_view = funWallMemoryInsideView(funWallMemoryBounds(anchor), view_x, view_y, view_width, view_height)
        var distance = funWallMemoryDistance(anchor, oPlayer.x, oPlayer.y - 8)
        if (anchor.phase != "idle") funWallMemoryAdvance(anchor, seconds, inside_view, distance)
        if (anchor.phase != "idle" and anchor.phase != "consumed") active += 1
        else if (anchor.phase == "idle" and !funWallMemoryWasRead(anchor.read_key)
            and inside_view and distance <= settings.activation_distance) {
            array_push(candidates, {anchor: anchor, distance: distance})
        }
    }
    array_sort(candidates, function(a, b) {
        if (a.distance != b.distance) return a.distance < b.distance ? -1 : 1
        return a.anchor.anchor_id < b.anchor.anchor_id ? -1 : 1
    })
    var limit = controller.level_number == 1 ? 2 : (controller.level_number == 41 ? 3 : 1)
    var special_active = 0
    for (var i = 0; i < array_length(controller.anchors); ++i) {
        var anchor = controller.anchors[i]
        if (anchor.role == "missing_previous" and anchor.phase != "idle"
            and anchor.phase != "consumed") special_active += 1
    }
    for (var i = 0; i < array_length(candidates); ++i) {
        if (active >= limit) break
        var anchor = candidates[i].anchor
        if (anchor.role == "missing_previous" and special_active >= 1) continue
        if (anchor.role == "missing_previous") special_active += 1
        funWallMemoryStart(anchor)
        active += 1
    }
}
