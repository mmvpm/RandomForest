self.following = oPlayer

var cam = view_camera[0]

self.h_border = camera_get_view_height(cam) * 0.6
self.w_border = camera_get_view_width(cam) * 0.6

self.target_x = self.x
self.target_y = self.y

self.min_speed_x = 0.5
self.min_speed_y = 0.5

self.meeting_k_x = 20.0
self.meeting_k_y = 20.0

self.fast_meeting_k = 2.0
