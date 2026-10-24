// last empty place for player
// self.shift_of_player_y

// for arrow
self.diagonal_countdown = 5 // frames
self.diagonal_countdown_counter = 0
self.current_angle = abs((sign(oPlayer.image_xscale) - 1) / 2 * 180)

// time
self.timeout_counter_max = 2 * 60 // seconds * fps
self.timeout_counter = self.timeout_counter_max

// Freeze gameplay while continuing the live layered atmosphere.
funAimFreezeBegin()
