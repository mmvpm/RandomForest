/// Starts the save-free regression run; the baseline uses only the identical stress stage.
function funThemeSmokeCreate() {
    self.stage=0;self.frames=0;self.pending_shot="";self.target=noone
    self.seen="";self.landings=0;self.samples=[];self.sampling=false
    self.previous_light=noone;self.max_light_delta=0
    self.capture_name=""
    global.forest_sound_events=[];global.forest_cpu_us=0
    global.is_debug=false;global.is_fullscreen=false;global.is_training_completed=true
    global.current_level=31
    global.time_records=array_create(41,100000)
    global.enemy_clear_records=array_create(41,false)
    global.flawless_records=array_create(41,false)
    global.orange_firefly_records=array_create(41,false)
    global.sfx_enabled=true
    funApplySfxSetting()
    window_set_fullscreen(false);window_set_size(960,540)
    var scenes=global.black_room_config.scenes
    for (var i=0;i<array_length(scenes);++i) variable_struct_set(global.black_room_seen,scenes[i].id,true)
}

/// Stops on a concrete invariant instead of claiming success from a crash-free battle alone.
function funForestSmokeAssert(condition,label) {
    if (!condition) { show_debug_message("FOREST_REVISION_FAIL "+label);show_error("FOREST_REVISION_FAIL "+label,true) }
}

/// Moves the fixture's player without reading external keyboard input or recording real progress.
function funRevisionPlayer(px,py) {
    oPlayer.x=px;oPlayer.y=py;oPlayer.current_xspeed=0;oPlayer.current_yspeed=0
    oPlayer.health=100;oPlayer.max_health=100
}

/// Removes only disposable test actors and starts the next independent scenario.
function funRevisionClear() {
    with (oForestEnemy) instance_destroy()
    with (oForestProjectile) instance_destroy()
    with (oForestStrike) instance_destroy()
    self.frames=0;self.seen=""
}

/// Applies a real sword instance immediately so airborne position can be checked before another step.
function funRevisionHit(target,damage) {
    var sword=instance_create_depth(target.x,target.y,-1,oPlayerSword,{damage:damage,xscale_factor:1,yscale_factor:1})
    target.hurt_countdown_counter=0
    with (target) funForestEnemyTakeDamage()
    instance_destroy(sword)
}

/// Covers both surviving and fatal hits during ascent, at the apex and during descent.
function funRevisionAirHitCases() {
    var velocities=[-5,0,4]
    for (var i=0;i<3;++i) for (var fatal=0;fatal<=1;++fatal) {
        var actor=instance_create_depth(300,300,0,oResinSlime,{visual_theme:"night"})
        actor.current_yspeed=velocities[i];actor.was_airborne=true
        with (actor) funForestEnemyState("move")
        actor.image_index=9
        if (i==0) actor.image_index=4
        else if (i==1) actor.image_index=8
        funRevisionHit(actor,fatal ? 9 : 2)
        funForestSmokeAssert(actor.y==300 and actor.current_yspeed==max(0,velocities[i]),"air hit keeps height and downward momentum in all three phases")
        funForestSmokeAssert(actor.is_dead==bool(fatal),"fatal air hit disables combat immediately")
        instance_destroy(actor)
    }
    show_debug_message("FOREST_REVISION_PASS six ascent/apex/descent hurt and death cases")
}

/// Creates the same sixty-actor mixed load for old and revised movement/collision implementations.
function funRevisionStartBenchmark() {
    funRevisionClear()
    var objects=[oResinSlime,oBarkBomber,oForestBat,oBarkGuard,oRootReaper,oRootMaw]
    for (var i=0;i<60;++i) {
        var actor=instance_create_depth(180+(i mod 10)*36,336-(i div 10)*44,0,objects[i mod 6],{visual_theme:"night"})
        actor.health=10000
    }
    funRevisionPlayer(340,336)
    self.stage=20;self.samples=[];self.frames=0
}

/// Covers ordinary hops, interrupted flight, air attacks, wake, predictive attacks and floor-aligned blasts.
function funThemeSmokeStep() {
    instance_activate_all()
    self.frames+=1
    self.capture_name=""
    if (self.frames mod 2==0) {
        var clip=""
        if (self.stage==2 and self.frames<=64) clip="hop"
        if (self.stage==8 and self.frames<=90) clip="reaper"
        if (self.stage==13 and self.frames<=90) clip="bat"
        if (clip!="") self.capture_name="motion-"+clip+"-"+string(1000+self.frames)
    }
    if (instance_exists(oPauseMenu)) oPauseMenu.paused=false
    if (self.stage>=21) { funFeedbackStep();return; }
    if (instance_exists(oPlayer)) { oPlayer.health=100;oPlayer.max_health=100 }
    if (self.stage==0) {
        if (self.frames<60) return;
        funOpenLevel(31);self.stage=1;self.frames=0;return;
    }
    if (self.stage==1) {
        if (self.frames<60) return;
        if (global.forest_benchmark_only) { funRevisionStartBenchmark();return; }
        if (global.forest_feedback_only) { funFeedbackStart();return; }
        funRevisionClear()
        self.target=instance_create_depth(300,336,0,oResinSlime,{visual_theme:"night"})
        self.target.vision_radius=0;self.target.rear_vision_radius=0
        funRevisionPlayer(260,336)
        self.stage=2;self.landings=0;self.min_y=336;return;
    }
    if (self.stage==2) {
        var t=self.target
        funRevisionPlayer(260,336)
        self.min_y=min(self.min_y,t.y)
        if (t.landed) self.landings+=1
        if (self.frames==35 or self.frames==65) self.pending_shot="hop-"+string(self.frames)
        if (self.frames<100) return;
        funForestSmokeAssert(self.landings>=2 and self.min_y<300,"patrol uses real full-height hops and lands repeatedly")
        show_debug_message("FOREST_REVISION_PASS patrol hops landings="+string(self.landings)+" apex="+string(self.min_y))
        self.stage=3;self.frames=0;return;
    }
    if (self.stage==3) {
        var t=self.target
        if (self.frames mod 60==0) show_debug_message("FOREST_DIAG hurt-wait state="+t.state+" hop="+t.hop_phase+" xy="+string(t.x)+","+string(t.y)+" vy="+string(t.current_yspeed)+" airborne="+string(t.air_navigation_active))
        funForestSmokeAssert(self.frames<240,"second patrol takeoff before hurt")
        if (t.current_yspeed>=-1) return;
        var height=t.y
        funRevisionHit(t,2)
        funForestSmokeAssert(abs(t.y-height)<.001 and t.current_yspeed>=0 and abs(t.current_xspeed)==2,"air hurt preserves height, cancels rise and pushes sideways")
        self.stage=4;self.frames=0;return;
    }
    if (self.stage==4) {
        var t=self.target
        if (self.frames mod 30==0) show_debug_message("FOREST_DIAG hurt xy="+string(t.x)+","+string(t.y)+" vy="+string(t.current_yspeed)+" frame="+string(t.image_index)+" finished="+string(t.animation_finished)+" speed="+string(t.image_speed))
        if (self.frames==5 or self.frames==15) self.pending_shot="hurt-fall-"+string(self.frames)
        if (t.state=="hurt") { funForestSmokeAssert(self.frames<100,"hurt reaches the floor");return; }
        if (t.current_yspeed>=-1) return;
        var height=t.y
        funRevisionHit(t,9)
        funForestSmokeAssert(t.is_dead and t.state=="fall_dead" and abs(t.y-height)<.001,"fatal air hit falls before death")
        self.stage=5;self.frames=0;return;
    }
    if (self.stage==5) {
        if (self.frames<120) return;
        funForestSmokeAssert(!instance_exists(self.target),"fatal hopper lands and finishes death")
        show_debug_message("FOREST_REVISION_PASS rising hurt and fatal fall preserve height, then land and finish death")
        funRevisionAirHitCases()
        funRevisionClear()
        self.target=instance_create_depth(300,336,0,oResinSlime,{visual_theme:"night"})
        self.target.attack_cooldown=0
        funRevisionPlayer(360,336)
        self.stage=6;self.saw_air_attack=false;self.saw_air_windup=false;return;
    }
    if (self.stage==6) {
        var t=self.target
        funRevisionPlayer(360,336)
        if (t.state=="windup" and t.was_airborne) self.saw_air_windup=true
        if (t.state=="attack" and t.attack_spawned and t.was_airborne) { self.saw_air_attack=true;self.pending_shot="air-spines" }
        if (self.frames<160) return;
        funForestSmokeAssert(self.saw_air_windup and self.saw_air_attack,"spines are actually released before landing")
        show_debug_message("FOREST_REVISION_PASS airborne spines and uninterrupted landing")
        funRevisionClear()
        self.target=instance_create_depth(260,336,0,oRootReaper)
        self.target.vision_radius=0;self.target.rear_vision_radius=0
        funRevisionPlayer(200,336)
        self.stage=7;self.walked=0;self.saw_sleep=false;return;
    }
    if (self.stage==7) {
        if (self.target.state=="move") self.walked+=1
        if (self.target.state=="sleep") self.saw_sleep=true
        if (self.frames<420) return;
        funForestSmokeAssert(self.walked>=300 and self.saw_sleep,"long reaper patrol then a real sleep interval")
        self.target.vision_radius=220;self.target.rear_vision_radius=220
        self.stage=8;self.frames=0;self.saw_wake=false;return;
    }
    if (self.stage==8) {
        var t=self.target
        funRevisionPlayer(t.x-44,self.frames<90 ? 336 : 314)
        if (t.state=="wake") self.saw_wake=true
        if (t.state=="attack") {
            self.seen+="attack"
            if (t.attack_style=="AttackSweep" and floor(t.image_index)==4) self.pending_shot="reaper-awake-sweep"
            if (t.attack_style=="AttackSlam" and floor(t.image_index)==6) self.pending_shot="reaper-awake-slam"
        }
        if (self.saw_wake and t.state!="sleep") funForestSmokeAssert(t.sprite_index!=sRootReaperIdle,"no sleeping pose beside a visible player")
        if (self.frames<210) return;
        funForestSmokeAssert(self.saw_wake and string_pos("attack",self.seen)>0,"sleeping reaper wakes and counters")
        show_debug_message("FOREST_REVISION_PASS reaper long patrol, wake, awake recovery and fast counter")
        funRevisionClear()
        self.target=instance_create_depth(300,336,0,oBarkGuard,{visual_theme:"night"})
        self.target.attack_cooldown=0
        self.stage=9;self.saw_shot=false;self.saw_melee=false;return;
    }
    if (self.stage==9) {
        var t=self.target
        funRevisionPlayer(self.frames<110 ? 470 : 380,336)
        if (t.state=="attack") {
            if (t.attack_style=="Attack1") self.saw_shot=true
            else { self.saw_melee=true;if (floor(t.image_index)==3) self.pending_shot="guard-night-volley" }
        }
        if (self.frames<240) return;
        funForestSmokeAssert(self.saw_shot and self.saw_melee,"guard shoots only beyond predictive melee range")
        var melee_reach=0
        with (t) melee_reach=funForestGuardMeleeDistance()
        show_debug_message("FOREST_REVISION_PASS guard modes; predictive melee distance="+string(melee_reach))
        funRevisionClear()
        self.target=instance_create_depth(300,336,0,oRootMaw)
        self.stage=10;return;
    }
    if (self.stage==10) {
        var t=self.target
        with (t) { funForestEnemyState("attack");image_index=3;image_speed=0 }
        var head=[]
        with (t) head=funForestEnemyWorldRect(funForestEnemyPose().parts[0])
        funRevisionPlayer((head[0]+head[2])*.5,(head[1]+head[3])*.5+10)
        oPlayer.hurt_countdown_counter=0
        var damage=0
        with (t) damage=funForestMawContactDamage()
        funForestSmokeAssert(damage==2,"active jaw contact is two damage")
        with (oPlayer) funPlayerDetectCriticalState()
        funForestSmokeAssert(oPlayer.future_damage==2,"real player damage resolver does not replace bite with body damage")
        t.bite_cancelled=true
        with (t) damage=funForestMawContactDamage()
        funForestSmokeAssert(damage==1,"body contact is one damage")
        funRevisionPlayer(290,310)
        with (t) damage=funForestMawContactDamage()
        funForestSmokeAssert(damage==0,"empty plant bounding corner is harmless")
        var previous_x=t.x,previous_y=t.y,pose=t.image_index,art=t.sprite_index
        funRevisionHit(t,2)
        funForestSmokeAssert(t.health==3 and t.x==previous_x and t.y==previous_y and t.sprite_index==art and t.image_index==pose,"plant hurt only blinks and does not recoil")
        show_debug_message("FOREST_REVISION_PASS plant three regions, one/two damage, no empty-corner hits, no recoil")
        self.pending_shot="maw-parts-blink"
        t.image_speed=1
        self.stage=11;self.frames=0;return;
    }
    if (self.stage==11) {
        funRevisionPlayer(340,336)
        if (self.frames<90) return;
        funRevisionClear()
        funRevisionPlayer(360,336)
        self.target=instance_create_depth(300,300,-1,oForestProjectile,{owner_id:noone,current_xspeed:0,current_yspeed:0,seed_gravity:.1,seed_blast:true})
        self.wall_bomb=instance_create_depth(497,326,-1,oForestProjectile,{owner_id:noone,current_xspeed:3,current_yspeed:0,seed_gravity:.1,seed_blast:true})
        self.wall_height=0;self.saw_wall_blast=false
        self.stage=12;self.saw_blast=false;return;
    }
    if (self.stage==12) {
        if (instance_exists(self.target) and self.target.blasting) {
            funForestSmokeAssert(self.target.ground_impact and self.target.y==336,"blast origin is the actual floor contact")
            self.saw_blast=true
            if (floor(self.target.image_index)==2) self.pending_shot="bomb-floor-contact"
        }
        if (instance_exists(self.wall_bomb)) {
            if (self.wall_bomb.blasting) {
                if (!self.saw_wall_blast) self.wall_height=self.wall_bomb.y
                funForestSmokeAssert(!self.wall_bomb.ground_impact and abs(self.wall_bomb.y-self.wall_height)<.001,"wall blast stays at its collision instead of snapping to ground")
                self.saw_wall_blast=true
            }
        }
        if (self.frames<100) return;
        funForestSmokeAssert(self.saw_blast and self.saw_wall_blast,"both floor and wall blasts exercised")
        show_debug_message("FOREST_REVISION_PASS floor blast touches surface; wall blast stays at impact")
        funRevisionClear()
        self.target=instance_create_depth(1512,252,0,oForestBat)
        funForestSmokeAssert(self.target.state=="hang","test level has a real ceiling perch")
        funRevisionPlayer(1470,316)
        self.stage=13;self.saw_wake=false;self.saw_dive=false;self.saw_hover=false;return;
    }
    if (self.stage==13) {
        var t=self.target
        if (self.frames>1) funForestSmokeAssert(point_distance(t.x,t.y,self.bat_x,self.bat_y)<=6.01,"bat motion has no pose-change teleport")
        self.bat_x=t.x;self.bat_y=t.y
        funRevisionPlayer(1470,316)
        if (t.state=="hang") self.pending_shot="bat-ceiling"
        if (t.state=="wake" or t.state=="drop") { self.saw_wake=true;self.pending_shot="bat-release" }
        if (t.state=="attack") { self.saw_dive=true;self.pending_shot="bat-fast-dive" }
        if (t.has_awoken) funForestSmokeAssert(t.state!="hang","bat never reattaches to ceiling")
        if (self.frames<210) return;
        funForestSmokeAssert(self.saw_wake and self.saw_dive,"bat detaches, closes vertically and dives")
        show_debug_message("FOREST_REVISION_PASS ceiling wake and short six-pixel-per-step committed dive")
        funForestSmokeCheckSelectedAudio()
        t.x=300;t.y=322;t.health=3
        funRevisionHit(t,1)
        self.stage=16;self.frames=0;return;
    }
    if (self.stage==16) {
        funRevisionPlayer(360,336)
        if (self.frames<80) return;
        funForestSmokeAssert(self.target.y<325 and !self.target.is_dead,"hurt bat takes off again without getting trapped by wing clearance at the floor")
        show_debug_message("FOREST_REVISION_PASS grounded hurt bat regains wing clearance without teleporting")
        self.target.x=300;self.target.y=280;self.target.retreat_required=false
        self.bat_return_x=self.target.x
        self.bat_player_x=self.target.x+100
        self.target.home_x=self.target.x-241;self.target.home_y=self.target.y
        self.target.attack_cooldown=999
        with (self.target) funForestEnemyState("idle")
        self.stage=17;self.frames=0;return;
    }
    if (self.stage==17) {
        funRevisionPlayer(self.bat_player_x,336)
        if (self.frames<60) return;
        funForestSmokeAssert(self.target.sees_player and !self.target.returning_home and self.target.x>self.bat_return_x,"visible player takes priority over a distant home; xy="+string(self.target.x)+","+string(self.target.y)+" state="+self.target.state)
        show_debug_message("FOREST_REVISION_PASS bat pursues beyond its old territory without a forced return")
        funRevisionClear()
        self.target=instance_create_depth(480,336,0,oResinSlime,{visual_theme:"night"})
        funRevisionPlayer(516,312)
        self.stage=14;self.saw_raised=false;return;
    }
    if (self.stage==14) {
        funRevisionPlayer(516,312)
        if (self.target.y<=313 and !self.target.was_airborne) self.saw_raised=true
        if (self.frames<180) return;
        funForestSmokeAssert(self.saw_raised,"same hopper physics reaches the raised 24-pixel obstacle")
        show_debug_message("FOREST_REVISION_PASS unified hop reaches raised platform")
        funRevisionClear()
        // A six-pixel gap specifically catches the old evening skin's narrow changing masks.
        self.legacy_floor_a=instance_create_depth(240,252,0,oSolid,{sprite_index:sForestStrikeCollision,mask_index:sForestStrikeCollision,image_xscale:60,image_yscale:12})
        self.legacy_floor_b=instance_create_depth(306,252,0,oSolid,{sprite_index:sForestStrikeCollision,mask_index:sForestStrikeCollision,image_xscale:120,image_yscale:12})
        self.skeleton=instance_create_depth(270,252,0,oSkeleton)
        global.playing_level=21
        self.stage=15;self.saw_skeleton_jump=false;self.saw_skeleton_attack=false;return;
    }
    if (self.stage==15) {
        funRevisionPlayer(360,252)
        funForestSmokeAssert(self.skeleton.mask_index==sSkeletonIdle,"evening skin retains original skeleton collider in every state")
        if (self.skeleton.air_navigation_active) self.saw_skeleton_jump=true
        if (self.skeleton.state==skeleton_states.attack) self.saw_skeleton_attack=true
        if (self.frames<240) return;
        funForestSmokeAssert(self.saw_skeleton_jump and self.saw_skeleton_attack,"evening skeleton crosses small gap and attacks; jump="+string(self.saw_skeleton_jump)+" attack="+string(self.saw_skeleton_attack)+" xy="+string(self.skeleton.x)+","+string(self.skeleton.y))
        show_debug_message("FOREST_REVISION_PASS evening skeleton original collider, six-pixel gap jump and attack")
        self.pending_shot="evening-skeleton-original-physics"
        instance_destroy(self.skeleton)
        instance_destroy(self.legacy_floor_a);instance_destroy(self.legacy_floor_b)
        global.playing_level=31
        self.drop_platform=instance_create_depth(240,252,0,oJumpThru,{sprite_index:sForestStrikeCollision,mask_index:sForestStrikeCollision,image_xscale:180,image_yscale:6})
        self.drop_floor=instance_create_depth(240,312,0,oSolid,{sprite_index:sForestStrikeCollision,mask_index:sForestStrikeCollision,image_xscale:180,image_yscale:12})
        self.target=instance_create_depth(300,252,0,oResinSlime,{visual_theme:"night"})
        self.target.attack_cooldown=999
        funRevisionPlayer(300,312)
        self.stage=18;self.frames=0;self.saw_drop=false;self.saw_drop_land=false;return;
    }
    if (self.stage==18) {
        funRevisionPlayer(300,312)
        if (self.target.y>260) self.saw_drop=true
        if (self.target.y>=311 and self.target.y<=313 and !self.target.was_airborne) self.saw_drop_land=true
        if (self.frames<100) return;
        funForestSmokeAssert(self.saw_drop and self.saw_drop_land,"unified hopper still drops through one-way platforms toward a lower target")
        show_debug_message("FOREST_REVISION_PASS one-way platform drop uses the same falling and landing physics")
        funRevisionClear()
        instance_destroy(self.drop_platform);instance_destroy(self.drop_floor)
        funFeedbackStart();return;
    }
    if (self.stage==20) {
        funRevisionPlayer(340,336)
        self.sampling=self.frames>120
        if (self.frames<480) return;
        self.sampling=false
        array_sort(self.samples,true)
        var count=array_length(self.samples),total=0
        for (var i=0;i<count;++i) total+=self.samples[i]
        funForestSmokeAssert(total>0,"CPU samples include actual actor steps")
        show_debug_message("FOREST_BENCH baseline="+string(global.forest_benchmark_only)+" actors=60 samples="+string(count)+" mean_us="+string(total/max(1,count))+" p50_us="+string(self.samples[floor(count*.5)])+" p95_us="+string(self.samples[floor(count*.95)]))
        show_debug_message("FOREST_LIGHT max_pose_offset_delta="+string(self.max_light_delta))
        show_debug_message("FOREST_REVISION_PASS completed")
        game_end()
    }
}

/// Saves real rendered frames and measures all actor steps after the frame has finished.
function funThemeSmokeDraw() {
    if (!global.forest_benchmark_only and instance_exists(self.target) and variable_instance_exists(self.target,"forest_kind")
        and self.target.forest_kind!="maw" and instance_exists(self.target.glow_id)) {
        var actor=self.target,glow=actor.glow_id
        funForestSmokeAssert(abs(glow.x-actor.x)<.01,"halo follows continuous body root")
        var offset=glow.y-actor.y
        if (self.previous_light==actor.id) {
            self.max_light_delta=max(self.max_light_delta,abs(offset-self.last_light_offset))
            funForestSmokeAssert(abs(offset-self.last_light_offset)<6,"halo pose offset has no high/low jump")
        }
        self.previous_light=actor.id;self.last_light_offset=offset
    }
    if (self.sampling) array_push(self.samples,global.forest_cpu_us)
    if (self.pending_shot!="") { screen_save(self.output_directory+self.pending_shot+".png");self.pending_shot="" }
    if (self.capture_name!="") screen_save(self.output_directory+self.capture_name+".png")
    global.forest_cpu_us=0
}
