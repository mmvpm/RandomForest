// update counters
self.flight_time_counter = max(0, self.flight_time_counter - 1)
if (self.current_speed > 0 and self.flight_time_counter == 0) {
	funPlayerTapSwordDestroy()
	return
}

// Bungalo defense
if (place_meeting(self.x, self.y, oBungaloSword)) {
	funPlayerTapSwordDestroy()
	return
}

// on landing
if (self.current_speed == 0 and !self.was_shake_effect) {
	funCameraShake(1)
	audio_play_sound(soundTapSwordLanding, 1, false)
	self.was_shake_effect = true
}

// change angle
// self.image_angle = self.current_angle

if (!self.effect_created) {
	self.effect_created = true
	var r = 16
	var ang = self.current_angle * pi / 180.0
	var effect = instance_create_depth(
		self.x + r * cos(ang), 
		self.y - r * sin(ang), 
		self.depth - 1, oAirBurst
	)
	effect.image_angle = self.current_angle
}

// no movement
if (self.current_speed == 0) {
	return
}
// now self.current_speed > 0

// current_angle
var cos_angle = cos(self.current_angle / 180 * pi)
var sin_angle = -sin(self.current_angle / 180 * pi)

// moving by X and Y together
var success_move = false
for (var speed_i = self.current_speed; speed_i > 0; --speed_i) {
	var new_x = self.x + speed_i * cos_angle
	var new_y = self.y + speed_i * sin_angle
	if (!place_meeting(new_x, new_y, oSolid)) {
		success_move = true
		self.y = new_y
		self.x = new_x
		break
	}
}
if (!success_move) {
	self.current_speed = 0
}

// collide with enemy
var nearest_enemy = instance_place(self.x, self.y, oEnemy)
var nearest_slime = instance_place(self.x, self.y, oSlime)
if (nearest_enemy != noone and nearest_enemy != nearest_slime) {
	if (self.collide_with_enemy_counter == 0) {
		funPlayerTapSwordDestroy()
		return
	}
	self.collide_with_enemy_counter--
}
if (nearest_enemy != noone and !global.hit_vs_tap_text_shown) {
	var text = instance_create_depth(self.x, self.y - 20, self.depth - 1, oFadingText)
	text.text = "Удар мечом (X) намного сильнее броска!"
	text.text_size = 14
	text.active_time = 3 * 60 // frames
	text.fading_time = 2 * 60 // frames
	global.hit_vs_tap_text_shown = true
	funSaveGameState()
}