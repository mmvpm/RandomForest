if (self.following != noone) {
	self.target_x = self.following.x
	self.target_y = self.following.y
}

var dx = self.target_x - self.x
var dy = self.target_y - self.y

var k_x = self.meeting_k_x
var k_y = self.meeting_k_y


if (abs(dx) > self.w_border || abs(dy) > self.h_border) {
	k_x = self.fast_meeting_k
	k_y = self.fast_meeting_k
}

dx /= k_x
dy /= k_y

if (abs(dx) < self.min_speed_x) {
	dx = self.target_x - self.x
	dx = sign(dx) * min(self.min_speed_x, abs(dx))
}

if (abs(dy) < self.min_speed_y) {
	dy = self.target_y - self.y
	dy = sign(dy) * min(self.min_speed_y, abs(dy))
}

self.x += dx
self.y += dy

var cam_w = camera_get_view_width(view_camera[0])
var cam_h = camera_get_view_height(view_camera[0])

self.x = 0.5 * cam_w + clamp(
	self.x - 0.5 * cam_w, 
	self.offset, 
	room_width - offset - cam_w
)

self.y = 0.5 * cam_h + clamp(
	self.y - 0.5 * cam_h, 
	self.offset, 
	room_height - offset - cam_h
)

if (self.camera_shake_counter > 0) {
	self.camera_shake_counter--
	if (self.camera_shake_counter % self.camera_shake_delay == 0) {
		self.x += irandom_range(-self.camera_shake_power, self.camera_shake_power)
		self.y += irandom_range(-self.camera_shake_power, self.camera_shake_power)
	}
}
