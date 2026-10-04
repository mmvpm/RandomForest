/// Prevents optional room music from leaking into menus or restarted levels.
funStopBlackRoomMusic()
// Leaving for a menu discards any reward that was never committed by the portal.
global.black_room_context = undefined
