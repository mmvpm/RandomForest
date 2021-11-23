function __funQuad(_vb, _x1, _y1, _x2, _y2) {
	vertex_position_3d(_vb, _x1, _y1, 0)
	vertex_position_3d(_vb, _x1, _y1, 2)
	vertex_position_3d(_vb, _x2, _y2, 1)

	vertex_position_3d(_vb, _x1, _y1, 2)
	vertex_position_3d(_vb, _x2, _y2, 1)
	vertex_position_3d(_vb, _x2, _y2, 3)
}

vertex_begin(self.vb, self.vf)

var _vb = self.vb

with (oSolid) {
	
	var _x = self.sprite_width * dcos(self.image_angle) + self.sprite_height * dsin(self.image_angle)
	var _y = -self.sprite_width * dsin(self.image_angle) + self.sprite_height * dcos(self.image_angle)
	
	__funQuad(_vb, 
		self.x, 
		self.y, 
		self.x + _x, 
		self.y + _y
	)
	
	__funQuad(_vb, 
		self.x + _x, 
		self.y,
		self.x, 
		self.y + _y
	)
}

if (mouse_check_button_pressed(mb_left)) {
	funCreateLight(
		mouse_x, mouse_y, oLight, 
		oMovingLight.light_radius, oMovingLight.light_power, 
		oMovingLight.light_color, oMovingLight.light_count, 
		oMovingLight.light_dir, oMovingLight.light_fov, oMovingLight.light_step
	)
}


vertex_end(self.vb)
