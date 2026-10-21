/// Verifies physical edge landings during movement and all three attack phases.
function funHopLifecycleEdgeCases() {
    var states=["move","windup","attack","recover"],cases=0
    for (var one_way=0;one_way<=1;++one_way) for (var side=-1;side<=1;side+=2) {
        for (var fraction=.2;fraction<1;fraction+=.4) for (var n=0;n<array_length(states);++n) {
            funPatrolSmokeClear()
            var platform_type=one_way ? oJumpThru : oSolid
            instance_create_depth(300,336,0,platform_type,{sprite_index:sForestStrikeCollision,
                mask_index:sForestStrikeCollision,image_xscale:12,image_yscale:12})
            funPatrolSmokeSolid(240,336,48,12)
            funPatrolSmokeSolid(336,336,96,12)
            var px=side<0 ? 317+fraction : 295+fraction
            var actor=instance_create_depth(px,316,0,oResinSlime)
            actor.current_direction=side;actor.image_xscale=side
            actor.vision_radius=0;actor.rear_vision_radius=0
            var action={landing_x:px,landing_y:336}
            with (actor) {
                funEnemyStartAirAction(action,0,1.2,0)
                self.was_airborne=true;self.hop_phase="flight"
                funForestEnemyState(states[n])
            }
            var sounds_before=array_length(global.forest_sound_events),landed=false
            for (var tick=0;tick<40 and !landed;++tick) {
                with (actor) funForestEnemyMoveGround()
                landed=actor.landed
            }
            funForestSmokeAssert(landed and !actor.air_navigation_active and !actor.was_airborne,
                "edge landing finishes all airborne flags")
            var center_supported=true
            with (actor) center_supported=funEnemyHasStableSupportAt(self.x,self.y)
            funForestSmokeAssert(!center_supported,"fixture lands on body overlap outside the platform center")
            funForestSmokeAssert(actor.state==states[n],"physical landing preserves the current combat phase")
            funForestSmokeAssert(array_length(global.forest_sound_events)==sounds_before+1,"one real landing cue")
            for (var tick=0;tick<5;++tick) with (actor) funForestEnemyMoveGround()
            funForestSmokeAssert(array_length(global.forest_sound_events)==sounds_before+1,"resting on an edge is silent")
            with (actor) { funForestEnemyState("recover");self.state_timer=0;funForestEnemyStep() }
            funForestSmokeAssert(actor.state=="idle" and actor.hop_phase=="none","grounded recovery returns to movement")
            with (actor) funForestEnemyStep()
            funForestSmokeAssert(actor.hop_phase=="prepare","an edge landing permits a fresh safe jump")
            cases+=1
        }
    }
    show_debug_message("FOREST_HOP_PASS edge landings with fractional roots, mirrored bodies, solid/one-way support and attack phases cases="+string(cases))
}

/// Closes a ceiling after planning and checks silent cancellation before physical lift-off.
function funHopLifecycleBlockedTakeoff() {
    funPatrolSmokeClear()
    funPatrolSmokeSolid(80,336,1000,60)
    var actor=instance_create_depth(300,336,0,oResinSlime)
    actor.vision_radius=0;actor.rear_vision_radius=0;actor.sees_player=false
    var accepted=false
    with (actor) accepted=funForestSlimeStartHop(1)
    funForestSmokeAssert(accepted,"takeoff initially has a real valid landing")
    var ceiling=funPatrolSmokeSolid(260,300,120,23)
    for (var tick=0;tick<8;++tick) with (actor) funForestSlimeStep()
    var sounds_before=array_length(global.forest_sound_events)
    with (actor) funForestSlimeStep()
    funForestSmokeAssert(actor.y==336 and actor.hop_phase=="none" and actor.turn_cooldown==12
        and !actor.was_airborne and !actor.air_navigation_active,"blocked takeoff cancels the route on the actual floor")
    funForestSmokeAssert(array_length(global.forest_sound_events)==sounds_before,"no landing cue without lift-off")
    instance_destroy(ceiling)
    for (var tick=0;tick<12;++tick) with (actor) funForestEnemyStep()
    funForestSmokeAssert(actor.hop_phase=="prepare","removing the ceiling allows a normal retry")
    show_debug_message("FOREST_HOP_PASS blocked takeoff cancels silently and retries after twelve frames")
}

/// Builds a save-free course of narrow posts, one-way ledges and a broad lower floor.
function funHopLifecycleStartCourse() {
    funPatrolSmokeClear()
    funPatrolSmokeSolid(80,336,1000,60)
    funPatrolSmokeSolid(80,200,12,136)
    funPatrolSmokeSolid(1068,200,12,136)
    for (var px=264;px<=624;px+=36) funPatrolSmokeSolid(px,312,12,24)
    for (var px=290;px<=590;px+=120) instance_create_depth(px,288,0,oJumpThru,
        {sprite_index:sForestStrikeCollision,mask_index:sForestStrikeCollision,image_xscale:12,image_yscale:6})
    self.target=instance_create_depth(300.4,280,0,oResinSlime)
    self.takeoffs=0;self.landings=0;self.attacks=0;self.last_phase="none";self.last_state=""
    self.last_player_phase=-1;self.lost_target_takeoffs=0;self.course_log=[]
    oCamera.following=self.target
    self.stage=2;self.frames=0
}

/// Drives repeated sight, attack, loss and reacquisition without changing the enemy's state.
function funHopLifecycleCourseStep() {
    var actor=self.target
    funForestSmokeAssert(instance_exists(actor),"hopper survives the repeated course")
    var phase=(self.frames div 180) mod 5
    if (phase==0) funRevisionPlayer(min(1000,actor.x+140),336)
    if (phase==1) funRevisionPlayer(actor.x+28,actor.y)
    if (phase==2) funRevisionPlayer(100,180)
    if (phase==3) funRevisionPlayer(max(120,actor.x-100),actor.y-24)
    if (phase==4) funRevisionPlayer(min(1000,actor.x+140),336)
    oPlayer.hurt_countdown_counter=0
    if (actor.hop_phase=="flight" and self.last_phase!="flight") self.takeoffs+=1
    if (actor.landed) self.landings+=1
    if (actor.state=="attack" and self.last_state!="attack") self.attacks+=1
    var grounded=false
    with (actor) grounded=self.current_yspeed==0 and funEnemyOnGroundAt(self.x,self.y)
    funForestSmokeAssert(!grounded or (!actor.was_airborne and !actor.air_navigation_active),
        "physical support never leaves the hopper locked in an airborne route")
    if (phase!=self.last_player_phase) {
        if (self.last_player_phase==2) funForestSmokeAssert(self.takeoffs>self.lost_target_takeoffs,
            "after the player leaves upward/left the hopper resumes hopping")
        if (phase==2) self.lost_target_takeoffs=self.takeoffs
        array_push(self.course_log,{frame:self.frames,player_phase:phase,x:actor.x,y:actor.y,
            state:actor.state,hop_phase:actor.hop_phase,air_route:actor.air_navigation_active,
            was_airborne:actor.was_airborne,takeoffs:self.takeoffs,landings:self.landings,attacks:self.attacks})
        show_debug_message("FOREST_HOP_PHASE "+json_stringify(self.course_log[array_length(self.course_log)-1]))
        self.pending_shot="course-"+string(self.frames)
    }
    self.last_player_phase=phase;self.last_phase=actor.hop_phase;self.last_state=actor.state
    if (self.frames<1800) return;
    funForestSmokeAssert(self.takeoffs>=12 and self.landings>=12 and self.attacks>=2,"repeated course includes real jumps, landings and attacks")
    var file=file_text_open_write(self.output_directory+"course-states.json")
    file_text_write_string(file,json_stringify(self.course_log));file_text_close(file)
    show_debug_message("FOREST_HOP_PASS repeated 1800-frame course takeoffs="+string(self.takeoffs)
        +" landings="+string(self.landings)+" attacks="+string(self.attacks))
    self.stage=3;self.frames=0;self.pending_shot="course-complete"
}

/// Runs the focused lifecycle regressions before a rendered thirty-second movement course.
function funHopLifecycleSmokeStep() {
    instance_activate_all()
    self.frames+=1
    if (instance_exists(oPauseMenu)) oPauseMenu.paused=false
    if (self.stage==0) {
        if (self.frames<60) return;
        funOpenLevel(31);self.stage=1;self.frames=0;return;
    }
    if (self.stage==1) {
        if (self.frames<30) return;
        funHopLifecycleEdgeCases()
        funHopLifecycleBlockedTakeoff()
        funHopLifecycleStartCourse()
        return;
    }
    if (self.stage==2) funHopLifecycleCourseStep()
    if (self.stage==3 and self.frames>=2) {
        show_debug_message("FOREST_HOP_PASS completed")
        game_end()
    }
}
