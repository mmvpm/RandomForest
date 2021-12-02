draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_set_font(self.default_font)

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

draw_set_color(self.default_color)

var offset_x = 10
var offset_y = 20

var bw = cam_w * 0.8 - self.border_width * 0.5 * self.current_scale - 2 * offset_x
var bh = 2 * offset_y + self.border_height * self.current_scale + cam_h * self.separate_dist * (self.items_count - 1)

draw_sprite_stretched_ext(
	sBorder1, 0,
	offset_x + 0.5 * bw, 
	cam_h * self.top_item + 0.5 * (bh - self.border_height * self.current_scale) - offset_y,
	bw, bh,
	c_white, 1
)

draw_text_transformed(
	100, 100, 
	"Текущее время: " + funGetTimeString(self.current_time),
	self.default_scale, self.default_scale, 0
)

draw_text_transformed(
	100, 150, 
	"Лучшее время: " + funGetTimeString(self.best_time),
	self.default_scale, self.default_scale, 0
)

// reset color
draw_set_color(c_white)
