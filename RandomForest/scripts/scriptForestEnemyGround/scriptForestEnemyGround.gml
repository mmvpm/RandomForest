/// Computes the close attack's reach and the distance a running player can close before it hits.
function funForestGuardMeleeDistance() {
    var poses=funForestEnemyPoseFrames(sBarkGuardAttack2)
    var reach=0
    for (var i=3;i<=5;++i) reach=max(reach,poses[i].strike[2]*abs(self.image_xscale))
    return reach+(oPlayer.bbox_right-oPlayer.bbox_left+1)*.5+oPlayer.step_xspeed*18+4
}

/// Checks a readable anticipatory attack against current motion and the visible player's height.
function funForestEnemyWantsGroundAttack() {
    if (!self.sees_player or self.attack_cooldown>0) return false
    var dx=oPlayer.x-self.x
    var height=abs(oPlayer.bbox_bottom-self.bbox_bottom)
    switch (self.forest_kind) {
        case "maw": return abs(dx)<45+max(0,-sign(dx)*oPlayer.current_xspeed)*25 and height<28
        case "barrel": return abs(dx)<174 and height<64
        case "guard": return abs(dx)<self.vision_radius and height<32
        case "sweeper":
            var closing=max(0,-sign(dx)*oPlayer.current_xspeed)
            return abs(dx)<68+closing*12 and height<48
    }
    return false
}

/// Runs long patrol stretches, wakes the reaper on sight, and pursues without timer-driven fidgeting.
function funForestEnemyGroundStep() {
    if (self.forest_kind=="maw") {
        if (funForestEnemyWantsGroundAttack()) funForestEnemyBeginAttack()
        return;
    }
    if (self.forest_kind=="sweeper") {
        if (self.state=="sleep") {
            self.current_xspeed=0
            self.state_timer-=1
            if (self.sees_player or self.state_timer<=0) { funForestEnemyState("wake");self.state_timer=18 }
            funForestEnemyMoveGround()
            return;
        }
        if (self.state=="wake") {
            self.state_timer-=1
            self.image_speed=0
            self.image_index=min(5,(18-self.state_timer)/3)
            self.current_xspeed=0
            funForestEnemyMoveGround()
            if (self.state_timer<=0) { self.patrol_timer=360;funForestEnemyState("idle") }
            return;
        }
        if (self.alert_timer<=0) {
            self.patrol_timer-=1
            if (self.patrol_timer<=0) { funForestEnemyState("sleep");self.state_timer=180;self.current_xspeed=0;return; }
        }
    }
    if (self.air_navigation_active) { funForestEnemyMoveGround();return; }
    if (funForestEnemyWantsGroundAttack()) { funForestEnemyBeginAttack();return; }
    var move_direction=self.current_direction
    var walking=false
    if (self.sees_player) {
        var dx=oPlayer.x-self.x
        if (abs(dx)>4) move_direction=sign(dx)
        self.current_direction=move_direction
        // Ranged guards hold their ground between close attacks instead of backing up every frame.
        walking=self.forest_kind!="guard" or abs(dx)>funForestGuardMeleeDistance()
        if (walking) walking=funForestEnemyChoosePursuit(move_direction)
    } else {
        walking=funEnemyCanWalk(move_direction)
        if (!walking and self.turn_cooldown<=0) {
            move_direction=-move_direction
            self.current_direction=move_direction
            self.turn_cooldown=12
            walking=funEnemyCanWalk(move_direction)
        }
    }
    var desired=walking ? "move" : "idle"
    if (self.state!=desired) funForestEnemyState(desired)
    self.image_xscale=move_direction*abs(self.image_xscale)
    self.current_xspeed=walking ? move_direction*self.step_xspeed : 0
    funForestEnemyMoveGround()
}

/// Reuses the existing local navigation planner against one stable body rectangle.
function funForestEnemyChoosePursuit(move_direction) {
    if (funEnemyCanPursueStep(move_direction)) return true
    if (self.forest_kind=="barrel") return false
    return funEnemyTryPursuitAction(oPlayer.x,oPlayer.bbox_bottom,-5.4,self.step_xspeed*1.6)
}
