function funGetEyePos() {
	var idx = floor(self.image_index)
	var s_x = self.image_xscale
	var s_y = self.image_yscale
	
	switch (self.sprite_index) {
		case sSlimeIdle:
			self.eye_x = s_x * self.eye_pos_x_idle[idx]
			self.eye_y = s_y * self.eye_pos_y_idle[idx]
			break
		case sSlimeMove:
			self.eye_x = s_x * self.eye_pos_x_move[idx]
			self.eye_y = s_y * self.eye_pos_y_move[idx]
			break
		case sSlimeHurt:
			self.eye_x = s_x * self.eye_pos_x_hurt[idx]
			self.eye_y = s_y * self.eye_pos_y_hurt[idx]
			break
		case sSlimeAttack:
			self.eye_x = s_x * self.eye_pos_x_attack[idx]
			self.eye_y = s_y * self.eye_pos_y_attack[idx]
			break
		case sSlimeDie:
			self.eye_x = s_x * self.eye_pos_x_die[idx]
			self.eye_y = s_y * self.eye_pos_y_die[idx]
			break
	}
}