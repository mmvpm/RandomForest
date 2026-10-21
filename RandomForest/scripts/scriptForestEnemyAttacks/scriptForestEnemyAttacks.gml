/// Adds a single reusable rectangle for the authored attack, without a pixel-mask sprite.
function funForestEnemyMakeStrike() {
    instance_create_depth(self.x,self.y,self.depth-1,oForestStrike,{owner_id:self.id,
        sprite_index:sForestStrikeCollision,mask_index:sForestStrikeCollision,image_speed:0,damage:1})
}

/// Separates explosive round bombs from the guard's narrow, non-explosive wooden thorns.
function funForestEnemyFireSeed() {
    var move_direction=sign(self.image_xscale)
    var px=self.x+self.image_xscale*12,py=self.y-12*self.image_yscale
    var bomb=self.forest_kind=="barrel"
    var projectile_gravity=bomb ? .10 : 0
    var vx=move_direction*(bomb ? 2.1 : 2.7)
    var flight=abs(self.attack_target_x-px)/abs(vx)
    flight=bomb ? clamp(flight,16,72) : max(16,flight)
    var vy=clamp((self.attack_target_y-py-.5*projectile_gravity*sqr(flight))/flight,-4.6,2.6)
    var seed=instance_create_depth(px,py,self.depth-1,oForestProjectile,{owner_id:self.id,
        current_xspeed:vx,current_yspeed:vy,seed_gravity:projectile_gravity,seed_blast:bomb,image_xscale:move_direction})
    if (!bomb) {
        seed.life=180
        seed.sprite_index=sBarkGuardThorn
        seed.mask_index=sBarkGuardThorn
        seed.image_xscale=1
        seed.image_angle=point_direction(0,0,vx,vy)
    }
}

/// Tests line of damage against hit_solid rock, allowing ordinary one-way platforms.
function funForestEnemyLineClear(px,py) {
    if (!instance_exists(oPlayer)) return false
    var target_y=(oPlayer.bbox_top+oPlayer.bbox_bottom)*.5
    var first=collision_line(px,py,oPlayer.x,target_y,oSolid,false,true)
    if (first==noone) return true
    if (first.object_index!=oJumpThru) return false
    var blockers=ds_list_create()
    var count=collision_line_list(px,py,oPlayer.x,target_y,oSolid,false,true,blockers,false)
    var clear=true
    for (var i=0;i<count;++i) if (blockers[| i].object_index!=oJumpThru) { clear=false;break }
    ds_list_destroy(blockers)
    return clear
}

/// Updates one cheap world-space attack rectangle in the owner's current active pose.
function funForestStrikeStep() {
    if (!instance_exists(self.owner_id) or self.owner_id.state!="attack") { instance_destroy();return; }
    var owner=self.owner_id
    var rect=[]
    with (owner) {
        var local=funForestEnemyPose().strike
        if (array_length(local)==4) rect=funForestEnemyWorldRect(local)
    }
    if (array_length(rect)!=4) { self.can_damage_player=false;return; }
    self.x=rect[0];self.y=rect[1]
    self.image_xscale=max(1,rect[2]-rect[0])
    self.image_yscale=max(1,rect[3]-rect[1])
    var first=0
    with (owner) first=funForestEnemyActiveStart()
    self.can_damage_player=owner.image_index>=first and owner.image_index<first+3
        and funForestEnemyLineClear(owner.x,owner.y-8*abs(owner.image_yscale))
}

/// Returns the shared first damage frame for tooling and battle checks.
function funForestEnemyStrikeFirst(owner) {
    var first=0
    with (owner) first=funForestEnemyActiveStart()
    return first
}

/// Keeps the round blast's damage inexpensive and excludes the empty corners of its broad rectangle.
function funForestBlastHitsPlayer() {
    if (!instance_exists(oPlayer)) return false
    var center_y=self.y-8
    var near_x=clamp(self.x,oPlayer.bbox_left,oPlayer.bbox_right)
    var near_y=clamp(center_y,oPlayer.bbox_top,oPlayer.bbox_bottom)
    return sqr(near_x-self.x)+sqr(near_y-center_y)<=400 and funForestEnemyLineClear(self.x,center_y)
}

/// Starts one impact explosion immediately, preserving the floor surface or wall contact position.
function funForestProjectileDetonate() {
    if (self.blasting) return;
    self.blasting=true
    self.life=16
    self.current_xspeed=0
    self.current_yspeed=0
    if (self.ground_impact) self.y=self.impact_y
    self.sprite_index=sForestSeedBurst
    self.mask_index=sForestBlastCollision
    self.image_index=0
    self.image_speed=1
    self.image_angle=0
    self.image_alpha=1
    self.can_damage_player=funForestBlastHitsPlayer()
    funForestSeedPlayBurstSound()
}

/// Sweeps projectiles against solids and detonates bombs on the first contact, without a fuse.
function funForestProjectileStep() {
    self.life-=1
    if (self.life<=0) { instance_destroy();return; }
    if (place_meeting(self.x,self.y,oPlayerSword) or funPlayerStompWaveDamage()!=noone) { instance_destroy();return; }
    if (self.blasting) {
        self.can_damage_player=self.life>8 and funForestBlastHitsPlayer()
        return;
    }
    self.current_yspeed+=self.seed_gravity
    var count=max(1,ceil(max(abs(self.current_xspeed),abs(self.current_yspeed))))
    for (var i=0;i<count;++i) {
        var nx=self.x+self.current_xspeed/count,ny=self.y+self.current_yspeed/count
        var hit_solid=instance_place(nx,ny,oSolid)
        if (hit_solid!=noone) {
            if (!self.seed_blast) { instance_destroy();return; }
            if (self.current_yspeed>=0 and self.bbox_bottom<=hit_solid.bbox_top+1) {
                self.ground_impact=true
                self.impact_y=hit_solid.bbox_top
                self.y=hit_solid.bbox_top-(self.bbox_bottom-self.y)-1
            }
            funForestProjectileDetonate()
            return;
        }
        self.x=nx;self.y=ny
    }
}
