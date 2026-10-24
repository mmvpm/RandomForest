/// Suspends gameplay between render passes while atmosphere and aim controls remain active.
function funAimFreezeWorld() {
    instance_deactivate_all(true)
    instance_activate_object(oAlwaysDraw)
    instance_activate_object(oAmbientSystem)
    instance_activate_object(oParallax)
    instance_activate_object(oWeatherAudio)
}

/// Records the active scene and holds sprite clocks without changing logical poses or physics.
function funAimFreezeBegin() {
    self.frozen_instances = []
    self.frozen_animations = []
    self.freeze_active = true
    with (all) {
        if (id == other.id) continue
        array_push(other.frozen_instances, id)
        if (sprite_index != -1 and object_index != oAlwaysDraw and !object_is_ancestor(object_index,oAlwaysDraw)) {
            array_push(other.frozen_animations, {instance:id, speed:image_speed})
            image_speed = 0
        }
    }
    funAimFreezeWorld()
}

/// Enables only the recorded scene for drawing; its Step, alarm and collision events stay suspended.
function funAimFreezeDrawBegin() {
    if (!self.freeze_active) return;
    for (var i = 0; i < array_length(self.frozen_instances); ++i)
        instance_activate_object(self.frozen_instances[i])
}

/// Restores the original animation clocks once on throw, cancellation or room cleanup.
function funAimFreezeEnd() {
    if (!self.freeze_active) return;
    self.freeze_active = false
    instance_activate_all()
    for (var i = 0; i < array_length(self.frozen_animations); ++i) {
        var entry = self.frozen_animations[i]
        if (instance_exists(entry.instance)) entry.instance.image_speed = entry.speed
    }
}
