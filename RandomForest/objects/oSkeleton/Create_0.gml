// states
enum skeleton_states {
	idle,
	move
}

self.state = skeleton_states.idle
self.state_changed = true

// health
self.max_health = 5
self.health = self.max_health

// move
self.step_xspeed = 1
self.current_xspeed = 0
self.current_yspeed = 0
self.gravitation = 0.5

self.vision_radius = 120 // in pixels
self.current_direction = 1 // or -1

// attack
self.attack_radius = 12 // in pixels