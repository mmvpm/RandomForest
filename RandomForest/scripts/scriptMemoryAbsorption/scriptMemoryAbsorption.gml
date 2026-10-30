// Particle side in game pixels; count scales inversely with its area.
#macro MEMORY_PARTICLE_SIZE 1
#macro MEMORY_PARTICLE_ALPHA 0.3
// Wisp opacity at 48 particles; burst density is normalized below.
#macro MEMORY_PARTICLE_GLOW_ALPHA 0.1
// Glow scale is independent of the core size and transparency.
#macro MEMORY_PARTICLE_GLOW_SCALE 0.4

/// Adds deterministic sparks without consuming the gameplay random stream.
function funMemoryAbsorptionBurst(x_pos, y_pos) {
    var count = round(12 * power(2 / MEMORY_PARTICLE_SIZE, 2))
    for (var i = 0; i < count; ++i) {
        var spark_angle = i * 360 / count + 13
        var spark_speed = 0.7 + (i mod 4) * 0.25
        array_push(self.memory_particles, {x: x_pos, y: y_pos,
            vx: lengthdir_x(spark_speed, spark_angle), vy: lengthdir_y(spark_speed, spark_angle), age: 0,
            glow_weight: 48 / count, glow_angle: i * 137.508, glow_stretch: 0.55 + (i mod 7) * 0.075})
    }
}

/// Follows the current player position; particles never own collection progress.
function funMemoryAbsorptionStep() {
    var player = instance_find(oPlayer, 0)
    var target_alive = instance_exists(player)
    if (target_alive) target_alive = player.visible and player.state != player_states.die
    for (var i = array_length(self.memory_particles) - 1; i >= 0; --i) {
        var particle = self.memory_particles[i]
        particle.age++
        if (!target_alive) particle.age = max(48, particle.age)
        if (particle.age <= 6) {
            particle.x += particle.vx
            particle.y += particle.vy
        } else if (target_alive) {
            var target_x = (player.bbox_left + player.bbox_right) * 0.5
            var target_y = (player.bbox_top + player.bbox_bottom) * 0.5
            var attraction = 0.06 + particle.age * 0.003
            particle.x = lerp(particle.x, target_x, attraction)
            particle.y = lerp(particle.y, target_y, attraction)
            if (point_distance(particle.x, particle.y, target_x, target_y) < 2) particle.age = 60
        }
        if (particle.age >= 60) array_delete(self.memory_particles, i, 1)
    }
}

/// Draws faint cores and independently sized additive halos that merge into a cloud.
function funMemoryAbsorptionDraw() {
    for (var i = 0; i < array_length(self.memory_particles); ++i) {
        var particle = self.memory_particles[i]
        var fade = min(1, particle.age / 6) * min(1, (60 - particle.age) / 12)
        var glow_scale = MEMORY_PARTICLE_GLOW_SCALE
        gpu_set_blendmode(bm_add)
        draw_set_alpha(1)
        draw_sprite_ext(sCoinBloom, 0, particle.x + particle.vx * 3, particle.y + particle.vy * 3,
            glow_scale * particle.glow_stretch, glow_scale * 0.45, particle.glow_angle,
            ORANGE_FIREFLY_GLOW_COLOUR, fade * MEMORY_PARTICLE_GLOW_ALPHA * particle.glow_weight)
        gpu_set_blendmode(bm_normal)
        draw_set_color(ORANGE_FIREFLY_COLOUR)
        draw_set_alpha(fade * MEMORY_PARTICLE_ALPHA)
        draw_rectangle(round(particle.x), round(particle.y), round(particle.x) + MEMORY_PARTICLE_SIZE - 1,
            round(particle.y) + MEMORY_PARTICLE_SIZE - 1, false)
    }
    draw_set_alpha(1)
    draw_set_color(c_white)
}
