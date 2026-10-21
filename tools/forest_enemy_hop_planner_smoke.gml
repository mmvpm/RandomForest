/// Executes physical flight in a disposable body, independently of candidate acceptance.
function funHopPlannerPhysical(actor,side,short_hop) {
    var probe=instance_create_depth(actor.x,actor.y,0,oResinSlime)
    probe.image_xscale=side*abs(actor.image_xscale);probe.image_yscale=actor.image_yscale
    probe.current_yspeed=-5.4;probe.hop_phase="flight"
    var start_x=probe.x,start_y=probe.y,landed=false,danger=false,flew=false
    for (var tick=0;tick<70 and !landed and !danger;++tick) {
        probe.current_xspeed=side*min(short_hop ? .4 : 1.2,short_hop ? max(0,12-abs(probe.x-start_x)) : 1.2)
        with (probe) { funForestEnemyMoveGround();danger=funEnemyPositionIsDangerous(self.x,self.y) }
        var grounded=false
        with (probe) grounded=self.current_yspeed==0 and funEnemyOnGroundAt(self.x,self.y)
        if (!grounded) flew=true
        landed=probe.landed
    }
    var result={safe:landed and flew and !danger and probe.y-start_y<=36.001
        and (abs(probe.x-start_x)>.01 or abs(probe.y-start_y)>.01),x:probe.x,y:probe.y}
    instance_destroy(probe)
    return result
}

/// Compares prediction, independent free flight and a committed hop through real animation phases.
function funHopPlannerCheck(actor,side,short_hop,flat=false) {
    var px=actor.x,py=actor.y,scale=actor.image_xscale,vx=actor.current_xspeed,vy=actor.current_yspeed
    var drop=actor.drop_through_counter,phase=actor.hop_phase,state=actor.state,sounds=array_length(global.forest_sound_events)
    var candidate=undefined
    with (actor) candidate=funForestSlimeHopCandidate(side,false,short_hop)
    funForestSmokeAssert(actor.x==px and actor.y==py and actor.image_xscale==scale
        and actor.current_xspeed==vx and actor.current_yspeed==vy and actor.drop_through_counter==drop
        and actor.hop_phase==phase and actor.state==state and array_length(global.forest_sound_events)==sounds,
        "candidate queries restore the live body and do not play sounds")
    var physical=funHopPlannerPhysical(actor,side,short_hop)
    funForestSmokeAssert(!physical.safe or candidate!=undefined,"safe physical flight must not be falsely rejected xy="+string(px)+","+string(py)+" side="+string(side)+" short="+string(short_hop))
    if (candidate==undefined) return 0
    funForestSmokeAssert(physical.safe,"accepted patrol hop has a safe physical landing")
    funForestSmokeAssert(abs(candidate.landing_x-physical.x)<=1 and abs(candidate.landing_y-physical.y)<=1,
        "prediction agrees with free-flight first landing xy="+string(px)+","+string(py)+" side="+string(side)+" short="+string(short_hop))
    var probe=instance_create_depth(px,py,0,oResinSlime)
    probe.image_xscale=scale;probe.sees_player=false;probe.vision_radius=0;probe.rear_vision_radius=0
    var accepted=false,landed=false
    with (probe) accepted=funForestSlimeStartHop(side,false,short_hop)
    funForestSmokeAssert(accepted,"the compared candidate can be committed")
    var top=py,flight_frames=0
    for (var tick=0;tick<80 and !landed;++tick) {
        with (probe) { funEnemyUpdateMovement();funForestSlimeStep() }
        top=min(top,probe.y);landed=probe.landed
        if (probe.hop_phase=="flight") flight_frames+=1
        if (short_hop) funForestSmokeAssert(abs(probe.x-px)<=12.001,"short hop never exceeds one cell")
    }
    funForestSmokeAssert(landed and abs(probe.x-candidate.landing_x)<=1 and abs(probe.y-candidate.landing_y)<=1,
        "committed hop lands on its predicted surface xy="+string(px)+","+string(py)+" side="+string(side)+" short="+string(short_hop))
    if (flat) funForestSmokeAssert(abs(py-top-39)<.01 and flight_frames==30,
        "short and full hops preserve the 39px rise and 30-frame level flight")
    instance_destroy(probe)
    return 1
}

/// Checks exact drop boundaries, narrow platforms, mirrored bodies and unchanged vertical flight.
function funHopPlannerFixtureCases() {
    var comparisons=0
    for (var side=-1;side<=1;side+=2) for (var fraction=.2;fraction<1;fraction+=.4) {
        funPatrolSmokeClear();funPatrolSmokeSolid(80,432,1000,60);funPatrolSmokeSolid(300,336,12,12)
        var actor=instance_create_depth(306+fraction,336,0,oResinSlime)
        actor.image_xscale=-side;actor.sees_player=false
        var full=undefined,small=undefined
        with (actor) { full=funForestSlimeHopCandidate(side,false);small=funForestSlimeHopCandidate(side,false,true) }
        funForestSmokeAssert(full==undefined,"full hop leaves the one-cell platform and falls too far")
        comparisons+=funHopPlannerCheck(actor,side,true)
        with (actor) funForestSlimeStep()
        funForestSmokeAssert(actor.hop_phase=="prepare" and actor.hop_candidate.air_speed==.4,"normal decision selects a short hop when both full hops are unsafe")
    }
    for (var side=-1;side<=1;side+=2) for (var short_hop=0;short_hop<=1;++short_hop) {
        funPatrolSmokeClear();funPatrolSmokeSolid(80,336,1000,60)
        var actor=instance_create_depth(500.4,336,0,oResinSlime)
        actor.sees_player=false
        var candidate=undefined
        with (actor) candidate=funForestSlimeHopCandidate(side,false,bool(short_hop))
        comparisons+=funHopPlannerCheck(actor,side,bool(short_hop),true)
        funForestSmokeAssert(candidate!=undefined,"flat ground allows either hop length")

    }
    for (var n=0;n<3;++n) {
        funPatrolSmokeClear();var drop_depth=n==0 ? 36 : 37
        funPatrolSmokeSolid(200,240,200,12);funPatrolSmokeSolid(400,240+drop_depth,300,80)
        var actor=instance_create_depth(386,240,0,oResinSlime)
        funRevisionPlayer(460,240+drop_depth);actor.sees_player=n==2
        var candidate=undefined
        with (actor) candidate=funForestSlimeHopCandidate(1,true)
        funForestSmokeAssert((candidate!=undefined)==(n!=1),"patrol accepts 36px, rejects 37px; pursuit retains deeper falls")
    }
    // A short descent can outlast the level flight: its horizontal travel must still stop at 12px.
    funPatrolSmokeClear();funPatrolSmokeSolid(200,240,200,12);funPatrolSmokeSolid(400,276,300,80)
    var actor=instance_create_depth(399.4,240,0,oResinSlime)
    actor.sees_player=false
    comparisons+=funHopPlannerCheck(actor,1,true)
    funPatrolSmokeClear();funPatrolSmokeSolid(80,336,1000,60)
    funPatrolSmokeSolid(260,200,12,136);funPatrolSmokeSolid(288,200,12,136)
    var actor=instance_create_depth(280,336,0,oResinSlime)
    actor.sees_player=false
    var tiny=undefined
    with (actor) tiny=funForestSlimeChooseHop(1)
    funForestSmokeAssert(tiny!=undefined and abs(tiny.landing_x-actor.x)>.01 and abs(tiny.landing_x-actor.x)<6,
        "a real tiny move remains valid when no full route fits")
    comparisons+=funHopPlannerCheck(actor,tiny.move_direction,false)
    funPatrolSmokeClear();funPatrolSmokeSolid(80,432,1000,60);funPatrolSmokeSolid(500,336,1,12)
    var actor=instance_create_depth(500.4,336,0,oResinSlime)
    actor.sees_player=false
    with (actor) funForestSlimeStep()
    funForestSmokeAssert(actor.hop_phase=="none" and actor.turn_cooldown==12,
        "all routes falling too far permit an idle retry")
    funPatrolSmokeClear();funPatrolSmokeSolid(80,336,1000,60)
    instance_create_depth(516,240,0,oTrap,{sprite_index:sForestStrikeCollision,
        mask_index:sForestStrikeCollision,image_xscale:72,image_yscale:96})
    var actor=instance_create_depth(500.4,336,0,oResinSlime)
    actor.sees_player=false
    var dangerous=undefined,safe=undefined
    with (actor) { dangerous=funForestSlimeHopCandidate(1,false);safe=funForestSlimeHopCandidate(-1,false) }
    funForestSmokeAssert(dangerous==undefined and safe!=undefined,"hazard avoidance remains active along the trajectory")
    funHopLifecycleEdgeCases();funHopLifecycleBlockedTakeoff();funPatrolSmokeFallbackCases()
    show_debug_message("FOREST_PLANNER_PASS physical comparisons and drop/short-hop boundaries cases="+string(comparisons))
}

/// Opens each original map, preserving its authored geometry and the level-18 hopper instance.
function funHopPlannerStartMap(number) {
    self.planner_level=number;funOpenLevel(number+9);self.stage=1;self.frames=0
}

/// Tests reported roots, then observes normal patrol without forced state recovery.
function funHopPlannerSetupMap() {
    var number=self.planner_level,actor=noone
    if (number==18) with (oResinSlime) if (abs(self.home_x-372)<1 and abs(self.home_y-468)<1) actor=self.id
    if (number>=14 and number<=17) actor=instance_find(oResinSlime,0)
    with (oForestEnemy) if (self.id!=actor) instance_destroy()
    if (number==12) actor=instance_create_depth(54.4,120,0,oResinSlime)
    if (number==13) actor=instance_create_depth(732.4,144,0,oResinSlime)

    if (!instance_exists(actor)) actor=instance_create_depth(54.4,120,0,oResinSlime)
    actor.vision_radius=0;actor.rear_vision_radius=0;actor.attack_cooldown=999999;actor.sees_player=false
    var sx=actor.x,sy=actor.y
    var roots=[]
    if (number==12) roots=[[84.4,108],[88,108]]
    if (number==13) roots=[[732.4,144]]
    if (number==18) roots=[[485.40094,420]]
    for (var n=0;n<array_length(roots);++n) {
        actor.x=roots[n][0];actor.y=roots[n][1]
        for (var side=-1;side<=1;side+=2) for (var short_hop=0;short_hop<=1;++short_hop)
            self.planner_compared+=funHopPlannerCheck(actor,side,bool(short_hop))
    }
    // Sample untouched map geometry, not only convenient authored spawn points.
    var samples=0
    for (var py=48;py<room_height-24 and samples<24;py+=12) for (var px=24.4;px<room_width-24 and samples<24;px+=24) {
        actor.x=px;actor.y=py
        var supported=false
        with (actor) supported=instance_place(self.x,self.y,oSolid)==noone
            and funEnemyOnGroundAt(self.x,self.y) and !funEnemyPositionIsDangerous(self.x,self.y)
        if (!supported) continue
        for (var side=-1;side<=1;side+=2) for (var short_hop=0;short_hop<=1;++short_hop)
            self.planner_compared+=funHopPlannerCheck(actor,side,bool(short_hop))
        samples+=1
    }
    actor.x=sx;actor.y=sy
    if (number==12) { actor.current_direction=1;actor.image_xscale=1 }
    self.target=actor;oCamera.following=actor;self.planner_stationary=0;self.planner_landings=0
    self.planner_last_x=actor.x;self.planner_last_y=actor.y;self.planner_top=false;self.planner_returned=false
    self.stage=2;self.frames=0
}

/// Observes false refusals, including arrival at and departure from the reported staircase top.
function funHopPlannerMapStep() {
    var actor=self.target
    funForestSmokeAssert(instance_exists(actor),"reported hopper survives the map patrol")
    funRevisionPlayer(room_width-36,36);oPlayer.image_alpha=0
    if (abs(actor.x-self.planner_last_x)<.01 and abs(actor.y-self.planner_last_y)<.01) self.planner_stationary+=1
    else self.planner_stationary=0
    self.planner_last_x=actor.x;self.planner_last_y=actor.y
    if (actor.landed) self.planner_landings+=1
    if (self.planner_level==18 and actor.y<=420 and actor.x>=465) self.planner_top=true
    if (self.planner_top and actor.x<450 and actor.y>=432) self.planner_returned=true
    if (self.planner_stationary>=60 and self.frames mod 12==0) {
        for (var side=-1;side<=1;side+=2) for (var short_hop=0;short_hop<=1;++short_hop) {
            var actual=funHopPlannerPhysical(actor,side,bool(short_hop))
            funForestSmokeAssert(!actual.safe,"stationary hopper must have no safe physical moving hop")
        }
    }
    if (self.frames mod 300==0) show_debug_message("FOREST_PLANNER_POSITION level="+string(self.planner_level)
        +" xy="+string(actor.x)+","+string(actor.y)+" stationary="+string(self.planner_stationary)+" landings="+string(self.planner_landings))
    if (self.frames<1800) return;
    if (self.planner_level==18) funForestSmokeAssert(self.planner_top and self.planner_returned,"authored level18 hopper climbs the stairs and comes back")
    array_push(self.planner_results,{level:self.planner_level,frames:self.frames,landings:self.planner_landings,
        staircase_top:self.planner_top,returned:self.planner_returned})
    if (self.planner_level==18) { funHopPlannerStartMap(12);return; }
    if (self.planner_level<17) { funHopPlannerStartMap(self.planner_level+1);return; }
    funOpenLevel(31);self.stage=3;self.frames=0
}

/// Runs original maps before isolated collision/animation regressions, keeping a durable report.
function funHopPlannerSmokeStep() {
    instance_activate_all();self.frames+=1
    if (instance_exists(oPauseMenu)) oPauseMenu.paused=false
    if (self.stage==0) {
        if (self.frames<60) return;
        self.planner_results=[];self.planner_compared=0;funOpenLevel(31);self.stage=4;self.frames=0;return;
    }
    if (self.stage==4 and self.frames>=30) { funHopPlannerFixtureCases();funHopPlannerStartMap(18);return; }
    if (self.stage==1 and self.frames>=30) { funHopPlannerSetupMap();return; }
    if (self.stage==2) funHopPlannerMapStep()
    if (self.stage==3 and self.frames>=30) {
        var file=file_text_open_write(self.output_directory+"planner-results.json")
        file_text_write_string(file,json_stringify({maps:self.planner_results,comparisons:self.planner_compared}));file_text_close(file)
        show_debug_message("FOREST_PLANNER_PASS completed");game_end()
    }
}
