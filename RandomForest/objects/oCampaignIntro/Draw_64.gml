// Pixel-aligned tiles extend beyond both edges, so the field fills the viewport.
var width = camera_get_view_width(view_camera[0])
var height = camera_get_view_height(view_camera[0])
gpu_set_tex_filter(false)
draw_set_alpha(1)
draw_set_color(c_black)
draw_rectangle(0, 0, width, height, false)
var fade_out = clamp((self.duration - self.elapsed) / self.fade_out_frames, 0, 1)
var origin_x = sprite_get_xoffset(sPlayerLightTurn)
var origin_y = sprite_get_yoffset(sPlayerLightTurn)
var center_x = sprite_get_width(sPlayerLightTurn) / 2
var center_y = sprite_get_height(sPlayerLightTurn) / 2
for (var i = 0; i < array_length(self.tiles); ++i) {
	var tile = self.tiles[i]
	var age = self.elapsed - tile.arrival
	if (age < 0) continue
	var alpha = clamp(age / self.fade_in_frames, 0, 1) * fade_out
	var frame = floor(age * self.turn_fps / 60 + tile.phase) mod 20
	draw_sprite_ext(sPlayerLightTurn, frame,
		round(tile.x + origin_x - center_x),
		round(tile.y + origin_y - center_y),
		1, 1, 0, c_white, alpha)
}
draw_set_color(c_white)
draw_set_alpha(1)
