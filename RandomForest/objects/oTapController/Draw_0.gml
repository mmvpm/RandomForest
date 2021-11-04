var cam = view_camera[0]
draw_sprite(self.screenshot, 0, 
	camera_get_view_x(cam),
	camera_get_view_y(cam)
)
draw_sprite_ext(sTapArrow, 0, self.x, self.y, 1, 1, self.current_angle, c_white, 1)