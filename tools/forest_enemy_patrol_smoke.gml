/// Creates one disposable rectangle using the existing one-pixel test collision mask.
function funPatrolSmokeSolid(px,py,width,height) {
    return instance_create_depth(px,py,0,oSolid,{sprite_index:sForestStrikeCollision,
        mask_index:sForestStrikeCollision,image_xscale:width,image_yscale:height})
}

/// Resets only the isolated arena's actors and collision geometry.
function funPatrolSmokeClear() {
    funRevisionClear()
    with (oSolid) instance_destroy()
    with (oTrap) instance_destroy()
}

/// Samples the reported staircase using real collision instances from the current level copy.
function funPatrolSmokeReportedStairs() {
    with (oForestEnemy) instance_destroy()
    funRevisionPlayer(276,516)
    var actor=instance_create_depth(180,444,0,oResinSlime)
    var checked=0,fallbacks=0,best_distance=100000
    for (var py=408;py<=516;py+=6) for (var px=144;px<=300;px+=6) {
        actor.x=px;actor.y=py;actor.current_direction=-1;actor.image_xscale=-1
        var grounded=false,clear=false
        with (actor) {
            clear=instance_place(self.x,self.y,oSolid)==noone
            grounded=clear and funEnemyOnGroundAt(self.x,self.y) and funEnemyHasStableSupportAt(self.x,self.y)
        }
        if (!grounded) continue
        checked+=1
        var chosen=undefined
        with (actor) {
            self.sees_player=funEnemySeePlayer()
            chosen=funForestSlimeChooseHop(-1)
        }
        if (chosen!=undefined and chosen.move_direction==1) {
            fallbacks+=1
            show_debug_message("FOREST_PATROL_STAIRS fallback xy="+string(px)+","+string(py)
                +" sees="+string(actor.sees_player)+" landing="+string(chosen.landing_x)+","+string(chosen.landing_y))
            var distance=point_distance(px,py,150,468)
            if (distance<best_distance) { self.stairs_x=px;self.stairs_y=py;best_distance=distance }
        }
    }
    funForestSmokeAssert(checked>0,"reported staircase contains supported hopper positions")
    if (fallbacks>0) {
        actor.x=self.stairs_x;actor.y=self.stairs_y
        actor.current_direction=-1;actor.image_xscale=-1
    }
    self.target=actor
    self.stairs_landings=0
    show_debug_message("FOREST_PATROL_PASS reported level staircase checked="+string(checked)+" fallback_positions="+string(fallbacks))
    self.pending_shot="reported-stairs"
}

/// Checks the patrol-only drop limit against actual landing simulations on two-height floors.
function funPatrolSmokeDropCases() {
    for (var n=0;n<3;++n) {
        funPatrolSmokeClear()
        var drop=n==0 ? 24 : 60
        funPatrolSmokeSolid(200,240,200,12)
        funPatrolSmokeSolid(400,240+drop,300,80)
        var actor=instance_create_depth(386,240,0,oResinSlime)
        funRevisionPlayer(460,240+drop)
        actor.sees_player=n==2
        var candidate=undefined,limit=0
        with (actor) {
            limit=funForestSlimePatrolDropLimit(-5.4)
            candidate=funForestSlimeHopCandidate(1,true)
        }
        funForestSmokeAssert(abs(limit-36)<.001,"patrol drop limit leaves three pixels below the real jump rise")
        if (n==1) funForestSmokeAssert(candidate==undefined,"patrol rejects a sixty-pixel descent")
        else funForestSmokeAssert(candidate!=undefined,"small patrol descent and deep pursuit remain possible")
    }
    show_debug_message("FOREST_PATROL_PASS patrol accepts 24px, rejects 60px, pursuit accepts 60px")
}

/// Exercises blocked directions, local retreat targets and bounded retries for both facings.
function funPatrolSmokeFallbackCases() {
    for (var side=-1;side<=1;side+=2) for (var pursuit=0;pursuit<=1;++pursuit) {
        funPatrolSmokeClear()
        funPatrolSmokeSolid(80,336,1000,60)
        funPatrolSmokeSolid(side<0 ? 260 : 288,200,12,136)
        var actor=instance_create_depth(280,336,0,oResinSlime)
        actor.current_direction=side;actor.image_xscale=side;actor.sees_player=bool(pursuit)
        funRevisionPlayer(280+side*120,336)
        with (actor) funForestSlimeStep()
        show_debug_message("FOREST_PATROL_DIAG fallback side="+string(side)+" pursuit="+string(pursuit)
            +" phase="+actor.hop_phase+" direction="+string(actor.current_direction)+" xy="+string(actor.x)+","+string(actor.y))
        funForestSmokeAssert(actor.hop_phase=="prepare" and actor.current_direction==-side,
            "blocked patrol/pursuit chooses a safe local hop in the opposite direction")
        var landed=false
        for (var tick=0;tick<70 and actor.hop_phase!="none";++tick) {
            with (actor) { funEnemyUpdateMovement();funForestSlimeStep() }
            if (actor.landed) landed=true
        }
        funForestSmokeAssert(landed and actor.hop_phase=="none" and (actor.x-280)*-side>12,
            "fallback uses one real complete hop and lands away from the blocked route")
    }
    funPatrolSmokeClear()
    funPatrolSmokeSolid(80,336,1000,60)
    var left_wall=funPatrolSmokeSolid(260,200,12,136)
    var right_wall=funPatrolSmokeSolid(288,200,12,136)
    actor=instance_create_depth(280,336,0,oResinSlime)
    actor.sees_player=false;actor.current_direction=-1;actor.image_xscale=-1
    // Close vertical clearance too: tiny real movements between walls are now valid routes.
    var ceiling=funPatrolSmokeSolid(260,300,40,23)
    with (actor) funForestSlimeStep()
    funForestSmokeAssert(actor.hop_phase=="none" and actor.turn_cooldown==12 and actor.current_direction==-1,
        "no takeoff clearance waits without turning or preparing an impossible hop")
    instance_destroy(left_wall);instance_destroy(right_wall);instance_destroy(ceiling)
    with (actor) funForestSlimeStep()
    funForestSmokeAssert(actor.hop_phase=="none","blocked retry interval prevents per-frame replanning")
    actor.vision_radius=0;actor.rear_vision_radius=0
    for (var tick=0;tick<12;++tick) with (actor) funForestEnemyStep()
    funForestSmokeAssert(actor.hop_phase=="prepare","hopper retries and uses a newly opened route")
    show_debug_message("FOREST_PATROL_PASS mirrored patrol/pursuit fallback hops, full landings and blocked retries")
}

/// Checks directional sight, cover and the real attack selector before the rendered long shot.
function funPatrolSmokeGuardCases() {
    funPatrolSmokeClear()
    funPatrolSmokeSolid(80,336,1000,60)
    var guard=instance_create_depth(200,336,0,oBarkGuard)
    guard.attack_cooldown=0
    funForestSmokeAssert(guard.vision_radius==430 and guard.rear_vision_radius==100,"guard front/rear sight settings")
    var seen=false,wants=false
    funRevisionPlayer(620,336)
    oPlayer.image_alpha=1
    with (guard) { self.sees_player=funEnemySeePlayer();seen=self.sees_player;wants=funForestEnemyWantsGroundAttack() }
    funForestSmokeAssert(seen and wants,"guard sees and can attack at 420px")
    with (guard) funForestEnemyBeginAttack()
    funForestSmokeAssert(guard.attack_style=="Attack1","distant player selects the ranged attack")
    funRevisionPlayer(631,336)
    with (guard) seen=funEnemySeePlayer()
    funForestSmokeAssert(!seen,"guard cannot see beyond 430px")
    funRevisionPlayer(90,336)
    with (guard) seen=funEnemySeePlayer()
    funForestSmokeAssert(!seen,"rear sight remains 100px")
    funRevisionPlayer(620,336)
    var wall=funPatrolSmokeSolid(400,260,12,76)
    with (guard) seen=funEnemySeePlayer()
    funForestSmokeAssert(!seen,"rock still blocks distant sight")
    instance_destroy(wall)
    funRevisionPlayer(250,336)
    with (guard) funForestEnemyBeginAttack()
    funForestSmokeAssert(guard.attack_style=="Attack2","close player still selects melee")
    instance_destroy(guard)
    show_debug_message("FOREST_PATROL_PASS guard 420px sight/attack, 431px cutoff, rear sight, cover and melee")
}

/// Advances focused cases and records real frames of a distant aimed thorn reaching the player.
function funForestPatrolSmokeStep() {
    instance_activate_all()
    self.frames+=1
    if (instance_exists(oPauseMenu)) oPauseMenu.paused=false
    if (self.stage==0) {
        if (self.frames<60) return;
        funOpenLevel(21);self.stage=1;self.frames=0;return;
    }
    if (self.stage==1) {
        if (self.frames<30) return;
        funPatrolSmokeReportedStairs()
        self.stage=2;self.frames=0;return;
    }
    if (self.stage==2) {
        if (instance_exists(self.target) and self.target.landed) self.stairs_landings+=1
        if (self.frames==45) self.pending_shot="reported-stairs-moving"
        if (self.frames<90) return;
        funForestSmokeAssert(instance_exists(self.target) and abs(self.target.x-self.stairs_x)>6 and self.stairs_landings>0,
            "reported staircase hopper leaves the blocked left-facing position and completes a landing")
        show_debug_message("FOREST_PATROL_PASS reported staircase moved from="+string(self.stairs_x)+","+string(self.stairs_y)
            +" to="+string(self.target.x)+","+string(self.target.y)+" phase="+self.target.hop_phase)
        funOpenLevel(31);self.stage=3;self.frames=0;return;
    }
    if (self.stage==3) {
        if (self.frames<30) return;
        funFeedbackBombOwnerCases()
        funPatrolSmokeDropCases()
        funPatrolSmokeFallbackCases()
        funPatrolSmokeGuardCases()
        funPatrolSmokeClear()
        funPatrolSmokeSolid(80,336,1000,60)
        self.target=instance_create_depth(200,336,0,oBarkGuard)
        funRevisionPlayer(620,312)
        oPlayer.state=player_states.idle
        oPlayer.hurt_countdown_counter=0
        // Aim at an elevated target to catch the old 72-frame capped thorn trajectory.
        with (self.target) { self.sees_player=funEnemySeePlayer();funForestEnemyBeginAttack() }
        self.stage=4;self.frames=0;self.pending_shot="guard-long-windup";return;
    }
    if (self.stage==4) {
        if (oPlayer.health<100) {
            show_debug_message("FOREST_PATROL_PASS distant elevated thorn hit frame="+string(self.frames))
            self.stage=5;self.frames=0;self.pending_shot="guard-long-hit";return;
        }
        funRevisionPlayer(620,312)
        oPlayer.hurt_countdown_counter=0
        if (self.frames==70) self.pending_shot="guard-long-flight"
        funForestSmokeAssert(self.frames<240,"distant aimed thorn reaches the player before its lifetime expires")
    }
    if (self.stage==5 and self.frames>=2) {
        show_debug_message("FOREST_PATROL_PASS completed")
        game_end()
    }
}
