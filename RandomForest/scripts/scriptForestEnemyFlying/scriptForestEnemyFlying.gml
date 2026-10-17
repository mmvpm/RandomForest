/// Sweeps the fixed body in short steps; cosmetic wing tips cannot stop a dive above the floor.
function funForestEnemyFlyMove(dx,dy) {
    var count=max(1,ceil(max(abs(dx),abs(dy)))),clear=true
    for (var i=0;i<count;++i) {
        if (!funForestEnemyFlightBlocked(self.x+dx/count,self.y)) self.x+=dx/count
        else clear=false
        if (!funForestEnemyFlightBlocked(self.x,self.y+dy/count)) self.y+=dy/count
        else clear=false
    }
    return clear
}

/// Uses the same small body for flight collision and receiving damage.
function funForestEnemyFlightBlocked(px,py) {
    return place_meeting(px,py,oSolid)
}

/// Prefers room for open wings when choosing a hovering or retreat position.
function funForestBatWingsBlocked(px,py) {
    return collision_rectangle(px-18,py-14,px+18,py+14,oSolid,false,true)!=noone
}

/// Checks a complete body-width flight segment before committing a dive or choosing a new perch.
function funForestBatPathClear(ax,ay,bx,by) {
    var count=max(1,ceil(point_distance(ax,ay,bx,by)/2))
    for (var i=1;i<=count;++i) {
        if (funForestEnemyFlightBlocked(lerp(ax,bx,i/count),lerp(ay,by,i/count))) return false
    }
    return true
}

/// Starts under a real ceiling when one exists; old open-air placements remain usable.
function funForestBatFindCeiling() {
    for (var distance=16;distance<=96;++distance) {
        var ceiling=collision_point(self.x,self.y-distance,oSolid,false,true)
        if (ceiling==noone or ceiling.object_index==oJumpThru) continue
        var surface=ceiling.bbox_bottom+1
        if (collision_rectangle(self.x-8,surface,self.x+8,surface+32,oSolid,false,true)!=noone) break
        self.x=round(self.x)
        self.y=surface+6
        self.ceiling_y=surface
        self.home_y=surface+40
        funForestEnemyState("hang")
        return;
    }
    self.has_awoken=true
    // Open-air markers can be placed near a floor; choose wing clearance before the first drawn frame.
    if (funForestBatWingsBlocked(self.x,self.y)) {
        for (var lift=1;lift<=48;++lift) {
            if (!funForestBatWingsBlocked(self.x,self.y-lift)) { self.y-=lift;self.home_y=self.y;break }
        }
    }
}

/// Releases the first perch once, with the selected quiet cloth cue and real downward motion.
function funForestBatDetach() {
    if (self.has_awoken) return;
    self.has_awoken=true
    self.current_yspeed=.5
    funForestEnemyPlayWakeSound()
}

/// Falls against the fixed body while hurt rather than snapping between hanging and flying roots.
function funForestBatHurtStep() {
    funForestEnemyMoveGround()
}

/// Folds movement to the small body while taking off after hurt, until the wings have room again.
function funForestBatClearanceStep() {
    if (!funForestBatWingsBlocked(self.x,self.y)) return false
    self.current_yspeed=0
    if (!funEnemyCollidesWithSolid(self.x,self.y-2,self.y,-2,true)) self.y-=2
    else {
        var move_direction=sign(self.home_x-self.x)
        if (move_direction==0) move_direction=sign(self.image_xscale)
        if (!funEnemyCollidesWithSolid(self.x+move_direction*2,self.y,self.y,0,false)) self.x+=move_direction*2
    }
    return true
}

/// Chooses a bounded upward/away retreat, shortening it only where actual terrain blocks the body.
function funForestBatChooseRetreat() {
    var away=sign(self.x-oPlayer.x)
    if (away==0) away=-sign(self.image_xscale)
    var base=point_direction(0,0,away*32,-32)
    var turns=[0,-45,45,-90,90,180]
    var distance=random_range(40,64),best=-1
    self.retreat_target_x=self.x;self.retreat_target_y=self.y
    for (var n=0;n<array_length(turns);++n) {
        var angle=base+turns[n],length=0
        for (var step=2;step<=distance;step+=2) {
            var px=self.x+lengthdir_x(step,angle),py=self.y+lengthdir_y(step,angle)
            if (funForestEnemyFlightBlocked(px,py)) break
            length=step
        }
        var tx=self.x+lengthdir_x(length,angle),ty=self.y+lengthdir_y(length,angle)
        var preference=length+(funForestBatWingsBlocked(tx,ty) ? 0 : 8)-n*2
        if (preference>best) { best=preference;self.retreat_target_x=tx;self.retreat_target_y=ty }
    }
}

/// Requires genuine separation after every dive, including a dive interrupted by a wall.
function funForestBatStartRetreat() {
    funForestEnemyState("retreat")
    self.state_timer=0
    self.attack_cooldown=30
    self.retreat_required=true
    self.retreat_start_x=self.x;self.retreat_start_y=self.y
    funForestBatChooseRetreat()
}

/// Moves during recovery instead of hovering in place and immediately repeating the same attack.
function funForestBatRetreatStep() {
    self.state_timer+=1
    var dx=self.retreat_target_x-self.x,dy=self.retreat_target_y-self.y
    var distance=point_distance(0,0,dx,dy)
    var clear=funForestEnemyFlyMove(dx/max(1,distance)*min(2.4,distance),dy/max(1,distance)*min(2.4,distance))
    if (point_distance(self.x,self.y,self.retreat_start_x,self.retreat_start_y)>=24) self.retreat_required=false
    if ((distance<=2.4 or self.state_timer>=36) and !self.retreat_required) { funForestEnemyState("idle");return; }
    if (!clear or distance<=2.4) funForestBatChooseRetreat()
}

/// Chooses a clear side or overhead approach, keeping wing room at the destination only.
function funForestBatApproach(player_y) {
    var side=sign(self.x-oPlayer.x)
    if (side==0) side=-sign(self.image_xscale)
    var targets=[[oPlayer.x+side*48,player_y-32],[oPlayer.x,player_y-56],[oPlayer.x-side*48,player_y-32]]
    var target_x=self.x,target_y=self.y-24,best=1000000
    for (var i=0;i<array_length(targets);++i) {
        var px=targets[i][0],py=targets[i][1]
        if (funForestBatWingsBlocked(px,py) or !funForestBatPathClear(self.x,self.y,px,py)
            or !funForestBatPathClear(px,py,oPlayer.x,player_y)) continue
        var distance=point_distance(self.x,self.y,px,py)
        if (distance<best) { best=distance;target_x=px;target_y=py }
    }
    var dx=target_x-self.x,dy=target_y-self.y,length=max(1,point_distance(0,0,dx,dy))
    if (!funForestEnemyFlyMove(dx/length*min(2,length),dy/length*min(2,length))) {
        funForestEnemyFlyMove(side*2,-1)
    }
}

/// Hangs, wakes once, closes on both axes, then commits a short fast dive that can be dodged.
function funForestEnemyBatStep() {
    if (self.state=="hang") {
        if (self.sees_player) { funForestEnemyState("wake");self.state_timer=18;self.image_speed=0 }
        return;
    }
    if (self.state=="wake") {
        self.state_timer-=1
        self.image_index=min(5,(18-self.state_timer)/3)
        if (self.state_timer<=6) {
            funForestBatDetach()
            funForestEnemyMoveGround()
        }
        if (self.state_timer<=0) { funForestEnemyState("drop");self.image_speed=0;self.image_index=5 }
        return;
    }
    if (self.state=="drop") {
        funForestEnemyMoveGround()
        if (self.y>=self.ceiling_y+28 or self.landed) { self.current_yspeed=0;funForestEnemyState("idle") }
        return;
    }
    if (self.state=="windup" or self.state=="attack") {
        if (self.state=="windup" and self.state_timer>3) {
            self.attack_target_x=oPlayer.x+clamp(oPlayer.current_xspeed*6,-12,12)
            self.attack_target_y=(oPlayer.bbox_top+oPlayer.bbox_bottom)*.5
        }
        funForestEnemyAttackStep()
        return;
    }
    if (self.state=="retreat") { funForestBatRetreatStep();return; }
    if (self.retreat_required) { funForestEnemyState("retreat");self.state_timer=0;funForestBatChooseRetreat();return; }
    if (self.sees_player) {
        self.returning_home=false
        var player_y=(oPlayer.bbox_top+oPlayer.bbox_bottom)*.5
        var distance=point_distance(self.x,self.y,oPlayer.x,player_y)
        if (self.attack_cooldown<=0 and distance<=72 and self.y<=player_y-12
            and funForestBatPathClear(self.x,self.y,oPlayer.x,player_y)) { funForestEnemyBeginAttack();return; }
        funForestBatApproach(player_y)
        if (abs(oPlayer.x-self.x)>4) self.image_xscale=sign(oPlayer.x-self.x)*abs(self.image_xscale)
        return;
    }
    // A lost target permits a gradual return; a visible player always takes priority over home.
    self.returning_home=true
    if (funForestBatClearanceStep()) return;
    var target_x=self.home_x+sin(self.ambient_clock/900)*12
    var target_y=self.home_y+sin(self.ambient_clock/650)*4
    funForestEnemyFlyMove(clamp(target_x-self.x,-1.4,1.4),clamp(target_y-self.y,-1.2,1.2))
}
