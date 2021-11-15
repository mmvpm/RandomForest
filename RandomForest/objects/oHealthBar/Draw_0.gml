/// @description Draw health bar

// top-left origin coordinates on the screen
var bar_x = 12
var bar_y = 12

var heart_width = 12 // oHealthBar.width
var indent_between_hearts = 3

for (var heart_index = 0; heart_index < oPlayer.health; ++heart_index) {
	var current_bar_x = bar_x + (indent_between_hearts + heart_width) *  heart_index
	var current_bar_y = bar_y

	current_bar_x += camera_get_view_x(view_camera[0])
	current_bar_y += camera_get_view_y(view_camera[0])

	draw_sprite(sHealthBar, 0, current_bar_x, current_bar_y)
}