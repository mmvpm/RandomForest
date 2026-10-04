/// Selects the current skin's matching sprite without changing collision geometry.
function funPlayerSkinSprite(light_sprite) {
    if (!self.is_dark) return light_sprite
    switch (light_sprite) {
        case sPlayerIdle: return sPlayerDarkIdle
        case sPlayerBlink: return sPlayerDarkBlink
        case sPlayerWondering: return sPlayerDarkWondering
        case sPlayerMove: return sPlayerDarkMove
        case sPlayerJump: return sPlayerDarkJump
        case sPlayerFall: return sPlayerDarkFall
        case sPlayerAttack1: return sPlayerDarkAttack1
        case sPlayerAttack2: return sPlayerDarkAttack2
        case sPlayerAttack3: return sPlayerDarkAttack3
        case sPlayerHurt: return sPlayerDarkHurt
        case sPlayerDie: return sPlayerDarkDie
    }
    return light_sprite
}

/// Applies newly awarded abilities without healing the current room.
function funPlayerRefreshAbilities() {
    var abilities = funCampaignAbilities()
    self.max_health = abilities.max_health
    self.health = clamp(self.health, 0, self.max_health)
    self.double_jump_unlocked = abilities.double_jump
    self.melee_bonus = abilities.melee_bonus
    self.stomp_unlocked = abilities.stomp
    self.stomp_radius = abilities.stomp_radius
}

/// Returns whether this request uses the one remaining airborne jump.
function funPlayerJumpIsAirborne() {
    return self.coyote_buffer_counter == 0 and !self.is_on_ground
}

/// Consumes a fresh buffered jump and its airborne allowance exactly once.
function funPlayerConsumeJump() {
    if (funPlayerJumpIsAirborne()) self.air_jump_available = false
    self.jump_buffer_counter = 0
    self.coyote_buffer_counter = 0
}
