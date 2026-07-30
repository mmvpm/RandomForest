// init
self.layer_id = layer_get_id("Background")

// compute layer speed
var view_width = camera_get_view_width(view_camera[0])
var view_height = camera_get_view_height(view_camera[0])
var background_width = sprite_get_width(sBackground_x13)
var background_height = sprite_get_height(sBackground_x13)

// Independent ratios keep every background edge covered for arbitrary room aspect ratios.
self.background_to_view_ratio_x = max(0, (room_width - background_width) / max(1, room_width - view_width))
self.background_to_view_ratio_y = max(0, (room_height - background_height) / max(1, room_height - view_height))
