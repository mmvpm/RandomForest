var cam_w = camera_get_view_width(view_camera[0])

draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_24)

// Match the main menu logo.
draw_set_color(c_white)
draw_text_transformed(0.5 * cam_w + 2, 30, "Random Forest", 2, 2, 0)

// Draw level buttons and cache their mouse hit boxes.
for (var i = 0; i < self.levels_count; ++i) {
	var unlocked = i <= global.current_level
	var ui_scale = self.default_scale
	var button_color = self.default_button_color
	draw_set_color(self.default_color)

	if (!unlocked) {
		button_color = self.locked_button_color
		draw_set_color(self.locked_color)
	}
	else if (i == self.current_index) {
		ui_scale = self.current_scale
		button_color = self.current_button_color
		draw_set_color(self.current_color)
	}

	var column = i mod self.columns_count
	var row = i div self.columns_count
	var x_pos = self.grid_left + self.grid_step * column
	var y_pos = self.grid_top + self.grid_step * row
	var button_size = self.level_button_size * ui_scale
	var x_left = x_pos - button_size / 2
	var y_top = y_pos - button_size / 2

	draw_sprite_stretched_ext(
		self.border_sprite, 0,
		x_left, y_top,
		button_size, button_size,
		button_color, 1
	)

	self.x_left_cached[i] = x_left
	self.y_top_cached[i] = y_top
	self.x_right_cached[i] = x_left + button_size
	self.y_bottom_cached[i] = y_top + button_size

	var number_scale = ui_scale * self.text_scale
	draw_text_transformed(x_pos, y_pos, string(i + 1), number_scale, number_scale, 0)
}

// Draw the exit button below the level grid.
var exit_scale = self.default_scale
var exit_button_color = self.default_button_color
draw_set_color(self.default_color)
if (self.current_index == self.exit_index) {
	exit_scale = self.current_scale
	exit_button_color = self.current_button_color
	draw_set_color(self.current_color)
}

var exit_width = self.exit_button_width * exit_scale
var exit_height = self.exit_button_height * exit_scale
var exit_left = self.exit_x - exit_width / 2
var exit_top = self.exit_y - exit_height / 2
draw_sprite_stretched_ext(
	self.border_sprite, 0,
	exit_left, exit_top,
	exit_width, exit_height,
	exit_button_color, 1
)

self.x_left_cached[self.exit_index] = exit_left
self.y_top_cached[self.exit_index] = exit_top
self.x_right_cached[self.exit_index] = exit_left + exit_width
self.y_bottom_cached[self.exit_index] = exit_top + exit_height

var exit_text_scale = exit_scale * self.text_scale
draw_text_transformed(self.exit_x, self.exit_y, "Выйти в меню", exit_text_scale, exit_text_scale, 0)

draw_set_color(c_white)
draw_set_alpha(1)
