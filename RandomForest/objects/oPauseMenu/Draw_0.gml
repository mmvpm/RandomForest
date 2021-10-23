draw_set_halign(fa_center)
draw_set_valign(fa_middle)

if (self.paused) {
	draw_sprite_ext(self.screenshot, 0, 0, 0, 1, 1, 0, c_white, 1)
	draw_text(room_width * 0.5, room_height * 0.5, "Paused")
}
