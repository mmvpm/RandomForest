// screenshot
self.screenshot = sprite_create_from_surface(
	application_surface,
	0, 0, room_width, room_height,
	0, 0, 0, 0
)

// last empty place for player
// self.shift_of_player_y

// for arrow
self.current_angle = abs((sign(oPlayer.image_xscale) - 1) / 2 * 180)

// time
self.timeout_counter = 2 * 60 // seconds * fps

// time-freeze logic
instance_deactivate_all(true)