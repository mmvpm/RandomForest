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
self.max_health = 5
self.health = self.max_health

// react
self.react_animation_ended = false

// move
self.step_xspeed = 1
self.current_xspeed = 0
self.current_yspeed = 0
self.gravitation = 0.5

self.vision_radius = 120 // in pixels
self.current_direction = 1 // or -1

// attack
self.damage = 1
self.attack_radius = 30 // in pixels
self.attack_animation_ended = false
self.sword_created = false

// hurt
self.hurt_countdown = 0.5 * 60 // seconds * fps
self.hurt_countdown_counter = 0

self.future_damage = 0
self.hurt_animation_ended = false

// die
self.die_animation_ended = false