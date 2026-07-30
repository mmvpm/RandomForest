draw_set_halign(fa_center)
draw_set_valign(fa_middle)

/// Draws centered icon-and-label content inside one achievement badge.
function __funDrawResultBadgeContent(
	x_pos,
	y_pos,
	width,
	height,
	icon_sprite,
	label,
	icon_color,
	label_color,
	label_font,
	content_scale,
	alpha
) {
	draw_set_font(label_font)
	var icon_width = sprite_get_width(icon_sprite) * content_scale
	var content_gap = 4 * content_scale
	var label_width = string_width(label) * content_scale
	var content_width = icon_width + content_gap + label_width
	var content_left = x_pos + (width - content_width) / 2
	var content_y = y_pos + height / 2

	draw_sprite_ext(
		icon_sprite,
		0,
		content_left + icon_width / 2,
		content_y,
		content_scale,
		content_scale,
		0,
		icon_color,
		alpha
	)
	draw_set_halign(fa_left)
	draw_set_valign(fa_middle)
	draw_set_color(label_color)
	draw_set_alpha(alpha)
	draw_text_transformed(
		content_left + icon_width + content_gap,
		content_y,
		label,
		content_scale,
		content_scale,
		0
	)
	draw_set_alpha(1)
}

/// Draws one result achievement in inactive and earned layers.
function __funDrawResultBadge(
	x_pos,
	y_pos,
	width,
	height,
	icon_sprite,
	label,
	label_font,
	earned,
	reveal_t
) {
	draw_sprite_stretched_ext(
		sBorder4,
		0,
		x_pos,
		y_pos,
		width,
		height,
		make_color_rgb(72, 72, 72),
		1
	)
	__funDrawResultBadgeContent(
		x_pos,
		y_pos,
		width,
		height,
		icon_sprite,
		label,
		c_black,
		c_dkgray,
		label_font,
		1,
		0.9
	)

	if (!earned or reveal_t <= 0) {
		return
	}

	var badge_scale = 1 + 0.3 * (1 - reveal_t)
	var draw_width = width * badge_scale
	var draw_height = height * badge_scale
	var draw_x = x_pos + (width - draw_width) / 2
	var draw_y = (
		y_pos
		+ (height - draw_height) / 2
		- 4 * (1 - reveal_t)
	)
	var border_color = merge_color(
		c_ltgray,
		make_color_rgb(58, 110, 58),
		1 - reveal_t
	)
	draw_sprite_stretched_ext(
		sBorder4,
		0,
		draw_x,
		draw_y,
		draw_width,
		draw_height,
		border_color,
		reveal_t
	)
	__funDrawResultBadgeContent(
		draw_x,
		draw_y,
		draw_width,
		draw_height,
		icon_sprite,
		label,
		make_color_rgb(112, 211, 112),
		c_ltgray,
		label_font,
		badge_scale,
		reveal_t
	)
}

/// Draws the target time on an unearned second or third star.
function __funDrawMissingStarTime(star_index, star_x, star_y) {
	if (star_index < self.max_stars or star_index == 0) {
		return
	}
	var target_seconds = (
		star_index == 1
		? self.star_times.two_stars
		: self.star_times.three_stars
	)
	draw_set_font(global.default_font_12)
	draw_set_halign(fa_center)
	draw_set_valign(fa_middle)
	draw_set_color(c_ltgray)
	draw_text(
		star_x + 10,
		star_y - 11,
		funGetTimeString(target_seconds * 60)
	)
}

var t_anim_stat = 1 - self.stats_animation_counter / self.stats_animation_time

var t_anim_border = self.border_animation_counter / self.border_animation_time
t_anim_border = power(t_anim_border, 2)

var cur_alpha = 1 - self.alpha_animation_counter / self.alpha_animation_time

var cam = view_camera[0]
var cam_w = camera_get_view_width(cam)
var cam_h = camera_get_view_height(cam)

gpu_set_tex_filter(false)
draw_set_alpha(cur_alpha)

for (var i = 0; i < self.items_count; i++) {
	var button_color = c_white
	var ui_scale = 1
	draw_set_font(global.default_font_24)
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

	var x_pos = cam_w * 0.8
	var y_pos = cam_h * (self.top_item + self.separate_dist * i)
	
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

// The container itself uses screen coordinates; its content uses local offsets.
var container_x = 10
var container_height = 210
var container_vertical_offset = 0
var container_y = 0.5 * (cam_h - container_height) + container_vertical_offset

var container_width = (
	cam_w * 0.8
	- self.border_width * 0.5 * self.current_scale
	- 2 * container_x
)

// Recreate the result surface when its expanded geometry changes.
if (
	surface_exists(self.border_surf)
	and (
		surface_get_width(self.border_surf) != container_width
		or surface_get_height(self.border_surf) != container_height
	)
) {
	surface_free(self.border_surf)
	self.border_surf = noone
}
if (!surface_exists(self.border_surf)) {
	self.border_surf = surface_create(container_width, container_height)
}

surface_set_target(self.border_surf)
draw_clear_alpha(c_black, 0)
draw_set_alpha(1)
draw_set_color(self.default_color)
var time_font = global.default_font_24
draw_set_font(time_font)

draw_sprite_stretched_ext(
	sBorder3, 0,
	0, 0,
	container_width, container_height,
	c_white, 1
)

draw_set_halign(fa_left)
draw_set_valign(fa_bottom)

var time_horizontal_padding = 25
var current_time_bottom_offset = 50
var best_time_bottom_offset = 15
var current_time_y = container_height - current_time_bottom_offset
var best_time_y = container_height - best_time_bottom_offset

draw_text(
	time_horizontal_padding,
	current_time_y,
	"Текущее время: "
)

draw_text(
	time_horizontal_padding,
	best_time_y,
	"Лучшее время: "
)

draw_set_halign(fa_right)

draw_text(
	container_width - time_horizontal_padding,
	current_time_y,
	funGetTimeString(floor(self.current_time * t_anim_stat))
)

draw_text(
	container_width - time_horizontal_padding,
	best_time_y,
	funGetTimeString(floor(self.best_time * t_anim_stat))
)

var star_count = 3
var middle_star_index = 1
var middle_star_y_from_top = 40
var side_star_drop = 16
var star_horizontal_gap = 70
var star_animation_horizontal_gap = 80
var star_animation_vertical_offset = 20
var star_animation_start_scale = 3.0
var result_star_scale = 2.0

for (var i = 0; i < star_count; i++) {
	var t_star = 0
	if (i < self.max_stars) {
		if (i < self.shown_stars) {
			t_star = 1
		}
		else if (i == self.shown_stars) {
			t_star = 1 - self.star_animation_counter / self.star_animation_time
		}
	}
	var star_x = (
		0.5 * container_width
		+ (i - middle_star_index) * star_horizontal_gap
	)
	var star_y = (
		middle_star_y_from_top
		+ abs(i - middle_star_index) * side_star_drop
	)
	funDrawStar(
		0.5 * container_width
			+ (i - middle_star_index) * star_animation_horizontal_gap,
		star_y + star_animation_vertical_offset,
		star_animation_start_scale,
		star_x,
		star_y,
		result_star_scale,
		0 * (1 - i),
		t_star
	)
	__funDrawMissingStarTime(i, star_x, star_y)
}

var badge_width = 122
var badge_height = 26
var badge_gap = 8
var badge_font = global.default_font_12
var badge_offset_below_side_stars = 8
var side_star_y = middle_star_y_from_top + side_star_drop
var side_star_half_height = (
	0.5 * sprite_get_height(sStar) * result_star_scale
)
var side_stars_bottom = side_star_y + side_star_half_height
var badge_y = side_stars_bottom + badge_offset_below_side_stars
var badge_start_x = (
	container_width - 2 * badge_width - badge_gap
) / 2
__funDrawResultBadge(
	badge_start_x,
	badge_y,
	badge_width,
	badge_height,
	sAchievementEnemies,
	"Все враги",
	badge_font,
	self.enemy_clear_earned,
	self.enemy_badge_t
)
__funDrawResultBadge(
	badge_start_x + badge_width + badge_gap,
	badge_y,
	badge_width,
	badge_height,
	sAchievementFlawless,
	"Без урона",
	badge_font,
	self.flawless_earned,
	self.flawless_badge_t
)

surface_reset_target()

draw_surface_ext(
	self.border_surf, 
	container_x + 0.5 * container_width * t_anim_border,
	container_y,
	1 - t_anim_border, 1, 0, c_white, cur_alpha
)

// reset
draw_set_color(c_white)
draw_set_alpha(1)
