/// Integrates only body position and velocity; prediction can reject hazards at each substep.
function funForestEnemyMoveBody(supported,check_danger=false) {
    // Do not oscillate between a fractional fall and floor snapping while already supported.
    if (supported and self.current_yspeed>=0) self.current_yspeed=0
    else self.current_yspeed=min(6,self.current_yspeed+self.gravitation)
    var count=max(1,ceil(abs(self.current_yspeed)))
    var dy=self.current_yspeed/count
    for (var i=0;i<count;++i) {
        if (funEnemyCollidesWithSolid(self.x,self.y+dy,self.y,dy,dy<0 or self.drop_through_counter>0)) {
            var support=instance_place(self.x,self.y+dy,oSolid)
            if (dy>0 and support!=noone and self.bbox_bottom<=support.bbox_top+1) {
                // Resolve the collider's bottom edge to the surface, independent of fractional rounding.
                var bottom=(sprite_get_bbox_bottom(self.mask_index)+1-sprite_get_yoffset(self.mask_index))*abs(self.image_yscale)
                self.y=support.bbox_top-bottom
            }
            self.current_yspeed=0
            break
        }
        self.y+=dy
        if (check_danger and funEnemyPositionIsDangerous(self.x,self.y)) return false
    }
    count=max(1,ceil(abs(self.current_xspeed)))
    var dx=self.current_xspeed/count
    for (var i=0;i<count;++i) {
        if (funEnemyCollidesWithSolid(self.x+dx,self.y,self.y,0,false)) {
            self.current_xspeed=0
            break
        }
        self.x+=dx
        if (check_danger and funEnemyPositionIsDangerous(self.x,self.y)) return false
    }
    return !check_danger or !funEnemyPositionIsDangerous(self.x,self.y)
}

/// Moves the fixed collider in short steps, keeping old enemy physics untouched.
function funForestEnemyMoveGround() {
    self.landed=false
    var supported=funEnemyCollidesWithSolid(self.x,self.y+1,self.y,1,self.drop_through_counter>0)
    if (!supported or self.current_yspeed<0) self.was_airborne=true
    if (self.air_navigation_active) funEnemyApplyAirMovement()
    funForestEnemyMoveBody(supported)
    var grounded=self.current_yspeed==0 and funEnemyOnGroundAt(self.x,self.y)
    if (self.forest_kind=="slime") funForestSlimeResolveGroundContact(grounded)
    else {
        funEnemyFinishAirMovement()
        if (grounded and self.was_airborne and !self.air_navigation_active) {
            self.was_airborne=false
            self.landed=true
        }
    }
    funEnemyStompKnockbackUpdate()
}

/// Converts one local rectangle to world coordinates, including mirrored and scaled poses.
function funForestEnemyWorldRect(rect) {
    var left=self.x+rect[0]*self.image_xscale
    var right=self.x+rect[2]*self.image_xscale
    var top=self.y+rect[1]*self.image_yscale
    var bottom=self.y+rect[3]*self.image_yscale
    return [min(left,right),min(top,bottom),max(left,right),max(top,bottom)]
}

/// Tests a small world rectangle against the player's ordinary body bounds.
function funForestRectHitsPlayer(rect) {
    return instance_exists(oPlayer) and rect[0]<=oPlayer.bbox_right and rect[2]>oPlayer.bbox_left
        and rect[1]<=oPlayer.bbox_bottom and rect[3]>oPlayer.bbox_top
}

/// Samples an authored light offset continuously, without using collision bounds.
function funForestEnemyLightHeight() {
    var poses=funForestEnemyPoseFrames(self.sprite_index)
    var index=clamp(self.image_index,0,array_length(poses)-1)
    var first=floor(index),last=min(first+1,array_length(poses)-1)
    return lerp(poses[first].light_y,poses[last].light_y,frac(index))
}
