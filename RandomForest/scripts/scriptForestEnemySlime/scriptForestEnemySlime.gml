/// Reconciles the hop with actual support, including edge landings and blocked takeoffs.
function funForestSlimeResolveGroundContact(grounded) {
    if (!grounded) {
        self.was_airborne=true
        self.air_was_airborne=true
        return;
    }
    if (!self.was_airborne and !self.air_navigation_active) return;
    var flew=self.air_was_airborne or !self.air_navigation_active
    funEnemyCancelAirMovement()
    self.was_airborne=false
    if (flew) {
        self.landed=true
        self.vertical_decision_counter=max(self.vertical_decision_counter,30)
        funForestEnemyPlayLandingSound()
        return;
    }
    // No physical lift-off happened; keep any current attack, then retry movement normally.
    self.hop_phase="none"
    self.hop_clock=0
    self.turn_cooldown=12
    if (self.state=="move") funForestEnemyState("idle")
}

/// Leaves three pixels of clearance below the ordinary hop's 39-pixel rise.
function funForestSlimePatrolDropLimit(impulse) {
    return 36
}

/// Uses the real body integrator without animation, audio or navigation side effects.
function funForestSlimeSimulateHop(move_direction,impulse,air_speed,ignore_frames,max_distance) {
    var start_x=self.x,start_y=self.y,flew=false
    self.current_yspeed=impulse
    for (var frame=0;frame<48;++frame) {
        self.current_xspeed=move_direction*min(air_speed,max(0,max_distance-abs(self.x-start_x)))
        var ignoring=frame<ignore_frames
        var supported=funEnemyCollidesWithSolid(self.x,self.y+1,self.y,1,ignoring)
        // The integrator reads only this counter; restore it together with the body after prediction.
        self.drop_through_counter=ignoring ? 1 : 0
        if (!funForestEnemyMoveBody(supported,true)) return undefined
        var grounded=self.current_yspeed==0 and funEnemyOnGroundAt(self.x,self.y)
        if (!grounded) flew=true
        if (grounded and flew) {
            if (abs(self.x-start_x)<=.01 and abs(self.y-start_y)<=.01) return undefined
            return {landing_x:self.x,landing_y:self.y,initial_yspeed:impulse,
                air_speed:air_speed,ignore_jump_thru_frames:ignore_frames,move_direction:move_direction}
        }
        if (self.x<0 or self.x>room_width or self.y<0 or self.y>room_height) return undefined
    }
    return undefined
}

/// Plans with the future facing, then restores every body field touched by prediction.
function funForestSlimeHopCandidate(move_direction,pursue_player,short_hop=false) {
    var target_y=self.bbox_bottom
    if (pursue_player and self.sees_player) target_y=oPlayer.bbox_bottom
    var dropping=pursue_player and self.sees_player and target_y>self.bbox_bottom+12
        and instance_place(self.x,self.y+1,oJumpThru)!=noone
    var impulse=dropping ? 0 : -5.4
    var ignore_frames=dropping ? 8 : 0
    var saved_x=self.x,saved_y=self.y,saved_xspeed=self.current_xspeed,saved_yspeed=self.current_yspeed
    var saved_scale=self.image_xscale,saved_drop=self.drop_through_counter
    self.image_xscale=move_direction*abs(saved_scale)
    var candidate=funForestSlimeSimulateHop(move_direction,impulse,short_hop ? .4 : 1.2,
        ignore_frames,short_hop ? 12 : room_width)
    self.x=saved_x;self.y=saved_y
    self.current_xspeed=saved_xspeed;self.current_yspeed=saved_yspeed
    self.image_xscale=saved_scale;self.drop_through_counter=saved_drop
    if (candidate==undefined or !funEnemyAirCandidateFitsTarget(candidate,target_y<self.bbox_bottom-8)) return undefined
    if (!self.sees_player and candidate.landing_y-self.y>funForestSlimePatrolDropLimit(impulse)+.001) return undefined
    return candidate
}

/// Prefers useful travel or ascent, keeping tiny safe moves when no longer route exists.
function funForestSlimeChooseHop(move_direction) {
    var fallback=undefined
    for (var n=0;n<4;++n) {
        var forward=n mod 2==0
        var candidate=funForestSlimeHopCandidate(forward ? move_direction : -move_direction,forward,n>=2)
        if (candidate==undefined) continue
        if (fallback==undefined) fallback=candidate
        // A blocked hop toward a wall must not hide a full retreat in the other direction.
        if (abs(candidate.landing_x-self.x)>=12-.001 or self.y-candidate.landing_y>1) return candidate
    }
    return fallback
}

/// Starts a requested validated hop; explicit callers retain their chosen direction and distance.
function funForestSlimeStartHop(move_direction,pursue_player=true,short_hop=false) {
    return funForestSlimeCommitHop(funForestSlimeHopCandidate(move_direction,pursue_player,short_hop))
}

/// Commits one accepted hop using the unchanged preparation, flight and landing physics.
function funForestSlimeCommitHop(candidate) {
    if (candidate==undefined) return false
    var move_direction=candidate.move_direction
    var dropping=candidate.ignore_jump_thru_frames>0
    self.hop_candidate=candidate
    self.hop_phase=dropping ? "flight" : "prepare"
    self.hop_clock=0
    self.current_direction=move_direction
    self.image_xscale=move_direction*abs(self.image_xscale)
    funForestEnemyState("move")
    self.image_speed=0
    if (dropping) {
        funEnemyStartAirAction(candidate,candidate.initial_yspeed,candidate.air_speed,candidate.ignore_jump_thru_frames)
        self.was_airborne=true
    }
    return true
}

/// Predicts whether the spine ring can meet the player at release, including a landing meanwhile.
function funForestSlimeWantsAttack() {
    if (!self.sees_player or self.attack_cooldown>0) return false
    var delay=12
    var target_x=oPlayer.x+clamp(oPlayer.current_xspeed,-oPlayer.step_xspeed,oPlayer.step_xspeed)*delay
    var future_x=self.x+self.current_xspeed*delay
    var future_y=self.y+self.current_yspeed*delay+.5*self.gravitation*sqr(delay)
    if (self.air_navigation_active and self.current_yspeed>=0) future_y=min(future_y,self.air_target_y)
    if (funEnemyOnGroundAt(self.x,self.y)) future_y=self.y
    return abs(target_x-future_x)<40 and future_y>=oPlayer.bbox_top and future_y-10<=oPlayer.bbox_bottom
}

/// Drives one complete hop by physics; animation poses cannot create an extra jump.
function funForestSlimeStep() {
    if (self.hop_phase=="none" and !funEnemyOnGroundAt(self.x,self.y)) {
        funForestEnemyState("move")
        self.image_speed=0
        self.hop_phase="flight"
        self.hop_clock=0
        self.was_airborne=true
    }
    if (self.hop_phase=="none") {
        self.current_xspeed=0
        if (funForestSlimeWantsAttack()) { funForestEnemyBeginAttack();return; }
        if (self.turn_cooldown>0) { funForestEnemyMoveGround();return; }
        var move_direction=self.sees_player ? sign(oPlayer.x-self.x) : self.current_direction
        if (move_direction==0) move_direction=self.current_direction
        if (!funForestSlimeCommitHop(funForestSlimeChooseHop(move_direction))) {
            self.turn_cooldown=12
            funForestEnemyMoveGround()
            return;
        }
    }
    self.hop_clock+=1
    if (self.hop_phase=="prepare") {
        self.image_index=min(3,floor((self.hop_clock-1)/2))
        funForestEnemyMoveGround()
        if (self.hop_clock>=8) {
            funEnemyStartAirAction(self.hop_candidate,self.hop_candidate.initial_yspeed,self.hop_candidate.air_speed,self.hop_candidate.ignore_jump_thru_frames)
            self.was_airborne=true
            self.hop_phase="flight"
            self.hop_clock=0
        }
        return;
    }
    if (self.hop_phase=="flight") {
        if (self.current_yspeed<0) self.image_index=min(7,4+floor((1-self.current_yspeed/-5.4)*4))
        else self.image_index=self.current_yspeed<1 ? 8 : 9
        if (self.current_yspeed>=0 and funForestSlimeWantsAttack()) { funForestEnemyBeginAttack();return; }
        funForestEnemyMoveGround()
        if (self.landed) { self.hop_phase="land";self.hop_clock=0;self.image_index=10;self.current_xspeed=0 }
        return;
    }
    self.current_xspeed=0
    self.image_index=10+min(2,floor(self.hop_clock*3/8))
    funForestEnemyMoveGround()
    if (self.hop_clock>=8) {
        self.hop_phase="none"
        funForestEnemyState("idle")
    }
}
