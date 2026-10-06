/// Draws an animated original-color star over its black inactive state.
function funDrawStar(x_start, y_start, scale_start, x_end, y_end, scale_end, rotation, t, presentation = undefined) {
    if (presentation == undefined) presentation = funThemePresentation("day")
	funDrawUiSprite(sStar, 0, x_end, y_end, scale_end, scale_end, rotation, presentation.palette.inactive, 0.9, presentation)

	if (t > 0) {
		var x_pos = lerp(x_start, x_end, t)
		var y_pos = lerp(y_start, y_end, t)
		var scale = lerp(scale_start, scale_end, t)

		funDrawUiSprite(
			sStar, 0, x_pos, y_pos, scale, scale, rotation, c_white, 1.0, presentation
		)
	}
}

/// Draws three compact record stars along the bottom of one level tile.
function funDrawLevelStars(center_x, center_y, tile_size, earned_stars, presentation = undefined) {
	var star_size = 9
	var star_scale = star_size / sprite_get_width(sStar)
	var center_star_y = center_y + tile_size / 2 - star_size / 2
	var side_star_y = center_star_y + 3
	var side_offset = tile_size / 2 - 5 - star_size / 2

	for (var star_index = 0; star_index < 3; ++star_index) {
		var star_x = center_x
		var star_y = center_star_y
		if (star_index != 1) {
			star_x += (star_index - 1) * side_offset
			star_y = side_star_y
		}
		var is_earned = star_index < earned_stars
		funDrawStar(
			star_x,
			star_y,
			star_scale,
			star_x,
			star_y,
			star_scale,
			0,
			is_earned, presentation
		)
	}
}
