/// Plans the same supported ballistic hop for patrol, pursuit and raised terrain.
function funForestSlimeStartHop(move_direction) {
    var target_x=self.x+move_direction*36,target_y=self.bbox_bottom
    if (self.sees_player) { target_x=oPlayer.x;target_y=oPlayer.bbox_bottom }
    var dropping=self.sees_player and target_y>self.bbox_bottom+12 and instance_place(self.x,self.y+1,oJumpThru)!=noone
    var impulse=dropping ? 0 : -5.4
    var ignore_frames=dropping ? 8 : 0
    var candidate=funEnemyBuildAirCandidate(move_direction,impulse,1.2,ignore_frames,target_x,target_y)
    if (candidate==undefined or !funEnemyAirCandidateFitsTarget(candidate,target_y<self.bbox_bottom-8)) return false
    self.hop_candidate=candidate
    self.hop_phase=dropping ? "flight" : "prepare"
    self.hop_clock=0
    self.current_direction=move_direction
    self.image_xscale=move_direction*abs(self.image_xscale)
    funForestEnemyState("move")
    self.image_speed=0
    if (dropping) {
        funEnemyStartAirAction(candidate,0,1.2,8)
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
        var move_direction=self.sees_player ? sign(oPlayer.x-self.x) : self.current_direction
        if (move_direction==0) move_direction=self.current_direction
        if (!funForestSlimeStartHop(move_direction)) {
            if (!self.sees_player and self.turn_cooldown<=0) {
                self.current_direction=-move_direction
                self.turn_cooldown=12
            }
            funForestEnemyMoveGround()
            return;
        }
    }
    self.hop_clock+=1
    if (self.hop_phase=="prepare") {
        self.image_index=min(3,floor((self.hop_clock-1)/2))
        funForestEnemyMoveGround()
        if (self.hop_clock>=8) {
            funEnemyStartAirAction(self.hop_candidate,self.hop_candidate.initial_yspeed,1.2,self.hop_candidate.ignore_jump_thru_frames)
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
