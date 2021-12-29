// draw background
var cam = view_camera[0]
var cam_h = camera_get_view_height(cam)
var cam_w = camera_get_view_width(cam)
draw_rectangle_color(0, 0, cam_w, cam_h, c_black, c_black, c_black, c_black, 0)

// draw arrow keys
var arrow_keys_start_x = self.start_x
var arrow_keys_start_y = self.start_y

var arrow_up_x = arrow_keys_start_x + self.key_width + self.key_shift
var arrow_up_y = arrow_keys_start_y
draw_sprite_ext(sKeyArrowUp, 0, arrow_up_x, arrow_up_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)

var arrow_left_x = arrow_keys_start_x
var arrow_left_y = arrow_keys_start_y + self.key_height + self.key_shift
draw_sprite_ext(sKeyArrowLeft, 0, arrow_left_x, arrow_left_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)

var arrow_down_x = arrow_keys_start_x + self.key_width + self.key_shift
var arrow_down_y = arrow_keys_start_y + self.key_height + self.key_shift
draw_sprite_ext(sKeyArrowDown, 0, arrow_down_x, arrow_down_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)

var arrow_right_x = arrow_keys_start_x + 2 * (self.key_width + self.key_shift)
var arrow_right_y = arrow_keys_start_y + self.key_height + self.key_shift
draw_sprite_ext(sKeyArrowRight, 0, arrow_right_x, arrow_right_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)

// draw X key
var x_key_start_x = arrow_keys_start_x + self.key_width + self.key_shift
var x_key_start_y = arrow_keys_start_y + 2 * (self.key_height + self.key_shift) + self.line_interval
draw_sprite_ext(sKeyX, 0, x_key_start_x, x_key_start_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)

// draw C key
var c_key_start_x = x_key_start_x
var c_key_start_y = x_key_start_y + (self.key_height + self.key_shift) + self.line_interval
draw_sprite_ext(sKeyC, 0, c_key_start_x, c_key_start_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)

// draw F key (fullscreen)
var f_key_start_x = c_key_start_x
var f_key_start_y = c_key_start_y + (self.key_height + self.key_shift) + self.line_interval
draw_sprite_ext(sKeyF, 0, f_key_start_x, f_key_start_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)


// set up font for controls
draw_set_halign(fa_left)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_24)

// type arrow keys text
var arrow_keys_text_x = self.start_x + 3 * (self.key_width + self.key_shift)
var arrow_keys_text_y = self.start_y + (self.key_height + self.key_shift) + 7
draw_text_transformed_color(arrow_keys_text_x, arrow_keys_text_y, self.shift_text, self.text_scale_20, self.text_scale_20, 0, c_white, c_white, c_white, c_white, self.text_alpha)
draw_text_transformed_color(arrow_keys_text_x + 30, arrow_keys_text_y - 7 - 3, self.arrow_keys_text, self.text_scale_20, self.text_scale_20, 0, c_white, c_white, c_white, c_white, self.text_alpha)


// type X key text
var x_key_text_x = arrow_keys_text_x
var x_key_text_y = x_key_start_y + self.magic_shift
draw_text_transformed_color(x_key_text_x, x_key_text_y, self.x_key_text, self.text_scale_20, self.text_scale_20, 0, c_white, c_white, c_white, c_white, self.text_alpha)

// type C key text
var c_key_text_x = arrow_keys_text_x
var c_key_text_y = c_key_start_y + self.magic_shift
draw_text_transformed_color(c_key_text_x, c_key_text_y, self.c_key_text, self.text_scale_20, self.text_scale_20, 0, c_white, c_white, c_white, c_white, self.text_alpha)

// type F key text (fullscreen)
var f_key_text_x = arrow_keys_text_x
var f_key_text_y = f_key_start_y + self.magic_shift
draw_text_transformed_color(f_key_text_x, f_key_text_y, self.fullscreen_text, self.text_scale_20, self.text_scale_20, 0, c_white, c_white, c_white, c_white, self.text_alpha)


// set up font for continue
draw_set_halign(fa_middle)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_12)

// type text
self.text_continue_alpha_current =
	( sin(self.tick_counter * pi / 60) + 1 ) / 2                  // [-1, 1] -> [0, 1]
	* self.text_continue_alpha_max + self.text_continue_alpha_min // [0, 1] -> [min, max]
draw_text_color(self.room_center_x, cam_h - 20, self.continue_text, c_white, c_white, c_white, c_white, self.text_continue_alpha_current)


// update time
self.tick_counter += 1