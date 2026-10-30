/// Creates the standard soft aura on the same Bloom layer as the existing enemies.
function funForestEnemyCreateGlow() {
    self.glow_id=instance_create_layer(self.x,self.y,"Bloom",oForestEnemyBloom)
    self.glow_id.following=self.id
}

/// Removes the owned aura immediately on death or room cleanup.
function funForestEnemyRemoveGlow() {
    if (variable_instance_exists(self,"glow_id") and instance_exists(self.glow_id)) instance_destroy(self.glow_id)
    self.glow_id=noone
}

/// Follows the body; the elongated plant uses a baked silhouette for each current pose.
function funForestEnemyGlowStep() {
    if (!instance_exists(self.following) or self.following.is_dead) { instance_destroy(); return; }
    var owner=self.following
    self.image_alpha=.7*owner.image_alpha
    self.visual_theme=owner.visual_theme
    if (owner.forest_kind=="maw") {
        self.x=owner.x
        self.y=owner.y
        self.sprite_index=asset_get_index(sprite_get_name(owner.sprite_index)+"Bloom")
        self.image_index=owner.image_index
        self.image_speed=0
        self.image_xscale=owner.image_xscale
        self.image_yscale=owner.image_yscale
        return;
    }
    self.x=owner.x
    var height=-10
    with (owner) height=funForestEnemyLightHeight()
    // Follow world motion immediately; only the small pose offset eases between animations.
    if (!variable_instance_exists(self,"body_height")) self.body_height=height
    self.body_height=lerp(self.body_height,height,.4)
    self.y=owner.y+self.body_height*abs(owner.image_yscale)
    self.sprite_index=sSkeletonBloom
    if (owner.forest_kind=="slime") self.sprite_index=sSlimeBloom
    if (owner.forest_kind=="sweeper") self.sprite_index=sBungaloBloom
    // Match the existing halos without letting their radius grow to include a weapon's full reach.
    self.image_xscale=abs(owner.image_xscale)*.7
    self.image_yscale=abs(owner.image_yscale)*.7
}

/// Reuses approved day/evening/night/morning halo artwork with its existing alpha gradient.
function funForestEnemyGlowDraw() {
    if (!instance_exists(self.following) or self.following.is_dead) return;
    funDrawThemedSelf(1,1,self.following.visual_theme)
}
