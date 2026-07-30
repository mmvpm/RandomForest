// states
enum skeleton_states {
	idle,
	react,
	move,
	attack,
	hurt,
	die
}

self.state = skeleton_states.idle
self.state_changed = true

// health
self.max_health = 4
self.health = self.max_health

// react
self.react_animation_ended = false
self.react_needed = true

// move
self.step_xspeed = 1
self.current_xspeed = 0
self.current_yspeed = 0
self.gravitation = 0.5

self.vision_radius = 160 // forward, in pixels
self.rear_vision_radius = 80 // backward, in pixels
self.vertical_vision_radius = 48 // four platform cells
self.sees_player = false
self.current_direction = 1 // or -1
funEnemyInitializeMovement(sSkeletonIdle)

// attack
self.damage = 1
self.can_damage_player = true
self.is_dead = false
self.attack_radius = 30 // in pixels
self.attack_animation_ended = false
self.sword_created = false
self.sword_id = noone
self.escape_hazard = false

// hurt
self.hurt_countdown = 0.5 * 60 // seconds * fps
self.hurt_countdown_counter = 0

self.future_damage = 0
self.hurt_animation_ended = false

// die
self.die_animation_ended = false

// bloom
var bloom = instance_create_layer(self.x, self.y, "Bloom", oSkeletonBloom)
bloom.following = self
