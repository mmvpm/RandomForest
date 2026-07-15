// Release the dynamic screenshot sprite when aiming ends or the room closes.
if (sprite_exists(self.screenshot)) {
	sprite_delete(self.screenshot)
}
self.screenshot = noone
