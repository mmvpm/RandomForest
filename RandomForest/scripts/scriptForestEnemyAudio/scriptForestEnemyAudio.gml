/// Plays the final selected cue once at the committed attack, never during flight or footsteps.
function funForestEnemyPlayAttackSound() {
    if (!funDefaultIsInView0()) return;
    var sound=noone
    switch (self.forest_kind) {
        case "slime": sound=soundResinSlimeAttack; break
        case "bat": sound=soundForestBatAttack; break
        case "maw": sound=soundRootMawBite; break
        case "guard": sound=self.attack_style=="Attack1" ? soundBarkGuardShot : soundBarkGuardImpact; break
        case "sweeper": sound=self.attack_style=="AttackSlam" ? soundRootReaperSlam : soundRootReaperSweep; break
    }
    // The bomber's sole cue belongs to its projectile's detonation.
    if (sound!=noone) audio_play_sound(sound,1,false)
}

/// Plays the selected soft explosion at the actual seed detonation.
function funForestSeedPlayBurstSound() {
    if (!funDefaultIsInView0()) return;
    audio_play_sound(soundBarkBomberBurst,1,false)
}

/// Adds the optional wake cue only on the bat's first engagement, without a wingbeat loop.
function funForestEnemyPlayWakeSound() {
    if (self.forest_kind!="bat" or self.wake_sound_played or !funDefaultIsInView0()) return;
    self.wake_sound_played=true
    audio_play_sound(soundForestBatWake,1,false)
}

/// Uses one landing cue for both the authored floor hop and a real navigation landing.
function funForestEnemyPlayLandingSound() {
    if (funDefaultIsInView0()) audio_play_sound(soundResinSlimeLand,1,false)
}
