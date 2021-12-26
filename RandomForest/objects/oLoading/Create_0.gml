/// @description Initializing the game

// Load saved state

funLoadGameState()

// disable anti-aliasing
font_add_enable_aa(false)


//Game window resizing

funResizeWindow()
funUpdateFullscreen()
alarm[0] = true // for centering


// Temporary config

global.default_font = font_add("glasstown.ttf", 24, true, false, 32, 128)

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