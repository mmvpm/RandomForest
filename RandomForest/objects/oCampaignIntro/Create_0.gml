// Own only the opening overlay; no gameplay room or achievements start yet.
self.elapsed = 0
self.duration = round(funCampaignIntroSetting("duration_seconds", 5) * 60)
self.spacing = funCampaignIntroSetting("grid_spacing", 30)
self.wave_frames = funCampaignIntroSetting("wave_seconds", 2.8) * 60
self.initial_hold_frames = funCampaignIntroSetting("initial_hold_seconds", 0.4) * 60
self.fade_in_frames = funCampaignIntroSetting("fade_in_seconds", 0.35) * 60
self.fade_out_frames = funCampaignIntroSetting("fade_out_seconds", 0.5) * 60
self.turn_fps = funCampaignIntroSetting("turn_fps", 20)
var width = camera_get_view_width(view_camera[0])
var height = camera_get_view_height(view_camera[0])
var half_columns = ceil(width / (2 * self.spacing))
var half_rows = ceil(height / (2 * self.spacing))
var max_distance = point_distance(0, 0, half_columns * self.spacing, half_rows * self.spacing)
self.tiles = []
for (var row = -half_rows; row <= half_rows; ++row) {
	for (var column = -half_columns; column <= half_columns; ++column) {
		var dx = column * self.spacing
		var dy = row * self.spacing
		array_push(self.tiles, {
			x: width / 2 + dx,
			y: height / 2 + dy,
			arrival: (column == 0 and row == 0) ? 0
				: self.initial_hold_frames + point_distance(0, 0, dx, dy) / max_distance * self.wave_frames,
			phase: (column == 0 and row == 0) ? 0 : irandom(19)
		})
	}
}
instance_deactivate_all(true)
instance_activate_object(oFullscreen)
instance_activate_object(oDebug)
