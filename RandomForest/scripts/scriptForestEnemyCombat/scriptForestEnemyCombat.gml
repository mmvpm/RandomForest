/// Resolves the physical attack origin independently of player input or a strike rectangle's edge.
function funForestPlayerKnockbackDirection(source,player_x) {
    if (source.object_index==oForestProjectile and !source.seed_blast) return sign(source.current_xspeed)
    var actor=source
    if (source.object_index==oForestStrike and instance_exists(source.owner_id)) actor=source.owner_id
    var away=sign(player_x-actor.x)
    if (away==0 and variable_instance_exists(actor,"current_xspeed")) away=sign(actor.current_xspeed)
    if (away==0) away=sign(actor.image_xscale)
    return away==0 ? 1 : away
}

/// Applies each hit once; the rooted plant pulses in place and a hopper falls from its actual height.
function funForestEnemyTakeDamage() {
    if (self.hurt_countdown_counter>0) return false
    var plant=self.forest_kind=="maw"
    var trap=plant ? funForestMawDamageInstance(oTrap) : instance_place(self.x,self.y,oTrap)
    var sword=plant ? funForestMawDamageInstance(oPlayerSword) : instance_place(self.x,self.y,oPlayerSword)
    var source=trap!=noone ? trap : sword
    if (source==noone) source=plant ? funForestMawWaveDamage() : funPlayerStompWaveDamage()
    if (source==noone or source.damage<=0) return false
    var applied=min(source.damage,self.health)
    self.health-=applied
    self.hurt_countdown_counter=24
    self.alert_timer=120
    funShowDamageText(self,applied,false)
    funForestEnemyCancelAttacks()
    if (plant) {
        self.bite_cancelled=true
        if (self.health<=0) funForestEnemyState("dead")
        self.stomp_knockback_direction=0
        return true
    }
    var airborne=self.current_yspeed!=0 or !funEnemyOnGroundAt(self.x,self.y)
    var away=sign(self.x-source.x)
    if (away==0) away=-sign(self.image_xscale)
    funEnemyCancelAirMovement()
    if (self.forest_kind=="bat" and !self.has_awoken) funForestBatDetach()
    self.hop_phase="none"
    if (self.forest_kind=="slime") {
        self.current_yspeed=max(0,self.current_yspeed)
        self.current_xspeed=away*2
        self.was_airborne=airborne
    } else {
        self.current_xspeed=0
        funEnemyStompKnockbackStart()
    }
    funForestEnemyState(self.health<=0 ? (airborne ? "fall_dead" : "dead") : "hurt")
    self.stomp_knockback_direction=0
    return true
}

/// Cancels attached strikes; released thorns and bombs finish independently of their owner.
function funForestEnemyCancelAttacks() {
    var owner=self.id
    with (oForestStrike) if (self.owner_id==owner) instance_destroy()
}

/// Returns the authored first damage/release frame, excluding anticipation poses.
function funForestEnemyActiveStart() {
    switch (self.forest_kind) {
        case "slime": return 4
        case "barrel": return 2
        case "maw": return 1
        case "sweeper": return self.attack_style=="AttackSlam" ? 5 : 3
        default: return 3
    }
}

/// Chooses an anticipatory attack and starts its single, readable preparation interval.
function funForestEnemyBeginAttack() {
    var move_direction=sign(oPlayer.x-self.x)
    if (move_direction!=0) self.image_xscale=move_direction*abs(self.image_xscale)
    self.attack_target_x=oPlayer.x
    self.attack_target_y=(oPlayer.bbox_top+oPlayer.bbox_bottom)*.5
    self.attack_style="Attack"
    if (self.forest_kind=="guard") self.attack_style=abs(oPlayer.x-self.x)>funForestGuardMeleeDistance() ? "Attack1" : "Attack2"
    if (self.forest_kind=="sweeper") self.attack_style=oPlayer.bbox_bottom<self.bbox_bottom-10 ? "AttackSlam" : "AttackSweep"
    self.attack_serial+=1
    self.bite_cancelled=false
    self.windup_duration=12
    if (self.forest_kind=="guard") self.windup_duration=18
    if (self.forest_kind=="sweeper" and self.attack_style=="AttackSlam") self.windup_duration=18
    if (self.forest_kind=="maw") self.windup_duration=20
    if (self.forest_kind=="barrel") self.windup_duration=30
    funForestEnemyState("windup")
    self.state_timer=self.windup_duration
    self.attack_elapsed=0
}

/// Plays anticipation once, commits one cue, and preserves airborne movement through landing.
function funForestEnemyAttackStep() {
    if (self.forest_kind!="bat" and self.forest_kind!="maw") {
        if (!self.air_navigation_active) {
            self.current_xspeed=0
            if (self.forest_kind=="sweeper" and self.state=="attack" and self.attack_elapsed<10
                and funEnemyHasGroundAhead(sign(self.image_xscale),2.4)) self.current_xspeed=sign(self.image_xscale)*2.4
        }
        funForestEnemyMoveGround()
    }
    if (self.state=="windup") {
        self.state_timer-=1
        var frames=self.forest_kind=="maw" ? self.image_number : funForestEnemyActiveStart()
        self.image_index=min(frames-.001,(self.windup_duration-self.state_timer)/self.windup_duration*frames)
        if (self.state_timer<=0) {
            // Recheck after anticipation: a moving target may have crossed behind rock.
            if (self.forest_kind=="bat" and !funForestBatPathClear(self.x,self.y,self.attack_target_x,self.attack_target_y)) {
                funForestBatStartRetreat();return;
            }
            funForestEnemyState("attack")
            if (self.forest_kind=="bat") {
                var length=max(1,point_distance(self.x,self.y,self.attack_target_x,self.attack_target_y))
                self.dive_xspeed=(self.attack_target_x-self.x)/length*6
                self.dive_yspeed=(self.attack_target_y-self.y)/length*6
                self.dive_left=min(72,length+8)
                self.dive_total=self.dive_left
                self.image_speed=0
            }
        }
        return;
    }
    self.attack_elapsed+=1
    if (!self.attack_spawned and self.image_index>=funForestEnemyActiveStart()) {
        self.attack_spawned=true
        funForestEnemyPlayAttackSound()
        if (self.forest_kind=="barrel" or self.forest_kind=="guard" and self.attack_style=="Attack1") funForestEnemyFireSeed()
        else if (self.forest_kind!="bat" and self.forest_kind!="maw") funForestEnemyMakeStrike()
    }
    if (self.forest_kind=="bat") {
        var distance=min(6,self.dive_left)
        var clear=funForestEnemyFlyMove(self.dive_xspeed*distance/6,self.dive_yspeed*distance/6)
        self.dive_left-=distance
        var first=funForestEnemyActiveStart()
        self.image_index=min(self.image_number-1,first+(1-self.dive_left/self.dive_total)*(self.image_number-first))
        if (!clear or self.dive_left<=0) self.animation_finished=true
    }
    if (!self.animation_finished) return;
    if (self.forest_kind=="bat") { funForestBatStartRetreat();return; }
    var owner=self.id
    with (oForestStrike) if (self.owner_id==owner) instance_destroy()
    var rest=18
    if (self.forest_kind=="guard") rest=self.attack_style=="Attack1" ? 24 : 12
    if (self.forest_kind=="sweeper") rest=self.attack_style=="AttackSlam" ? 18 : 12
    if (self.forest_kind=="maw") rest=36
    funForestEnemyState("recover")
    self.state_timer=rest
    self.attack_cooldown=self.forest_kind=="barrel" ? 75 : rest
}
