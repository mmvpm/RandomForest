draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_set_font(self.default_font)

var t_anim_border = self.border_animation_counter / self.border_animation_time
t_anim_border = power(t_anim_border, 2)


var cur_alpha = 1 - self.alpha_animation_counter / self.alpha_animation_time

var cam = view_camera[0]
var cam_w = camera_get_view_width(cam)
var cam_h = camera_get_view_height(cam)

if (!surface_exists(self.back_surf)) {
	var tmp_surf = surface_create(cam_w, cam_h)
	surface_set_target(tmp_surf)
	draw_sprite(sBackground, 0, 0, 0)
	surface_reset_target()
	
	self.back_surf = funBlurSurface(
		tmp_surf, 10,
		cam_w, cam_h,
		1, 4,
		0, 0, 0, 0.2
	)
	surface_free(tmp_surf)
}

draw_set_color(c_black)
draw_rectangle(0, 0, cam_w, cam_h, 0)
draw_set_color(c_white)
draw_set_alpha(cur_alpha)
draw_surface(self.back_surf, 0, 0)

for (var i = 0; i < self.items_count; i++) {
	var button_color = c_white
	var ui_scale = 1
	if (i == self.current_index) {
		draw_set_color(self.current_color)
		button_color = self.current_button_color
		ui_scale = self.current_scale
	} else {
		draw_set_color(self.default_color)
		button_color = self.default_button_color
		ui_scale = self.default_scale
	}
	
	var x_pos = cam_w * 0.8
	var y_pos = cam_h * (self.top_item + self.separate_dist * i)

	draw_sprite_stretched_ext(
		self.border_sprite, 0,
		x_pos, y_pos + 1.5,
		self.border_width * ui_scale, self.border_height * ui_scale,
		button_color, 1
	)

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

draw_text_transformed(
	0.5 * bw, 
	0.3 * bh, 
	"Текущее время: " + funGetTimeString(self.current_time),
	self.default_scale, self.default_scale, 0
)

draw_text_transformed(
	0.5 * bw,
	0.5 * bh, 
	"Лучшее время: " + funGetTimeString(self.best_time),
	self.default_scale, self.default_scale, 0
)

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