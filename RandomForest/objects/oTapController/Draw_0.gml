var cam = view_camera[0]

gpu_set_blendenable(false)
draw_sprite(self.screenshot, 0, 
	camera_get_view_x(cam),
	camera_get_view_y(cam)
)
gpu_set_blendenable(true)

var frames_number = sprite_get_number(sTapCountdown)
var inverse_counter = self.timeout_counter_max - self.timeout_counter
var countdown_index = floor(inverse_counter / self.timeout_counter_max * frames_number)

var is_diagonal = self.current_angle % 10 == 5
if (is_diagonal) {
	draw_sprite_ext(sTapArrowDiag, 0, self.x, self.y, 1, 1, self.current_angle - 45, c_white, 1)
	draw_sprite_ext(sTapCountdownDiag, countdown_index, self.x, self.y, 1, 1, self.current_angle - 45, c_white, 1)
}
else {
	draw_sprite_ext(sTapArrow, 0, self.x, self.y, 1, 1, self.current_angle, c_white, 1)
	draw_sprite_ext(sTapCountdown, countdown_index, self.x, self.y, 1, 1, self.current_angle, c_white, 1)
}
