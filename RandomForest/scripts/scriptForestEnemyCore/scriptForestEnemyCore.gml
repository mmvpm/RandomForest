/// Initializes the six new actors without altering the established enemy families.
function funForestEnemyInitialize(kind) {
    if (kind=="guard" or kind=="sweeper") { self.image_xscale*=1.5;self.image_yscale*=1.5 }
    self.forest_kind=kind
    self.state="idle"
    self.state_timer=0
    self.animation_finished=false
    self.attack_spawned=false
    self.attack_style="Attack"
    self.damage=1
    self.can_damage_player=true
    self.is_dead=false
    self.counts_as_enemy=true
    self.health=4
    self.vision_radius=180
    self.rear_vision_radius=100
    self.vertical_vision_radius=60
    self.current_direction=sign(self.image_xscale)
    if (self.current_direction==0) self.current_direction=1
    self.step_xspeed=.7
    self.current_xspeed=0
    self.current_yspeed=0
    self.gravitation=.35
    self.hurt_countdown_counter=0
    self.future_damage=0
    self.attack_cooldown=20
    self.home_x=self.x
    self.home_y=self.y
    self.ambient_clock=0
    self.attack_target_x=self.x
    self.attack_target_y=self.y
    self.attack_serial=0
    self.attack_elapsed=0
    self.glow_id=noone
    self.wake_sound_played=false
    self.was_airborne=false
    self.landed=false
    self.hop_phase="none"
    self.hop_clock=0
    self.turn_cooldown=0
    self.alert_timer=0
    self.patrol_timer=360
    self.bite_cancelled=false
    self.dive_left=0
    self.has_awoken=false
    self.returning_home=false
    self.retreat_required=false
    self.retreat_start_x=self.x
    self.retreat_start_y=self.y
    self.retreat_target_x=self.x
    self.retreat_target_y=self.y
    if (!variable_instance_exists(self,"visual_theme")) self.visual_theme=funCurrentLevelTheme()
    switch (kind) {
        case "slime": self.art_prefix="sResinSlime";self.step_xspeed=.75;self.vision_radius=360;self.rear_vision_radius=200;break
        case "barrel": self.art_prefix="sBarkBomber";self.health=5;self.step_xspeed=.55;self.vision_radius=220;self.visual_theme="night";break
        case "guard": self.art_prefix="sBarkGuard";self.health=7;self.step_xspeed=.6;self.vision_radius=430;break
        case "sweeper": self.art_prefix="sRootReaper";self.health=6;self.step_xspeed=.75;self.visual_theme="night";break
        case "bat": self.art_prefix="sForestBat";self.health=3;self.vertical_vision_radius=160;self.vision_radius=210;self.rear_vision_radius=210;self.visual_theme="night";break
        case "maw": self.art_prefix="sRootMaw";self.health=5;self.step_xspeed=0;self.vision_radius=96;self.vertical_vision_radius=48;self.visual_theme="night";break
    }
    if (kind=="maw") self.maw_skin=funRootMawStartLevel(global.playing_level)
    self.max_health=self.health
    funEnemyInitializeMovement(asset_get_index(self.art_prefix+"Collision"))
    funForestEnemyState("idle")
    if (kind=="bat") funForestBatFindCeiling()
    funForestEnemyCreateGlow()
}

/// Keeps alert reapers awake and uses the existing native animations for each state.
function funForestEnemyAnimation(state) {
    if (state=="dead") return self.forest_kind=="maw" ? "Die" : "Death"
    if (state=="hurt" or state=="fall_dead") return "Hurt"
    if (state=="hang") return "Idle"
    if (state=="wake" or state=="drop") return "Wake"
    if (state=="sleep") return "Idle"
    if (state=="windup") return self.forest_kind=="maw" ? "Prepare" : self.attack_style
    if (state=="attack") return self.attack_style
    if (state=="recover" and self.forest_kind=="maw") return "Recover"
    if (self.forest_kind=="bat") return "Fly"
    if (state=="move") {
        if (self.forest_kind=="slime") return "Hop"
        if (self.forest_kind=="sweeper") return "Walk"
        return "Run"
    }
    if (self.forest_kind=="sweeper") return "Wake"
    return "Idle"
}

/// Changes only the pose clock; world position, collider and falling velocity stay intact.
function funForestEnemyState(next_state) {
    self.state=next_state
    self.animation_finished=false
    self.attack_spawned=false
    self.sprite_index=asset_get_index(self.art_prefix+funForestEnemyAnimation(next_state))
    self.image_index=0
    self.image_speed=1
    if (next_state=="windup") self.image_speed=0
    if (next_state=="attack" and self.forest_kind!="maw") self.image_index=funForestEnemyActiveStart()
    if (self.forest_kind=="sweeper" and (next_state=="idle" or next_state=="recover")) {
        self.image_index=self.image_number-1
        self.image_speed=0
    }
    if (next_state=="recover") self.state_timer=18
    if (next_state=="hurt" or next_state=="fall_dead") self.state_timer=8
    if (next_state=="dead" or next_state=="fall_dead") {
        self.is_dead=true
        self.can_damage_player=false
        funForestEnemyCancelAttacks()
        funForestEnemyRemoveGlow()
    }
    // The physical recoil ends on landing; the death artwork must not slide across the floor.
    if (next_state=="dead" and self.forest_kind=="slime") self.current_xspeed=0
}

/// Holds one-shot poses at their final frame, including the plant's continuous attack/return sequence.
function funForestEnemyAnimationEnd() {
    self.animation_finished=true
    if (self.state=="hurt" or self.state=="fall_dead" or self.state=="dead"
        or self.forest_kind=="maw" and (self.state=="attack" or self.state=="recover")) {
        self.image_index=self.image_number-1
        self.image_speed=0
    }
}

/// Keeps native hurt art opaque; only the rooted plant needs a single soft damage pulse.
function funForestEnemyDamageAlpha() {
    if (self.forest_kind!="maw" or self.is_dead) return 1
    var elapsed=24-self.hurt_countdown_counter
    if (self.hurt_countdown_counter<=0 or elapsed>=12) return 1
    return 1-.4*(1-abs(elapsed-6)/6)
}

/// Updates combat and locomotion while each actor keeps a stable physical body.
function funForestEnemyStep() {
    self.ambient_clock+=1000/game_get_speed(gamespeed_fps)
    self.hurt_countdown_counter=max(0,self.hurt_countdown_counter-1)
    self.attack_cooldown=max(0,self.attack_cooldown-1)
    self.turn_cooldown=max(0,self.turn_cooldown-1)
    self.alert_timer=max(0,self.alert_timer-1)
    funEnemyUpdateMovement()
    if (!self.is_dead) funForestEnemyTakeDamage()
    self.image_alpha=funForestEnemyDamageAlpha()
    if (self.y>room_height+80) { instance_destroy();return; }
    if (self.state=="dead") {
        if (self.forest_kind!="maw") funForestEnemyMoveGround()
        if (self.animation_finished) instance_destroy()
        return;
    }
    if (self.state=="hurt" or self.state=="fall_dead") {
        self.can_damage_player=false
        self.state_timer-=1
        if (self.forest_kind=="bat") funForestBatHurtStep()
        else funForestEnemyMoveGround()
        if (self.forest_kind=="slime") self.current_xspeed*=.92
        var grounded=funEnemyOnGroundAt(self.x,self.y) and self.current_yspeed==0
        if (self.forest_kind=="slime" and !grounded) {
            return;
        }
        if (self.state_timer<=0 and self.animation_finished) {
            if (self.is_dead) funForestEnemyState("dead")
            else { self.hop_phase="none";self.current_xspeed=0;funForestEnemyState("idle");self.attack_cooldown=0 }
        }
        return;
    }
    self.can_damage_player=true
    self.sees_player=funEnemySeePlayer()
    if (self.sees_player) self.alert_timer=120
    if (self.forest_kind=="bat") { funForestEnemyBatStep();return; }
    if (self.state=="windup" or self.state=="attack") { funForestEnemyAttackStep();return; }
    if (self.state=="recover") {
        self.state_timer-=1
        if (self.forest_kind!="maw") {
            if (!self.air_navigation_active) self.current_xspeed=0
            funForestEnemyMoveGround()
        }
        if (self.state_timer<=0 and (self.forest_kind!="slime" or !self.was_airborne)) {
            self.hop_phase="none"
            funForestEnemyState("idle")
        }
        return;
    }
    if (self.forest_kind=="slime") { funForestSlimeStep();return; }
    funForestEnemyGroundStep()
}

/// Draws the unchanged source poses around physical anchors.
function funForestEnemyDraw() {
    var pose=funForestEnemyPose()
    var art=funThemeSprite(self.sprite_index,self.visual_theme)
    if (self.forest_kind=="barrel" and self.sprite_index==sBarkBomberAttack) art=sBarkBomberAttackCast
    if (self.forest_kind=="maw") art=funRootMawSkinSprite(asset_get_index(sprite_get_name(self.sprite_index)+"Bare"),self.maw_skin)
    draw_sprite_ext(art,self.image_index,self.x+pose.x*self.image_xscale,self.y+pose.y*self.image_yscale,
        self.image_xscale,self.image_yscale,0,c_white,self.image_alpha)
    // The rosette and stalk share one death lifetime, so neither part disappears early.
    if (self.forest_kind!="maw") return;
    var durations=[360,240,360,420,360,240,360,420]
    var phase=self.ambient_clock mod 2760,leaf_frame=0
    while (phase>=durations[leaf_frame] and leaf_frame<7) { phase-=durations[leaf_frame];leaf_frame+=1 }
    draw_sprite_ext(funRootMawSkinSprite(sRootMawRosette,self.maw_skin),leaf_frame,self.x,self.y,1,1,0,c_white,self.image_alpha)
}
