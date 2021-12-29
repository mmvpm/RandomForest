// set up font for controls
draw_set_halign(fa_middle)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_24)

// type arrow keys text
var victory_text_x = self.room_center_x
var victory_text_y = self.room_center_y - 30
draw_text_color(victory_text_x, victory_text_y, self.victory_text, c_white, c_white, c_white, c_white, self.text_alpha)


// set up font for continue
draw_set_halign(fa_middle)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_12)

// type text
self.text_continue_alpha_current =
	( sin(self.tick_counter * 2 * pi / self.music_duration) + 1 ) / 2  // [-1, 1] -> [0, 1]
	* self.text_continue_alpha_max + self.text_continue_alpha_min      // [0, 1] -> [min, max]
draw_text_color(self.room_center_x, room_height - 20, self.continue_text, c_white, c_white, c_white, c_white, self.text_continue_alpha_current)


// update time
self.tick_counter += 1
if (self.tick_counter % self.music_duration == self.tick_counter_start) { // one lap
	audio_play_sound(musicVictory, 0, false) // repeat
}