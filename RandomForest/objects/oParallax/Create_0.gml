/// Assigns the room's theme before drawing and computes its parallax coverage.
self.layer_id = layer_get_id("Background")
var theme = funCurrentLevelTheme()
var background_sprite = funThemeBackground(theme)
layer_background_sprite(layer_background_get_id(self.layer_id), background_sprite)
// Generated tilemaps already receive their themed art during construction.
if (room != rGeneratedLevel) funApplyRoomTheme(theme)

// compute layer speed
var view_width = camera_get_view_width(view_camera[0])
var view_height = camera_get_view_height(view_camera[0])
var background_width = sprite_get_width(background_sprite)
var background_height = sprite_get_height(background_sprite)

// Independent ratios keep every background edge covered for arbitrary room aspect ratios.
self.background_to_view_ratio_x = max(0, (room_width - background_width) / max(1, room_width - view_width))
self.background_to_view_ratio_y = max(0, (room_height - background_height) / max(1, room_height - view_height))
