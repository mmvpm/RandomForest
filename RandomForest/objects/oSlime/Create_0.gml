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
self.damage = 1
self.cooldown = 0.6 * 60 // seconds * fps
self.cooldown_counter = 0
self.vision_radius = 60 // in pixels

// hurt
self.hurt_ximpulse = 0.5
self.hurt_countdown = 0.5 * 60 // seconds * fps
self.hurt_countdown_counter = 0

self.future_damage = 0
self.hurt_animation_ended = false

// die
self.is_splitted = false // by two part (small slimes)
self.die_animation_ended = false

// lighting
self.light = funCreateLight(
	self.x, self.y - 0.5 * self.sprite_height, 
	oSlimeLight
)

self.eye_pos_x_idle = [6, 6, 6, 6]
self.eye_pos_y_idle = [-8, -8, -8, -8]

self.eye_pos_x_move = [8, 7, 7, 8]
self.eye_pos_y_move = [-6, -6, -7, -6]

self.eye_pos_x_hurt = [3, 3, 5]
self.eye_pos_y_hurt = [-6, -5, -7]

self.eye_pos_x_die = [4, 9, 10, noone, noone]
self.eye_pos_y_die = [-7, -7, -8, noone, noone]

self.eye_pos_x_attack = [5, 10, 10, 3, 10]
self.eye_pos_y_attack = [-5, -14, -7, -5, -6]

self.eye_light = funCreateLight(
	self.x, self.y, 
	oSlimeEyeLight
)