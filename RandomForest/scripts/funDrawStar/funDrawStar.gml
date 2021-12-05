function funDrawStar(x_start, y_start, scale_start, x_end, y_end, scale_end, t) {
	
	draw_sprite_ext(sStar, 0, x_end, y_end, scale_end, scale_end, 0, c_black, 0.9)
	
	if (t > 0) {
		var x_pos = lerp(x_start, x_end, t)
		var y_pos = lerp(y_start, y_end, t)
		var scale = lerp(scale_start, scale_end, t)
	
		draw_sprite_ext(
			sStar, 0, x_pos, y_pos, scale, scale, 0, c_white, 1
		)
	}
}