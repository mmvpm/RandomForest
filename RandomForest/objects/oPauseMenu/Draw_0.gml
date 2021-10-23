draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_set_font(self.default_font)

if (self.paused) {
	
	funSetBlurShader(
		100, room_width, room_height, 0.1, 1,
		0, 0, 0, 0.5
	)
	draw_sprite_ext(self.screenshot, 0, 0, 0, 1, 1, 0, c_white, 1)
	shader_reset()
	
	for (var i = 0; i < self.items_count; i++) {
		if (i == self.current_index) {
			draw_set_color(self.current_color)
		} else {
			draw_set_color(self.default_color)
		}
		draw_text(
			room_width * 0.5, 
			room_height * (self.top_item + self.separate_dist * i),
			self.strings[i]
		)
	}
}
