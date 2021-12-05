/// @description Initializing the game

// Load saved state

funLoadGameState()


//Game window resizing

global.scale = 3

var cam = room_get_camera(rLevel00, 0)
var cam_width = camera_get_view_width(cam)
var cam_height = camera_get_view_height(cam)
var window_width_scaled = cam_width * global.scale
var window_height_scaled = cam_height * global.scale


for (var i = room_first; i != -1; i = room_next(i)) {
	var viewport = room_get_viewport(i, 0)
	room_set_camera(i, 0, cam)
	room_set_viewport(i, 0,
		viewport[0], viewport[1], viewport[2],
		window_width_scaled, window_height_scaled
	)
}

surface_resize(application_surface, cam_width, cam_height)

window_set_size(window_width_scaled, window_height_scaled)

funUpdateFullscreen()
alarm[0] = true // for centering

// Temporary config

global.key_move_left = vk_left
global.key_move_right = vk_right
global.key_jump = vk_up
global.key_fall = vk_down
global.key_attack = ord("X")
global.key_tap_attack = ord("C")

global.key_arrow_left = vk_left
global.key_arrow_right = vk_right
global.key_arrow_up = vk_up
global.key_arrow_down = vk_down

global.key_pause = vk_escape
global.key_fullscreen = ord("F")