/// @description Game window resizing

global_scale = 3
window_width_scaled = room_width * global_scale
window_height_scaled = room_height * global_scale
window_set_size(window_width_scaled, window_height_scaled)
alarm[0] = true // for centering