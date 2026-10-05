/// Returns actual visible world pixels, including the brief nighttime echoes.
function funWallMemoryBounds(anchor) {
    var echo_pad = anchor.theme == "night" ? 2 : 0
    var ink = anchor.ink_bounds
    return [anchor.memory_left + ink[0] - echo_pad, anchor.memory_top + ink[1] - echo_pad,
        anchor.memory_left + ink[2] + echo_pad, anchor.memory_top + ink[3] + echo_pad]
}

/// Allows ceiling walls while protecting screen edges and the top-left health/coin HUD.
function funWallMemoryInsideView(bounds, view_x, view_y, view_width, view_height) {
    if (bounds[0] < view_x + 4 or bounds[1] < view_y + 4
        or bounds[2] > view_x + view_width - 4 or bounds[3] > view_y + view_height - 4) return false
    return bounds[0] >= view_x + 110 or bounds[1] >= view_y + 48
}

/// Measures proximity to the readable box's center rather than its alignment edge.
function funWallMemoryDistance(anchor, player_x, player_y) {
    return point_distance(player_x, player_y, anchor.memory_left + anchor.surface_width / 2,
        anchor.memory_top + anchor.surface_height / 2)
}

/// Updates one active memory using minimum reading time and distance hysteresis.
function funWallMemoryAdvance(anchor, seconds, inside_view, distance) {
    var settings = global.wall_memory_config.defaults
    anchor.phase_elapsed += seconds
    if (anchor.phase == "appear" and anchor.phase_elapsed >= settings.appear_seconds) {
        anchor.phase = "hold"
        anchor.phase_elapsed = 0
    }
    if ((anchor.phase == "hold" or anchor.phase == "appear")
        and (!inside_view or (distance > settings.leave_distance
            and anchor.phase == "hold" and anchor.phase_elapsed >= settings.hold_seconds))) {
        anchor.phase = "fade"
        anchor.phase_elapsed = 0
    }
    if (anchor.phase == "fade" and anchor.phase_elapsed >= settings.fade_seconds) {
        anchor.phase = "idle"
        anchor.phase_elapsed = 0
    }
}

/// Chooses nearest eligible anchors while counting fading text against visible limits.
function funWallMemoryUpdateController(controller) {
    if (!controller.ready) funWallMemoryAssignAnchors(controller)
    if (!instance_exists(oPlayer)) return;
    var cam = view_camera[0]
    var view_x = camera_get_view_x(cam), view_y = camera_get_view_y(cam)
    var view_width = camera_get_view_width(cam), view_height = camera_get_view_height(cam)
    var candidates = []
    var ordinary_active = 0, special_active = 0
    var settings = global.wall_memory_config.defaults
    var seconds = 1 / game_get_speed(gamespeed_fps)
    for (var i = 0; i < array_length(controller.anchors); ++i) {
        var anchor = controller.anchors[i]
        if (!instance_exists(anchor) or !anchor.ready) continue
        var bounds = funWallMemoryBounds(anchor)
        var inside_view = funWallMemoryInsideView(bounds, view_x, view_y, view_width, view_height)
        var distance = funWallMemoryDistance(anchor, oPlayer.x, oPlayer.y - 8)
        if (anchor.phase != "idle") funWallMemoryAdvance(anchor, seconds, inside_view, distance)
        if (anchor.phase != "idle") {
            if (anchor.role == "missing_previous") special_active += 1
            else ordinary_active += 1
        } else if (inside_view and distance <= settings.activation_distance) {
            array_push(candidates, {anchor: anchor, distance: distance})
        }
    }
    array_sort(candidates, function(a, b) {
        if (a.distance != b.distance) return a.distance < b.distance ? -1 : 1
        return a.anchor.anchor_id < b.anchor.anchor_id ? -1 : 1
    })
    var ordinary_limit = controller.level_number == 1 ? 2 : (controller.level_number == 41 ? 3 : 1)
    var total_limit = ordinary_limit
    for (var i = 0; i < array_length(candidates); ++i) {
        var anchor = candidates[i].anchor
        if (ordinary_active + special_active >= total_limit) break
        if (anchor.role == "missing_previous") {
            if (special_active >= 1) continue
            special_active += 1
        } else {
            if (ordinary_active >= ordinary_limit) continue
            ordinary_active += 1
        }
        anchor.first_reveal = !anchor.seen
        anchor.seen = true
        anchor.phase = "appear"
        anchor.phase_elapsed = 0
    }
}
