/// Refines the plant's cheap outer rectangle into its jaw and two stalk sections.
function funForestMawContactDamage() {
    if (self.is_dead) return 0
    if (!funForestEnemyLineClear(self.x,self.y-16)) return 0
    var regions=funForestEnemyPose().parts
    if (self.state=="attack" and !self.bite_cancelled and self.image_index>=1 and self.image_index<4
        and funForestRectHitsPlayer(funForestEnemyWorldRect(regions[0]))) return 2
    for (var i=0;i<array_length(regions);++i) {
        if (funForestRectHitsPlayer(funForestEnemyWorldRect(regions[i]))) return 1
    }
    return 0
}

/// Finds an actual hit on the plant rather than a hit in the empty corner of its outer bounds.
function funForestMawDamageInstance(object) {
    var regions=funForestEnemyPose().parts
    for (var i=0;i<array_length(regions);++i) {
        var r=funForestEnemyWorldRect(regions[i])
        var hit=collision_rectangle(r[0],r[1],r[2]-1,r[3]-1,object,false,true)
        if (hit!=noone) return hit
    }
    return noone
}

/// Counts sword contacts on the actual plant, preserving ordinary enemy contacts in overlapping groups.
function funForestMawFilterSwordContact(first_enemy) {
    if (first_enemy==noone or first_enemy.object_index!=oRootMaw) return first_enemy
    var sword=self.id,contact=noone
    var enemies=ds_list_create()
    var count=instance_place_list(self.x,self.y,oEnemy,enemies,false)
    for (var i=0;i<count;++i) {
        var enemy=enemies[| i]
        if (enemy.object_index==oRootMaw) {
            var body_hit=noone
            with (enemy) body_hit=funForestMawDamageInstance(sword)
            if (body_hit==noone) continue
        }
        contact=enemy
        break
    }
    ds_list_destroy(enemies)
    return contact
}

/// Tests wave crossings against the same three regions, recording each owner only once.
function funForestMawWaveDamage() {
    var regions=funForestEnemyPose().parts
    for (var i=0;i<instance_number(oPlayerStompWave);++i) {
        var wave=instance_find(oPlayerStompWave,i)
        if (ds_list_find_index(wave.hit_enemies,self.id)!=-1) continue
        for (var j=0;j<array_length(regions);++j) {
            var r=funForestEnemyWorldRect(regions[j])
            var near=point_distance(wave.x,wave.y,clamp(wave.x,r[0],r[2]),clamp(wave.y,r[1],r[3]))
            var far=point_distance(0,0,max(abs(wave.x-r[0]),abs(wave.x-r[2])),max(abs(wave.y-r[1]),abs(wave.y-r[3])))
            if (near<=wave.radius and far>=wave.previous_radius) {
                ds_list_add(wave.hit_enemies,self.id)
                return wave
            }
        }
    }
    return noone
}
