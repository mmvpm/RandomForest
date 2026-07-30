/// Draws one achievement icon in its earned or inactive state.
function funDrawAchievementIcon(
	sprite_asset,
	x_pos,
	y_pos,
	earned,
	scale = 1,
	alpha = 1
) {
	var icon_color = earned
		? make_color_rgb(112, 211, 112)
		: make_color_rgb(72, 72, 72)
	var icon_alpha = earned ? alpha : 0.9 * alpha
	draw_sprite_ext(
		sprite_asset,
		0,
		x_pos,
		y_pos,
		scale,
		scale,
		0,
		icon_color,
		icon_alpha
	)
}

/// Draws the two compact achievement markers inside one level tile.
function funDrawLevelAchievementIcons(
	center_x,
	center_y,
	tile_size,
	enemy_clear_earned,
	flawless_earned
) {
	var icon_scale = 0.625
	var icon_y = center_y - tile_size / 2 + 7
	var icon_offset_x = tile_size / 2 - 8
	funDrawAchievementIcon(
		sAchievementEnemies,
		center_x - icon_offset_x,
		icon_y,
		enemy_clear_earned,
		icon_scale
	)
	funDrawAchievementIcon(
		sAchievementFlawless,
		center_x + icon_offset_x,
		icon_y,
		flawless_earned,
		icon_scale
	)
}
