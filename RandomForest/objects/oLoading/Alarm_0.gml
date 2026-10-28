/// @description Go to next level

window_center()
alarm[0] = false

// go to menu
if (global.ending_stage == 1) funOpenStoryEnding(true)
else if (global.special_level_completed and global.ending_stage == 0) funOpenStoryEnding()
else room_goto(rMenu)
