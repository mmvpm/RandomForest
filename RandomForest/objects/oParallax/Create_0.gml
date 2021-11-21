// init
self.layer_id = layer_get_id("Background")

// compute layer speed
var view_width = camera_get_view_width(view_camera[0])
var background_width = sprite_get_width(sBackground_x13)
self.background_to_view_ratio = max(0, (room_width - background_width) / (room_width - view_width))