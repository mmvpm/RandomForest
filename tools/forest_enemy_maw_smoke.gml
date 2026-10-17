/// Shoots the real moving child sword at a jaw or stalk pose from either facing.
function funMawSmokeSwordCase(case_index) {
    funRevisionClear()
    with (oPlayerTapSword) instance_destroy()
    var side=case_index mod 2==0 ? -1 : 1
    var states=["idle","attack","recover"]
    var case_state=states[(case_index div 2) mod 3]
    var head=case_index>=6
    var pose=case_state=="attack" ? 3 : (case_state=="recover" ? 2 : 0)
    var region_index=head ? 0 : 1
    funRevisionPlayer(300+side*90,336)
    self.target=instance_create_depth(300,336,0,oRootMaw)
    self.target.image_xscale=side
    self.target.vision_radius=0;self.target.rear_vision_radius=0
    var rect=[]
    with (self.target) {
        funForestEnemyState(case_state)
        image_index=pose
        image_speed=0;state_timer=999
        rect=funForestEnemyWorldRect(funForestEnemyPose().parts[region_index])
    }
    self.shot=instance_create_depth(300+side*80,(rect[1]+rect[3])*.5,-1,oPlayerTapSword,{
        current_angle:side<0 ? 0 : 180,image_angle:side<0 ? 0 : 180,shift_of_player_y:10})
    self.side=side
    self.sword_case=case_index
    self.frames=0
}

/// Empty broad-phase space must not consume the sword, including where another enemy overlaps it.
function funMawSmokeEmptyContact() {
    funRevisionClear()
    self.target=instance_create_depth(300,336,0,oRootMaw)
    var sword=instance_create_depth(324,326,-1,oPlayerTapSword,{current_angle:0,image_angle:0,shift_of_player_y:10})
    var contact=noone
    with (sword) contact=funForestMawFilterSwordContact(other.target)
    funForestSmokeAssert(contact==noone,"empty plant rectangle cannot consume a flying sword")
    var legacy=instance_create_depth(334,336,0,oSlime)
    legacy.image_xscale=1;legacy.image_yscale=1
    with (sword) contact=funForestMawFilterSwordContact(other.target)
    funForestSmokeAssert(contact==legacy,"plant filtering preserves a real overlapping legacy enemy contact; contact="+string(contact)+" expected="+string(legacy))
    with (sword) contact=funForestMawFilterSwordContact(legacy)
    funForestSmokeAssert(contact==legacy,"ordinary enemy contact uses unchanged fast path")
    instance_destroy(legacy);instance_destroy(sword)
    show_debug_message("MAW_PASS empty regions and overlapping legacy enemy contacts")
}

/// Records complete one-shot returns and a death where the rosette shares the body's full lifetime.
function funMawSmokeStep() {
    instance_activate_all()
    self.frames+=1;self.capture_name=""
    if (instance_exists(oPauseMenu)) oPauseMenu.paused=false
    if (self.stage==0) {
        if (self.frames<60) return;
        funOpenLevel(31);self.stage=1;self.frames=0;return;
    }
    if (self.stage==1) {
        if (self.frames<60) return;
        funMawSmokeEmptyContact()
        funMawSmokeSwordCase(0);self.stage=2;return;
    }
    if (self.stage==2) {
        funRevisionPlayer(300+self.side*90,336)
        if (self.frames<25) return;
        funForestSmokeAssert(self.target.health==4,"real flying sword damages jaw/stalk once from either side in idle/attack/recover; case="+string(self.sword_case)+" hp="+string(self.target.health))
        if (self.sword_case<11) { funMawSmokeSwordCase(self.sword_case+1);return; }
        show_debug_message("MAW_PASS 12 actual flying sword hits: both sides, jaw/stalk, idle/attack/recover")
        funRevisionClear()
        self.target=instance_create_depth(300,336,0,oRootMaw)
        self.target.vision_radius=0;self.target.rear_vision_radius=0
        funRevisionPlayer(360,336)
        with (self.target) funForestEnemyBeginAttack()
        self.stage=4;self.frames=0;self.cycles=0;self.last_state="";self.last_pose=0;self.recovery_ticks=0;return;
    }
    if (self.stage==4) {
        funRevisionPlayer(360,336)
        if (self.frames mod 2==0) self.capture_name="maw-cycle-"+string(1000+self.frames)
        var t=self.target,pose=floor(t.image_index)
        if (t.state=="attack" or t.state=="recover") {
            if (self.last_state==t.state) funForestSmokeAssert(pose>=self.last_pose,"one-shot plant pose never wraps back to an earlier frame")
            if (t.state=="recover") self.recovery_ticks+=1
        }
        if (t.state=="idle" and self.last_state=="recover") {
            funForestSmokeAssert(self.last_pose==4 and self.recovery_ticks>=30,"complete return holds its final pose through cooldown")
            self.cycles+=1
            if (self.cycles<3) {
                with (t) funForestEnemyBeginAttack()
                self.recovery_ticks=0
            } else {
                show_debug_message("MAW_PASS three attack/recovery cycles without pose wrap or repeated return")
                funRevisionHit(t,9)
                funForestSmokeAssert(t.state=="dead","lethal hit begins plant death")
                self.stage=5;self.frames=0;return;
            }
        }
        self.last_state=t.state;self.last_pose=floor(t.image_index)
        funForestSmokeAssert(self.frames<320,"three plant attack cycles finish")
        return;
    }
    if (self.stage==5) {
        funRevisionPlayer(360,336)
        if (self.frames mod 2==0) self.capture_name="maw-death-"+string(1000+self.frames)
        if (instance_exists(self.target)) {
            funForestSmokeAssert(self.target.state=="dead" and self.target.image_alpha==1,"whole plant remains visible during native death")
        } else funForestSmokeAssert(self.frames>=50,"plant death is not removed early")
        if (self.frames<60) return;
        funForestSmokeAssert(!instance_exists(self.target),"rosette and stalk leave together at animation completion")
        show_debug_message("MAW_PASS complete plant death lifetime")
        show_debug_message("MAW_PASS completed")
        game_end()
    }
}
