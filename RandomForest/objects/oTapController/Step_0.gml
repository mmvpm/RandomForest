// update counters
self.timeout_counter = max(0, self.timeout_counter - 1)

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
	
	instance_destroy()
}

// change angle
var dx = right - left
var dy = up - down
if (dx ==  0 and dy ==  0) {} // nothing
if (dx ==  1 and dy ==  0) self.current_angle = 0
if (dx ==  1 and dy ==  1) self.current_angle = 45
if (dx ==  0 and dy ==  1) self.current_angle = 90
if (dx == -1 and dy ==  1) self.current_angle = 135
if (dx == -1 and dy ==  0) self.current_angle = 180
if (dx == -1 and dy == -1) self.current_angle = 225
if (dx ==  0 and dy == -1) self.current_angle = 270
if (dx ==  1 and dy == -1) self.current_angle = 315