// states
enum slime_states {
	idle,
	move,
	attack,
	hurt,
	die
}

self.state = slime_states.idle
self.state_changed = true

// Every externally created slime is large; children overwrite this with half of the parent scale.
var slime_facing = sign(self.image_xscale)
if (slime_facing == 0) {
	slime_facing = 1
}
var slime_scale = random_range(0.7, 1)
self.image_xscale = slime_facing * slime_scale
self.image_yscale = slime_scale

// health
self.max_health = 3
self.health = self.max_health

// idle
self.idle_countdown = 1 * 60 // seconds * fps
self.idle_countdown_counter = 0

// move
self.step_xspeed = 0.5
self.current_xspeed = 0
self.current_yspeed = 0
self.gravitation = 0.5

self.move_distance = 3 * 60 // seconds * fps
self.current_move_distance = 0
self.current_direction = 1 // or -1
funEnemyInitializeMovement(sSlimeIdle)

// attack
self.damage = 1
self.can_damage_player = true
self.is_dead = false
self.vision_radius = 120 // forward, in pixels
self.rear_vision_radius = 30 // backward, in pixels
self.vertical_vision_radius = 24 // two platform cells
self.sees_player = false
self.escape_hazard = false
self.slime_air_visual_active = false
self.slime_landing_scale_counter = 0
self.enemy_visual_scale_x = 1
self.enemy_visual_scale_y = 1

// hurt
self.hurt_ximpulse = 0.5
self.hurt_countdown = 0.5 * 60 // seconds * fps
self.hurt_countdown_counter = 0

self.future_damage = 0
self.hurt_animation_ended = false

// die
self.is_splitted = false // by two part (small slimes)
self.die_animation_ended = false

// bloom
var bloom = instance_create_layer(self.x, self.y, "Bloom", oSlimeBloom)
bloom.following = self
