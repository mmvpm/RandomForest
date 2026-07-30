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
	pulse = 0
) {
	var ui_scale = self.default_scale
	var button_color = self.default_button_color
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
	draw_sprite_stretched_ext(
		self.border_sprite, 0,
		x_left, y_top,
		button_width, button_height,
		button_color, 1
	)

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
		draw_sprite_ext(
			icon_sprite,
			0,
			icon_x,
			68,
			icon_scale,
			icon_scale,
			0,
			c_white,
			1
		)
	}
	else {
		funDrawAchievementIcon(
			icon_sprite,
			icon_x,
			68,
			true,
			icon_scale
		)
	}

	draw_set_color(c_ltgray)
	draw_set_halign(fa_left)
	draw_text(text_x, 68, progress_text)

	var meter_width = 48
	var meter_x = center_x - meter_width / 2
	draw_set_color(make_color_rgb(72, 72, 72))
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
__funDrawPageProgress(
	175,
	sStar,
	page_progress.earned_stars,
	page_progress.max_stars,
	true
)
__funDrawPageProgress(
	240,
	sAchievementEnemies,
	page_progress.earned_enemy_clears,
	page_progress.levels_count
)
__funDrawPageProgress(
	305,
	sAchievementFlawless,
	page_progress.earned_flawless,
	page_progress.levels_count
)

// Progress helpers use the small font and left alignment; restore button style.
draw_set_font(global.default_font_24)
draw_set_halign(fa_center)
draw_set_valign(fa_middle)
for (var i = 0; i < visible_count; ++i) {
	var level_index = first_level + i
	var x_pos = self.button_x[i]
	var y_pos = self.button_y[i]
	var pulse = 0
	if (self.completion_animation_counter >= 0) {
		var pulse_frame = self.completion_animation_counter - i * 3
		if (pulse_frame >= 0 and pulse_frame < 12) {
			pulse = sin(pi * pulse_frame / 12)
		}
	}
	var button_size = __funDrawLevelSelectButton(
		i,
		x_pos,
		y_pos,
		self.level_button_size,
		self.level_button_size,
		string(level_index + 1),
		level_index <= global.current_level,
		0,
		0,
		pulse
	)
	if (level_index <= global.current_level) {
		var earned_stars = funGetStarCount(
			global.time_records[level_index],
			level_index,
			self.level_star_times[level_index]
		)
		funDrawLevelStars(x_pos, y_pos, button_size, earned_stars)
		funDrawLevelAchievementIcons(
			x_pos,
			y_pos,
			button_size,
			global.enemy_clear_records[level_index],
			global.flawless_records[level_index]
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
