/// Consumes a wave hit and adds a short, collision-aware push to the hurt movement.
function funEnemyStompKnockbackStart() {
    self.stomp_knockback_counter = 0
    if (self.stomp_knockback_direction == 0) return;
    self.stomp_knockback_counter = ceil(0.2 * game_get_speed(gamespeed_fps))
    self.current_xspeed = self.stomp_knockback_direction * 90 / game_get_speed(gamespeed_fps)
    self.stomp_knockback_direction = 0
}

/// Stops the stomp push after about 18 game pixels without changing ordinary hurt.
function funEnemyStompKnockbackUpdate() {
    if (self.stomp_knockback_counter <= 0) return;
    self.stomp_knockback_counter -= 1
    if (self.stomp_knockback_counter == 0) self.current_xspeed = 0
}
