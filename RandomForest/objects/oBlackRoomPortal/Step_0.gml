/// Requires a fresh approach after opening, even if the player waited in the portal.
var opened = oBlackRoomController.dialogue_finished
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
fade.end_function = funFinishBlackRoomScene
