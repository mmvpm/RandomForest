// update counters
self.timeout_counter = max(0, self.timeout_counter - 1)
self.diagonal_countdown_counter = max(0, self.diagonal_countdown_counter - 1)

// read inputs
var left = keyboard_check(global.key_arrow_left)
var right = keyboard_check(global.key_arrow_right)
var up = keyboard_check(global.key_arrow_up)
var down = keyboard_check(global.key_arrow_down)
var tap_released = keyboard_check_released(global.key_tap_attack)

// handle exit
if (tap_released or self.timeout_counter == 0) {
	instance_activate_all()

	var tap_sword = instance_create_depth(self.x, self.y, self.depth, oPlayerTapSword)
	tap_sword.current_angle = self.current_angle
	tap_sword.image_angle   = self.current_angle
	tap_sword.shift_of_player_y = self.shift_of_player_y

	var dx = 0
	if (self.current_angle == 0 || self.current_angle == 45 || self.current_angle == 315) {
		dx = 1
	} else if (self.current_angle == 135 || self.current_angle == 180 || self.current_angle == 225) {
		dx = -1
	}
	if (dx != 0) {
		oPlayer.image_xscale = dx * abs(oPlayer.image_xscale)
	}

	instance_destroy()
}

// change angle
var dx = right - left
var dy = up - down
var next_angle = -1
if (dx ==  0 and dy ==  0) {} // nothing
if (dx ==  1 and dy ==  0) next_angle = 0
if (dx ==  1 and dy ==  1) next_angle = 45
if (dx ==  0 and dy ==  1) next_angle = 90
if (dx == -1 and dy ==  1) next_angle = 135
if (dx == -1 and dy ==  0) next_angle = 180
if (dx == -1 and dy == -1) next_angle = 225
if (dx ==  0 and dy == -1) next_angle = 270
if (dx ==  1 and dy == -1) next_angle = 315

if (next_angle != -1) { // angle was changed
	if (next_angle % 10 == 5) { // diagonal
		self.current_angle = next_angle
		self.diagonal_countdown_counter = self.diagonal_countdown
	}
	else { // not diagonal
		if (self.diagonal_countdown_counter == 0) {
			self.current_angle = next_angle
		}
		else {
			// nothing: user accidentally released the key
		}
	}
}