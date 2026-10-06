/// Draws one achievement icon in its earned or inactive state.
function funDrawAchievementIcon(
	sprite_asset,
	x_pos,
	y_pos,
	earned,
	scale = 1,
	alpha = 1,
    presentation = undefined
) {
    if (presentation == undefined) presentation = funThemePresentation("day")
	var icon_color = earned
		? presentation.palette.accent
		: presentation.palette.inactive
	var icon_alpha = earned ? alpha : 0.9 * alpha
	funDrawUiSprite(
		sprite_asset,
		0,
		x_pos,
		y_pos,
		scale,
		scale,
		0,
		icon_color,
		icon_alpha, presentation
	)
}

/// Draws the two compact achievement markers inside one level tile.
function funDrawLevelAchievementIcons(
	center_x,
	center_y,
	tile_size,
	enemy_clear_earned,
	flawless_earned,
    presentation = undefined
) {
	var icon_scale = 0.625
	var icon_y = center_y - tile_size / 2 + 7
	var icon_offset_x = tile_size / 2 - 8
	funDrawAchievementIcon(
		sAchievementEnemies,
		center_x - icon_offset_x,
		icon_y,
		enemy_clear_earned,
		icon_scale, 1, presentation
	)
	funDrawAchievementIcon(
		sAchievementFlawless,
		center_x + icon_offset_x,
		icon_y,
		flawless_earned,
		icon_scale, 1, presentation
	)
}
