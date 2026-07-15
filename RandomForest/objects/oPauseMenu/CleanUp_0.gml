// Release the pause screenshot on restart, room change, or game shutdown.
if (sprite_exists(self.screenshot)) {
	sprite_delete(self.screenshot)
}
self.screenshot = noone
