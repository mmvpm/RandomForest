draw_set_halign(fa_center)
draw_set_valign(fa_middle)

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
	draw_set_font(self.default_font)
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
	
	var x_center = x_pos
	var y_center = y_pos + 1.5
	var x_width  = self.border_width  * ui_scale
	var y_height = self.border_height * ui_scale

	draw_sprite_stretched_ext(
		self.border_sprite, 0,
		x_center, y_center,
		x_width, y_height,
		button_color, 1
	)

	// cache for mouse
	self.x_left_cached[i] = x_center - x_width / 2
	self.y_top_cached[i]  = y_center - y_height / 2
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

var offset_x = 10
var offset_y = 20

var bw = cam_w * 0.8 - self.border_width * 0.5 * self.current_scale - 2 * offset_x
var bh = 2 * offset_y + self.border_height * self.current_scale + cam_h * self.separate_dist * (self.items_count - 1)

if (!surface_exists(self.border_surf)) {
	self.border_surf = surface_create(bw, bh)
}

surface_set_target(self.border_surf)
draw_set_alpha(1)
draw_set_color(self.default_color)
draw_set_font(self.border_font)

draw_sprite_stretched_ext(
	sBorder3, 0,
	0.5 * bw, 
	0.5 * bh,
	bw, bh,
	c_white, 1
)

draw_set_halign(fa_left)
draw_set_valign(fa_bottom)

var offset_text_x = 25
var offset_text_y = 25

draw_text(
	offset_text_x, 
	0.8 * bh - offset_text_y, 
	"Текущее время: "
)

draw_text(
	offset_text_x,
	bh - offset_text_y, 
	"Лучшее время: "
)

draw_set_halign(fa_right)

draw_text(
	bw - offset_text_x,
	0.8 * bh - offset_text_y, 
	funGetTimeString(floor(self.current_time * t_anim_stat))
)

draw_text(
	bw - offset_text_x,
	bh - offset_text_y, 
	funGetTimeString(floor(self.best_time * t_anim_stat))
)

if (t_anim_stat == 1 and self.shown_stars == -1) {
	self.star_animation_counter = self.star_animation_time + self.star_animation_delay
	self.shown_stars = 0
}

for (var i = 0; i < 3; i++) {
	var t_star = 0
	if (i < self.max_stars) {
		if (i < self.shown_stars) {
			t_star = 1
		}
		else if (i == self.shown_stars) {
			t_star = 1 - self.star_animation_counter / self.star_animation_time
		}
	}
	funDrawStar(
		0.5 * bw + (i - 1) * 80, 
		43 + abs(i - 1) * 15 + 20,
		3.0,
		0.5 * bw + (i - 1) * 70, 
		43 + abs(i - 1) * 15,
		2.0,
		0 * (1 - i),
		t_star
	)
}

surface_reset_target()

draw_surface_ext(
	self.border_surf, 
	offset_x + 0.5 * bw * t_anim_border,
	cam_h * self.top_item - 0.5 * self.border_height * self.current_scale - offset_y,
	1 - t_anim_border, 1, 0, c_white, cur_alpha
)

// reset
draw_set_color(c_white)
draw_set_alpha(1)