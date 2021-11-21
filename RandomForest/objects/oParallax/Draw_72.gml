/// @description Background moving

self.x = camera_get_view_x(view_camera[0]) * self.background_to_view_ratio
self.y = camera_get_view_y(view_camera[0]) * self.background_to_view_ratio

layer_x(self.layer_id, self.x)
layer_y(self.layer_id, self.y)