function funDefaultIsInView0() {
	var camera_x = camera_get_view_x(view_camera[0])
	var camera_y = camera_get_view_y(view_camera[0])
	var camera_w = camera_get_view_width(view_camera[0])
	var camera_h = camera_get_view_height(view_camera[0])

	var cam_x0 = camera_x
	var cam_y0 = camera_y
	var cam_x1 = camera_x + camera_w
	var cam_y1 = camera_y + camera_h

	var self_x0 = self.bbox_left
	var self_y0 = self.bbox_top
	var self_x1 = self.bbox_right
	var self_y1 = self.bbox_bottom

	return
		self_x1 >= cam_x0 and self_y1 >= cam_y0 
			and 
		self_x0 <= cam_x1 and self_y0 <= cam_y1
}