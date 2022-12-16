draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_24)

if (self.paused) {

	gpu_set_tex_filter(false)
	for (var i = 0; i < self.items_count; i++) {
		var button_color = c_white
		var ui_scale = 1
		if (i == self.current_index) {
			draw_set_color(self.current_color)
			button_color = self.current_button_color
			ui_scale = self.current_scale
		}
		else {
			draw_set_color(self.default_color)
			button_color = self.default_button_color
			ui_scale = self.default_scale
		}
		var cam = view_camera[0]
		var x_pos = camera_get_view_width(cam) * 0.5
		var y_pos = self.top_item + self.separate_dist * i

		var x_width  = self.border_width  * ui_scale
		var y_height = self.border_height * ui_scale
		var x_left = x_pos - x_width / 2
		var y_up   = y_pos + 1.5 - y_height / 2

		draw_sprite_stretched_ext(
			self.border_sprite, 0,
			x_left, y_up,
			x_width, y_height,
			button_color, 1
		)

		// cache for mouse
		self.x_left_cached[i] = x_left
		self.y_top_cached[i]  = y_up
		self.x_right_cached[i]  = self.x_left_cached[i] + x_width
		self.y_bottom_cached[i] = self.y_top_cached[i]  + y_height
		self.x_shift_cached = 40
		self.y_shift_cached = 0 //(self.separate_dist - y_height) / 2 - 2 // ~ half-interval

		ui_scale *= self.text_scale

		draw_text_transformed(
			x_pos, y_pos,
			self.strings[i],
			ui_scale, ui_scale, 0
		)
	}
}

// reset color
draw_set_color(c_white)
