// init
self.layer_id = layer_get_id("Background")
self.background_id = layer_background_get_id(layer_id)

// resize
self.background_scale = 1.3
layer_background_xscale(self.background_id, self.background_scale)
layer_background_yscale(self.background_id, self.background_scale)

// compute layer speed
var view_width = camera_get_view_width(view_camera[0])
var background_width = sprite_get_width(sBackground) * self.background_scale
self.background_to_room_scale_ratio = (room_width - background_width) / (room_width - view_width)