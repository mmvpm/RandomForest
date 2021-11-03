// states
enum player_states {
	idle,
	move,
	prejump,
	jump,
	fall,
	attack,
	hurt,
	die
}

self.state = player_states.idle
self.state_changed = true

// health
self.max_health = 5
self.health = self.max_health

// buffers
self.jump_buffer_max = 5 // frames
self.jump_buffer_counter = 0

self.coyote_buffer_max = 5 // frames
self.coyote_buffer_counter = 0

// idle
self.blink_probability = 50 // 50% per second (< 1% per frame)
self.wondering_probability = 20
self.idle_animation_ended = true // blink or wondering

// jump & move
self.step_xspeed = 2
self.jump_impulse = -6.5
self.xfriction = 0.9
self.gravitation = 0.5

self.current_xspeed = 0
self.current_yspeed = 0

// fall
self.fall_buffer_max = 3 // frames
self.fall_buffer_counter = 0 // for jump-thru platforms

// attack
self.cooldown = 0.7 * 60 // seconds * fps
self.cooldown_counter = 0
self.has_sword = true
self.sword_destroyed = false
self.attack_animation_ended = false

// tap attack
self.tap_attack_countdown = 1 * 60 // seconds * fps
self.tap_attack_countdown_counter = 0

// hurt
self.hurt_ximpulse = 2
self.hurt_yimpulse = 4

self.hurt_countdown = 0.6 * 60 // temporary invulnerability (including hurt animation ~ 20 frames)
self.hurt_countdown_counter = 0

self.future_damage = 0
self.direction_to_enemy = undefined
self.hurt_animation_ended = false

// die
self.die_animation_ended = false