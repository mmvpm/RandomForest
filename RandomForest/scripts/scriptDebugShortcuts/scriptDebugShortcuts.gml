/// Shortens only the current weather period, preserving an already closer transition.
function funDebugSkipWeather() {
    if (!global.is_debug or !instance_exists(oAmbientSystem)) return;
    var weather = oAmbientSystem.weather
    weather.remaining = min(weather.remaining, 5)
}

/// Collects remaining berries once, including those already flying towards the HUD.
function funDebugCollectBerries() {
    if (!global.is_debug or !instance_exists(oCoinCollector)) return;
    oCoinCollector.coins_collected += instance_number(oCoin)
    instance_destroy(oCoin)
}

/// Checks the player's destination against collisions and non-solid black platform fill.
function funDebugDoorSpotFree(xx, yy) {
    var x0 = xx + self.bbox_left - self.x, x1 = xx + self.bbox_right - self.x
    var y0 = yy + self.bbox_top - self.y, y1 = yy + self.bbox_bottom - self.y
    if (x0 < 0 or y0 < 0 or x1 >= room_width or y1 >= room_height) return false
    if (place_meeting(xx, yy, oSolid) or place_meeting(xx, yy, oDoor)
        or place_meeting(xx, yy, oEnemy)) return false
    if (collision_rectangle(x0, y0, x1, y1 + 12, oTrap, false, true) != noone) return false
    if (instance_exists(oAmbientSystem)) {
        var terrain = oAmbientSystem
        for (var row = floor(y0 / 12); row <= floor(y1 / 12); ++row) {
            for (var column = floor(x0 / 12); column <= floor(x1 / 12); ++column) {
                if (terrain.tiles[row * terrain.grid_width + column] != 0) return false
            }
        }
    }
    return true
}

/// Moves a player to free air two to three tiles from the door, preferring nearby support.
function funDebugMoveNearDoor(door) {
    if (!global.is_debug) return false
    var old_sprite = self.sprite_index, old_frame = self.image_index
    self.sprite_index = funPlayerSkinSprite(sPlayerIdle)
    for (var pass = 0; pass < 2; ++pass) {
        for (var radius = 24; radius <= 36; radius += 6) {
            for (var angle = 180; angle < 540; angle += 15) {
                var xx = door.x + round(lengthdir_x(radius, angle))
                var yy = door.y + round(lengthdir_y(radius, angle))
                if (!funDebugDoorSpotFree(xx, yy)) continue
                if (pass == 0 and !place_meeting(xx, yy + 13, oSolid)) continue
                self.x = xx; self.y = yy
                self.current_xspeed = 0; self.current_yspeed = 0
                self.jump_buffer_counter = 0; self.fall_buffer_counter = 0
                self.image_index = 0; self.image_alpha = 1
                funPlayerChangeState(player_states.idle)
                return true
            }
        }
    }
    self.sprite_index = old_sprite; self.image_index = old_frame
    return false
}

/// Runs the exit shortcut only in an active debug level, without completing it automatically.
function funDebugFinishLevel() {
    if (!global.is_debug or !instance_exists(oPlayer) or !instance_exists(oDoor)) return;
    funDebugCollectBerries()
    var door = instance_find(oDoor, 0)
    with (oPlayer) funDebugMoveNearDoor(door)
}
