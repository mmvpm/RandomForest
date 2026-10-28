/// Requires a fresh approach after opening, even if the player waited in the portal.
if (oBlackRoomController.is_ending) {
	if (oBlackRoomController.portal_closing) {
		self.scale = max(0, self.scale - self.scale_open_speed)
		self.image_xscale = self.x_factor * self.scale
		self.image_yscale = self.y_factor * self.scale
		oBlackRoomController.portal_closed = self.scale == 0
	}
	else if (oBlackRoomController.portal_ready) funUpdatePortalVisual(true)
	else {
		self.scale = 0
		self.image_xscale = 0
		self.image_yscale = 0
	}
	exit
}
var opened = oBlackRoomController.portal_ready
if (opened and !self.is_opened) {
	self.departed = false
}
self.is_opened = opened
funUpdatePortalVisual(opened)

// Only arm once fully grown: its expanding mask must not swallow a waiting player.
if (!opened or self.scale < 1 or self.exiting) {
	exit
}
var touching = place_meeting(self.x, self.y, oPlayer)
if (!touching) {
	self.departed = true
}
if (!touching or !self.departed or !oPlayer.visible or oPlayer.image_alpha == 0) {
	exit
}

self.exiting = true
oBlackRoomController.exiting = true
oPlayer.image_alpha = 0
var fade = instance_create_depth(0, 0, -10, oFadeOut)
fade.alpha_step = 1 / (60 * funBlackRoomSetting(oBlackRoomController.scene, "fade_seconds"))
fade.hold_black_frame = true
fade.end_function = funFinishBlackRoomScene
