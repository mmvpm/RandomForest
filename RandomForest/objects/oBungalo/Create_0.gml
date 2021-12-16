// states
enum bungalo_states {
	idle,
	walk,
	move,
	attack,
	hurt,
	die
}

self.state = bungalo_states.idle
self.state_changed = true

// health
self.max_health = 6
self.health = self.max_health

// idle
self.idle_countdown = 2 * 60 // seconds * fps
self.idle_countdown_counter = 0

// walk
self.step_xspeed = 0.7
self.current_xspeed = 0
self.current_yspeed = 0
self.gravitation = 0.5

self.current_direction = 1 // or -1

// move
self.vision_radius = 160 // in pixels

// attack
self.damage = 1
self.attack_frame = 4
self.attack_radius = 40 // in pixels
self.attack_animation_ended = false
self.sword_created = false
self.sword_destroyed = false

// defense from tap-sword by attack
self.defense_activated = false

// hurt
self.hurt_countdown = 0.5 * 60 // seconds * fps
self.hurt_countdown_counter = 0

self.future_damage = 0
self.hurt_animation_ended = false

// die
self.die_animation_ended = false