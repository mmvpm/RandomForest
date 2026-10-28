/// Prevents optional room music from leaking into menus or restarted levels.
funStopBlackRoomMusic(self.scene)
// Leaving for a menu discards any reward that was never committed by the portal.
if (global.black_room_context == self.context) global.black_room_context = undefined
