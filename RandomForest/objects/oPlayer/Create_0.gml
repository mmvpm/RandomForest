/// @description


enum player_states {
	idle,
	move,
	jump,
	fall,
	attack,
	hurt,
	die
}

self.state = player_states.idle
self.state_changed = true


self.step_xspeed = 2
self.jump_impulse = -6
self.gravitation = 0.5

self.current_xspeed = 0
self.current_yspeed = 0
