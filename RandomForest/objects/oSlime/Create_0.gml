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

// attack
self.cooldown = 0.6 * 60 // seconds * fps
self.cooldown_counter = 0
self.attack_animation_ended = false

// hurt
self.hurt_ximpulse = 2
self.hurt_animation_ended = false

// die
self.die_animation_ended = false