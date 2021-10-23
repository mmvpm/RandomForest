/// @description Initializing the game


//Game window resizing

global.scale = 3
window_width_scaled = room_width * global.scale
window_height_scaled = room_height * global.scale
window_set_size(window_width_scaled, window_height_scaled)
alarm[0] = true // for centering


// Temporary config

global.key_move_left = vk_left
global.key_move_right = vk_right
global.key_jump = vk_up
global.key_attack = ord("X")
global.key_pause = vk_escape