/// Shares the background's current palette and crossfade weights.
funApplyUiPresentation(funUiScenePresentation(true))
// Draws a menu firefly as integer-aligned game pixels behind tile content.
function __funDrawLevelOrangeFirefly(
	firefly,
	center_x,
	center_y,
	color,
	alpha
) {
	var pixel_x = round(center_x + firefly.x)
	var pixel_y = round(center_y + firefly.y)
	var body_left = pixel_x - 1
	var body_top = pixel_y - 1

	// A sparse one-pixel ring hints at bloom without creating a soft blob.
	gpu_set_blendmode(bm_add)
	draw_set_color(color)
	draw_set_alpha(alpha * 0.05)
	draw_rectangle(
		body_left,
		body_top - 1,
		body_left + 2,
		body_top,
		false
	)
	draw_rectangle(
		body_left,
		body_top + 2,
		body_left + 2,
		body_top + 3,
		false
	)
	draw_rectangle(
		body_left - 1,
		body_top,
		body_left,
		body_top + 2,
		false
	)
	draw_rectangle(
		body_left + 2,
		body_top,
		body_left + 3,
		body_top + 2,
		false
	)

	// One brighter pixel gives the 2x2 body volume without subpixel drawing.
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(alpha * 0.65)
	draw_rectangle(
		body_left,
		body_top,
		body_left + 2,
		body_top + 2,
		false
	)
	draw_set_color(merge_color(color, c_white, 0.2))
	draw_set_alpha(alpha)
	draw_rectangle(
		body_left + 1,
		body_top,
		body_left + 2,
		body_top + 1,
		false
	)
	draw_set_alpha(1)
	draw_set_color(c_white)
}

// Draws one level or navigation button and caches its mouse bounds.
function __funDrawLevelSelectButton(
	button_index,
	x_pos,
	y_pos,
	width,
	height,
	text,
	enabled,
	text_offset_x = 0,
	text_offset_y = 0,
	pulse = 0,
	orange_firefly = undefined
) {
	var ui_scale = self.default_scale
	var button_color = self.default_button_color
	var has_orange_firefly = enabled and orange_firefly != undefined
	draw_set_color(self.default_color)

	if (!enabled) {
		button_color = self.locked_button_color
		draw_set_color(self.locked_color)
	}
	else if (button_index == self.current_index) {
		ui_scale = self.current_scale
		button_color = self.current_button_color
		draw_set_color(self.current_color)
	}
	if (pulse > 0) {
		ui_scale += 0.05 * pulse
		button_color = merge_color(
			button_color,
			self.current_button_color,
			pulse
		)
	}
	var button_width = width * ui_scale
	var button_height = height * ui_scale
	var x_left = x_pos - button_width / 2
	var y_top = y_pos - button_height / 2
	funDrawUiPanel(
		self.border_sprite, 0,
		x_left, y_top,
		button_width, button_height,
		button_color, 1, self.theme_presentation
	)
	if (has_orange_firefly) {
		__funDrawLevelOrangeFirefly(
			orange_firefly,
			x_pos,
			y_pos,
			self.orange_firefly_menu_color,
			self.level_firefly_alpha
		)
	}

	if (enabled) {
		self.x_left_cached[button_index] = x_left
		self.y_top_cached[button_index] = y_top
		self.x_right_cached[button_index] = x_left + button_width
		self.y_bottom_cached[button_index] = y_top + button_height
	}

	var label_scale = ui_scale * self.text_scale
	draw_text_transformed(
		x_pos + text_offset_x,
		y_pos + text_offset_y,
		text,
		label_scale,
		label_scale,
		0
	)
	return button_width
}

// Draws deliberately ambiguous progress with an orange mystery icon.
function __funDrawOrangeFireflyProgress(center_x, earned, maximum) {
	var icon_scale = 0.75
	var progress_text = string(earned) + "/" + string(maximum)
	draw_set_font(global.default_font_12)
	var icon_width = sprite_get_width(sAchievementMystery) * icon_scale
	var content_gap = 4
	var content_width = icon_width + content_gap + string_width(progress_text)
	var content_left = center_x - content_width / 2
	var icon_x = content_left + icon_width / 2
	var text_x = content_left + icon_width + content_gap

	funDrawUiSprite(
		sAchievementMystery,
		0,
		icon_x,
		68,
		icon_scale,
		icon_scale,
		0,
		self.orange_firefly_menu_color,
		1, self.theme_presentation
	)
	draw_set_color(self.default_color)
	draw_set_halign(fa_left)
	draw_text(text_x, 68, progress_text)

	var meter_width = 48
	var meter_x = center_x - meter_width / 2
	draw_set_color(self.theme_presentation.palette.inactive)
	draw_rectangle(meter_x, 78, meter_x + meter_width, 79, false)
	if (maximum > 0 and earned > 0) {
		draw_set_color(self.orange_firefly_menu_color)
		draw_rectangle(
			meter_x,
			78,
			meter_x + meter_width * earned / maximum,
			79,
			false
		)
	}
}

// Draws one compact page-progress counter and its two-pixel meter.
function __funDrawPageProgress(
	center_x,
	icon_sprite,
	earned,
	maximum,
	is_star = false
) {
	var icon_scale = is_star ? 0.5 : 0.75
	var progress_text = string(earned) + "/" + string(maximum)
	draw_set_font(global.default_font_12)
	var icon_width = sprite_get_width(icon_sprite) * icon_scale
	var content_gap = 4
	var content_width = icon_width + content_gap + string_width(progress_text)
	var content_left = center_x - content_width / 2
	var icon_x = content_left + icon_width / 2
	var text_x = content_left + icon_width + content_gap
	if (is_star) {
		funDrawUiSprite(
			icon_sprite,
			0,
			icon_x,
			68,
			icon_scale,
			icon_scale,
			0,
			c_white,
			1, self.theme_presentation
	)
	}
	else {
		funDrawAchievementIcon(
			icon_sprite,
			icon_x,
			68,
			true,
			icon_scale, 1, self.theme_presentation
	)
	}

	draw_set_color(self.default_color)
	draw_set_halign(fa_left)
	draw_text(text_x, 68, progress_text)

	var meter_width = 48
	var meter_x = center_x - meter_width / 2
	draw_set_color(self.theme_presentation.palette.inactive)
	draw_rectangle(meter_x, 78, meter_x + meter_width, 79, false)
	if (maximum > 0 and earned > 0) {
		draw_set_color(self.current_color)
		draw_rectangle(
			meter_x,
			78,
			meter_x + meter_width * earned / maximum,
			79,
			false
		)
	}
}

var cam_w = camera_get_view_width(view_camera[0])
draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_24)

// Clear bounds for unused slots and disabled page controls.
for (var clear_index = 0; clear_index < self.buttons_count; ++clear_index) {
	self.x_left_cached[clear_index] = -1000
	self.y_top_cached[clear_index] = -1000
	self.x_right_cached[clear_index] = -1000
	self.y_bottom_cached[clear_index] = -1000
}

// Keep the original level-select title and visual hierarchy.
draw_set_color(c_white)
draw_text_transformed(0.5 * cam_w + 2, 30, "Random Forest", 2, 2, 0)

var first_level = self.page_index * self.page_size
var visible_count = min(self.page_size, self.levels_count - first_level)
var page_progress = funGetAchievementPageProgress(
	self.page_index,
	self.page_size,
	self.level_star_times
)
if (page_progress.levels_count > 0) {
__funDrawPageProgress(
	144,
	sStar,
	page_progress.earned_stars,
	page_progress.max_stars,
	true
)
__funDrawPageProgress(
	208,
	sAchievementEnemies,
	page_progress.earned_enemy_clears,
	page_progress.levels_count
)
__funDrawPageProgress(
	272,
	sAchievementFlawless,
	page_progress.earned_flawless,
	page_progress.levels_count
)
__funDrawOrangeFireflyProgress(
	336,
	page_progress.earned_orange_fireflies,
	page_progress.levels_count
)

}

// Progress helpers use the small font and left alignment; restore button style.
draw_set_font(global.default_font_24)
draw_set_halign(fa_center)
draw_set_valign(fa_middle)
for (var i = 0; i < visible_count; ++i) {
	var level_index = first_level + i
	var center = funLevelSelectButtonCenter(i)
	var x_pos = center.x
	var y_pos = center.y
	var pulse = 0
	if (self.completion_animation_counter >= 0) {
		var pulse_frame = self.completion_animation_counter - i * 3
		if (pulse_frame >= 0 and pulse_frame < 12) {
			pulse = sin(pi * pulse_frame / 12)
		}
	}
	var level_enabled = level_index <= global.current_level
	var orange_firefly = undefined
	if (level_enabled and funLevelTracksProgress(level_index) and global.orange_firefly_records[level_index]) {
		orange_firefly = self.level_orange_fireflies[level_index]
	}
	var button_size = __funDrawLevelSelectButton(
		i,
		x_pos,
		y_pos,
		self.level_button_size,
		self.level_button_size,
		funCampaignLevelLabel(level_index),
		level_enabled,
		0,
		0,
		pulse,
		orange_firefly
	)
	if (level_enabled and funLevelTracksProgress(level_index)) {
		var earned_stars = funGetStarCount(
			global.time_records[level_index],
			level_index,
			self.level_star_times[level_index]
		)
		funDrawLevelStars(x_pos, y_pos, button_size, earned_stars, self.theme_presentation
	)
		funDrawLevelAchievementIcons(
			x_pos,
			y_pos,
			button_size,
			global.enemy_clear_records[level_index],
			global.flawless_records[level_index], self.theme_presentation
	)
	}
}

__funDrawLevelSelectButton(
	self.previous_index,
	self.previous_x,
	self.page_buttons_y,
	self.page_button_width,
	self.page_button_height,
	"<",
	self.page_index > 0,
	0,
	-2
)
__funDrawLevelSelectButton(
	self.next_index,
	self.next_x,
	self.page_buttons_y,
	self.page_button_width,
	self.page_button_height,
	">",
	self.page_index < self.page_count - 1,
	1,
	-2
)
__funDrawLevelSelectButton(
	self.exit_index,
	self.exit_x,
	self.exit_y,
	self.exit_button_width,
	self.exit_button_height,
	"Выйти в меню",
	true
)

draw_set_color(c_white)
draw_set_alpha(1)
