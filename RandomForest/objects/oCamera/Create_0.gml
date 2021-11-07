self.following = oPlayer

var cam = view_camera[0]

self.h_border = camera_get_view_height(cam) * 0.6
self.w_border = camera_get_view_width(cam) * 0.6

self.target_x = self.x
self.target_y = self.y

self.meeting_k = 25.0
self.fast_meeting_k = 2.0
