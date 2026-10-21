/// Applies a detected enemy hit through the real player hurt entry point.
function funFeedbackAcceptHit() {
    var detected=undefined
    with (oPlayer) detected=funPlayerDetectCriticalState()
    if (detected!=player_states.hurt) show_debug_message("FOREST_DIAG contact player="+string(oPlayer.x)+","+string(oPlayer.y)+" mask="+string(oPlayer.mask_index)+" bounds="+string(oPlayer.bbox_left)+","+string(oPlayer.bbox_top)+","+string(oPlayer.bbox_right)+","+string(oPlayer.bbox_bottom)+" state="+string(oPlayer.state)+" future="+string(oPlayer.future_damage))
    funForestSmokeAssert(detected==player_states.hurt,"fixture contact reaches the real damage resolver")
    with (oPlayer) funPlayerHurtStart()
}

/// Covers both sides and all player movement directions for bodies, area strikes and thorns.
function funFeedbackKnockbackCases() {
    var objects=[oResinSlime,oBarkGuard,oRootReaper]
    for (var n=0;n<array_length(objects);++n) for (var side=-1;side<=1;side+=2) {
        for (var movement=-2;movement<=2;movement+=2) {
            var actor=instance_create_depth(300,336,0,objects[n])
            funRevisionPlayer(300+side*4,336)
            oPlayer.hurt_countdown_counter=0;oPlayer.current_xspeed=movement
            funFeedbackAcceptHit()
            funForestSmokeAssert(oPlayer.current_xspeed==side*oPlayer.hurt_ximpulse,"body knockback is away regardless of player movement")
            actor.can_damage_player=false
            funRevisionPlayer(300+side*28,336)
            var strike=instance_create_depth(oPlayer.x-12,315,0,oForestStrike,{owner_id:actor,
                sprite_index:sForestStrikeCollision,mask_index:sForestStrikeCollision,image_xscale:24,image_yscale:24,can_damage_player:true})
            strike.can_damage_player=true
            oPlayer.hurt_countdown_counter=0;oPlayer.current_xspeed=movement
            funFeedbackAcceptHit()
            funForestSmokeAssert(oPlayer.current_xspeed==side*oPlayer.hurt_ximpulse,"strike rectangle's left edge cannot reverse knockback")
            instance_destroy(strike)
            var away_direction=0
            actor.current_xspeed=side*2
            with (oPlayer) away_direction=funForestPlayerKnockbackDirection(actor,actor.x)
            funForestSmokeAssert(away_direction==side,"equal-x contact uses attack motion rather than player input")
            instance_destroy(actor)
        }
    }
    funRevisionPlayer(300,336)
    var thorn=instance_create_depth(300,326,0,oForestProjectile,{owner_id:noone,
        seed_blast:false,seed_gravity:0,current_xspeed:-3,current_yspeed:0})
    oPlayer.hurt_countdown_counter=1
    with (oPlayer) funPlayerDetectCriticalState()
    funForestSmokeAssert(instance_exists(thorn) and oPlayer.health==100,"invulnerable overlap does not consume thorn")
    oPlayer.hurt_countdown_counter=0
    funFeedbackAcceptHit()
    funForestSmokeAssert(!instance_exists(thorn) and oPlayer.health==99 and oPlayer.current_xspeed<0,"accepted thorn damage consumes it and follows its trajectory")
    show_debug_message("FOREST_FEEDBACK_PASS 36 real body/strike hits, equal-x fallback and accepted thorn consumption")
}

/// Hits controlled floor, wall, ceiling and corner geometry without advancing a fuse timer.
function funFeedbackImpactCases() {
    var surfaces=[[280,250,80,10],[400,240,12,60],[280,250,80,10],[400,250,12,30]]
    var shots=[[300,247,0,3],[397,270,3,0],[300,263,0,-3],[397,247,3,3]]
    for (var n=0;n<4;++n) {
        var b=surfaces[n],s=shots[n]
        var wall=instance_create_depth(b[0],b[1],0,oSolid,{sprite_index:sForestStrikeCollision,
            mask_index:sForestStrikeCollision,image_xscale:b[2],image_yscale:b[3]})
        var bomb=instance_create_depth(s[0],s[1],0,oForestProjectile,{owner_id:noone,
            seed_blast:true,seed_gravity:0,current_xspeed:s[2],current_yspeed:s[3]})
        with (bomb) funForestProjectileStep()
        funForestSmokeAssert(bomb.blasting and bomb.life==16 and bomb.image_index==0,"first solid contact immediately starts one complete explosion")
        if (n==0 or n==3) funForestSmokeAssert(bomb.ground_impact and bomb.y==250,"floor/corner blast uses actual surface")
        else funForestSmokeAssert(!bomb.ground_impact,"wall/ceiling blast is not relocated to floor")
        with (bomb) funForestProjectileDetonate()
        funForestSmokeAssert(bomb.life==16,"repeated detonation request is harmless")
        instance_destroy(bomb);instance_destroy(wall)
    }
    show_debug_message("FOREST_FEEDBACK_PASS immediate floor/wall/ceiling/corner explosions")
}

/// Verifies loss-of-sight return and rejects repeated dives when a tiny cavity prevents retreat.
function funFeedbackBatEdgeCases() {
    funRevisionPlayer(400,336)
    var actor=instance_create_depth(300,280,0,oForestBat)
    actor.home_x=200;actor.home_y=280;actor.sees_player=false
    with (actor) funForestEnemyBatStep()
    funForestSmokeAssert(actor.returning_home and actor.x<300,"lost target permits a gradual homeward flight")
    var previous_x=actor.x
    actor.sees_player=true;actor.attack_cooldown=999
    with (actor) funForestEnemyBatStep()
    funForestSmokeAssert(!actor.returning_home and actor.x>previous_x,"sighting immediately overrides homeward flight")
    instance_destroy(actor)
    var boxes=[[280,240,60,12],[280,268,60,12],[280,240,19,40],[317,240,20,40]],walls=[]
    for (var i=0;i<array_length(boxes);++i) {
        var b=boxes[i]
        array_push(walls,instance_create_depth(b[0],b[1],0,oSolid,{sprite_index:sForestStrikeCollision,
            mask_index:sForestStrikeCollision,image_xscale:b[2],image_yscale:b[3]}))
    }
    actor=instance_create_depth(308,260,0,oForestBat)
    actor.x=308;actor.y=260;actor.sees_player=true;actor.has_awoken=true
    with (actor) funForestBatStartRetreat()
    for (var tick=0;tick<60;++tick) with (actor) funForestEnemyBatStep()
    funForestSmokeAssert(actor.retreat_required and actor.state=="retreat" and actor.attack_serial==0,"blocked retreat cannot become a stationary attack loop")
    instance_destroy(actor)
    for (var i=0;i<array_length(walls);++i) instance_destroy(walls[i])
    show_debug_message("FOREST_FEEDBACK_PASS lost target return, immediate reacquisition and blocked retreat without attack spam")
}

/// Begins rendered reaction checks after deterministic damage and impact cases have passed.
function funFeedbackStart() {
    funRevisionClear()
    funFeedbackKnockbackCases()
    funFeedbackImpactCases()
    funFeedbackBatEdgeCases()
    funFeedbackBombOwnerCases()
    funRevisionPlayer(300,336)
    var objects=[oResinSlime,oBarkBomber,oForestBat,oBarkGuard,oRootReaper,oRootMaw]
    self.hurt_actors=[]
    for (var i=0;i<array_length(objects);++i) {
        var actor=instance_create_depth(200+i*38,336,0,objects[i])
        actor.vision_radius=0;actor.rear_vision_radius=0;actor.attack_cooldown=999
        funRevisionHit(actor,1)
        array_push(self.hurt_actors,actor)
    }
    self.stage=21;self.frames=0
}

/// Advances the actual projectile physics until impact, without relying on a surviving owner.
function funFeedbackBombReachImpact(bomb) {
    for (var tick=0;tick<150 and instance_exists(bomb) and !bomb.blasting;++tick) {
        with (bomb) funForestProjectileStep()
    }
    funForestSmokeAssert(instance_exists(bomb) and bomb.blasting,"released bomb still reaches impact and explodes")
}

/// Covers nonfatal interruption, death cleanup and an already active blast after the thrower's death.
function funFeedbackBombOwnerCases() {
    funRevisionClear()
    funRevisionPlayer(220,336)
    var thrower=instance_create_depth(300,336,0,oBarkBomber)
    thrower.attack_target_x=380;thrower.attack_target_y=326
    with (thrower) funForestEnemyFireSeed()
    var bomb=instance_find(oForestProjectile,0)
    for (var tick=0;tick<20;++tick) with (bomb) funForestProjectileStep()
    funForestSmokeAssert(!bomb.blasting,"bomb is airborne before its thrower is hit")
    var previous_x=bomb.x,previous_y=bomb.y,vx=bomb.current_xspeed,vy=bomb.current_yspeed
    funRevisionHit(thrower,1)
    funForestSmokeAssert(instance_exists(bomb) and bomb.x==previous_x and bomb.y==previous_y
        and bomb.current_xspeed==vx and bomb.current_yspeed==vy,"hurt cannot cancel or alter an airborne bomb")
    funRevisionHit(thrower,9)
    funForestSmokeAssert(thrower.is_dead and instance_exists(bomb),"lethal hit leaves the released bomb alive")
    instance_destroy(thrower)
    funForestSmokeAssert(instance_exists(bomb),"thrower cleanup also leaves the released bomb alive")
    funFeedbackBombReachImpact(bomb)
    funRevisionPlayer(bomb.x,bomb.y)
    oPlayer.hurt_countdown_counter=0
    with (bomb) self.can_damage_player=funForestBlastHitsPlayer()
    funFeedbackAcceptHit()
    funForestSmokeAssert(oPlayer.health==99,"orphaned explosion still damages the player")
    instance_destroy(bomb)
    thrower=instance_create_depth(300,336,0,oBarkBomber)
    thrower.attack_target_x=380;thrower.attack_target_y=326
    with (thrower) funForestEnemyFireSeed()
    bomb=instance_find(oForestProjectile,0)
    funFeedbackBombReachImpact(bomb)
    var strike=instance_create_depth(300,336,0,oForestStrike,{owner_id:thrower})
    funRevisionHit(thrower,9)
    instance_destroy(thrower)
    funForestSmokeAssert(instance_exists(bomb) and bomb.blasting and !instance_exists(strike),"death preserves an active blast while cancelling the attached strike")
    for (var tick=0;tick<16 and instance_exists(bomb);++tick) with (bomb) funForestProjectileStep()
    funForestSmokeAssert(!instance_exists(bomb),"orphaned explosion completes its normal lifetime")
    var guard=instance_create_depth(300,336,0,oBarkGuard)
    guard.attack_target_x=450;guard.attack_target_y=326
    with (guard) funForestEnemyFireSeed()
    var thorn=instance_find(oForestProjectile,0)
    for (var tick=0;tick<20;++tick) with (thorn) funForestProjectileStep()
    previous_x=thorn.x;previous_y=thorn.y;vx=thorn.current_xspeed;vy=thorn.current_yspeed
    var remaining=thorn.life
    strike=instance_create_depth(guard.x,guard.y,0,oForestStrike,{owner_id:guard})
    funRevisionHit(guard,1)
    funForestSmokeAssert(instance_exists(thorn) and thorn.x==previous_x and thorn.y==previous_y
        and thorn.current_xspeed==vx and thorn.current_yspeed==vy and thorn.life==remaining,
        "hurt leaves the released thorn's position, velocity and lifetime intact")
    funForestSmokeAssert(!instance_exists(strike),"hurt still cancels attached melee damage")
    funRevisionHit(guard,9)
    funForestSmokeAssert(guard.is_dead and instance_exists(thorn),"thorn survives lethal owner damage")
    instance_destroy(guard)
    funForestSmokeAssert(instance_exists(thorn),"thorn survives owner cleanup")
    funRevisionPlayer(thorn.x,thorn.y+10)
    oPlayer.hurt_countdown_counter=0
    funFeedbackAcceptHit()
    funForestSmokeAssert(oPlayer.health==99 and !instance_exists(thorn),"orphaned thorn still damages the player and is consumed")
    funRevisionClear()
    show_debug_message("FOREST_FEEDBACK_PASS bombs and thorns survive hurt/death/cleanup and retain player damage; attached strikes cancel")
}

/// Checks native reaction clocks, an anchored death and repeated dives beside the screenshot's block.
function funFeedbackStep() {
    if (self.frames mod 2==0) self.capture_name="feedback-"+string(self.stage)+"-"+string(1000+self.frames)
    if (self.stage==21) {
        funRevisionPlayer(300,336)
        for (var i=0;i<array_length(self.hurt_actors);++i) {
            var actor=self.hurt_actors[i]
            if (actor.forest_kind!="maw") {
                funForestSmokeAssert(actor.image_alpha==1,"native hurt is never strobed by invulnerability")
                if (self.frames<=10) funForestSmokeAssert(actor.state=="hurt","native two-frame hurt is not truncated by eight-tick stun")
            } else funForestSmokeAssert(actor.image_alpha>=.6,"plant pulse is gentle")
        }
        if (self.frames<36) return;
        show_debug_message("FOREST_FEEDBACK_PASS all six rendered hurt reactions, complete native animation and no alpha strobe")
        funRevisionClear()
        self.target=instance_create_depth(300,336,0,oResinSlime,{visual_theme:"night"})
        funForestSmokeAssert(self.target.vision_radius==360 and self.target.rear_vision_radius==200,"hopper sight doubled")
        funRevisionHit(self.target,9)
        self.death_x=self.target.x;self.death_y=self.target.y;self.death_frame=0
        self.stage=22;self.frames=0;return;
    }
    if (self.stage==22) {
        funRevisionPlayer(260,336)
        if (instance_exists(self.target)) {
            var t=self.target
            funForestSmokeAssert(t.state=="dead" and t.x==self.death_x and abs(t.y-self.death_y)<.01,"grounded death never slides or teleports; state="+t.state+" xy="+string(t.x)+","+string(t.y)+" origin="+string(self.death_x)+","+string(self.death_y)+" vx="+string(t.current_xspeed))
            funForestSmokeAssert(t.image_alpha==1 and t.image_index>=self.death_frame,"death is opaque and advances once")
            self.death_frame=t.image_index
        } else {
            funForestSmokeAssert(self.frames>=40,"death animation completes before removal")
        }
        if (self.frames<48) return;
        funForestSmokeAssert(!instance_exists(self.target),"death ends after one native cycle")
        show_debug_message("FOREST_FEEDBACK_PASS anchored single-play hopper death")
        funRevisionClear()
        funRevisionPlayer(480,336)
        self.target=instance_create_depth(520,282,0,oForestBat)
        self.target.attack_cooldown=0
        self.stage=23;self.frames=0;self.dive_count=0;self.bat_hits=0
        self.last_bat_state="";self.last_dive_end=-100;self.dive_end_x=0;self.dive_end_y=0;return;
    }
    if (self.stage==23) {
        var t=self.target
        if (oPlayer.health<100) self.bat_hits+=1
        funRevisionPlayer(480,336)
        if (t.state=="attack" and self.last_bat_state!="attack") {
            if (self.dive_count>0) {
                funForestSmokeAssert(self.frames-self.last_dive_end>=30,"dives are separated by cooldown")
                funForestSmokeAssert(point_distance(t.x,t.y,self.dive_end_x,self.dive_end_y)>=24,"next dive requires actual retreat displacement")
            }
            self.dive_count+=1
        }
        if (t.state=="retreat" and self.last_bat_state!="retreat") {
            self.last_dive_end=self.frames;self.dive_end_x=t.x;self.dive_end_y=t.y
        }
        self.last_bat_state=t.state
        if (self.frames<420) return;
        funForestSmokeAssert(self.dive_count>=3 and self.bat_hits>=self.dive_count-1,"stationary player beside block is reached reliably, rather than five empty attacks per hit")
        show_debug_message("FOREST_FEEDBACK_PASS screenshot block: dives="+string(self.dive_count)+" hits="+string(self.bat_hits)+" with moving retreats")
        funRevisionClear()
        if (global.forest_feedback_only) { show_debug_message("FOREST_FEEDBACK_PASS completed");game_end();return; }
        funRevisionStartBenchmark()
    }
}
