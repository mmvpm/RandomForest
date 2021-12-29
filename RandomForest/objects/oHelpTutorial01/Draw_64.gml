// draw arrow keys
var arrow_up_x = self.arrow_keys_start_x + self.key_width + self.key_shift
var arrow_up_y = self.arrow_keys_start_y
draw_sprite_ext(sKeyArrowUp, 0, arrow_up_x, arrow_up_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)

var arrow_left_x = self.arrow_keys_start_x
var arrow_left_y = self.arrow_keys_start_y + self.key_height + self.key_shift
draw_sprite_ext(sKeyArrowLeft, 0, arrow_left_x, arrow_left_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)

var arrow_down_x = self.arrow_keys_start_x + self.key_width + self.key_shift
var arrow_down_y = self.arrow_keys_start_y + self.key_height + self.key_shift
draw_sprite_ext(sKeyArrowDown, 0, arrow_down_x, arrow_down_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)

var arrow_right_x = self.arrow_keys_start_x + 2 * (self.key_width + self.key_shift)
var arrow_right_y = self.arrow_keys_start_y + self.key_height + self.key_shift
draw_sprite_ext(sKeyArrowRight, 0, arrow_right_x, arrow_right_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)

// set up font for controls
draw_set_halign(fa_left)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_24)

// type arrow keys text
var arrow_keys_text_x = self.arrow_keys_start_x + 3 * (self.key_width + self.key_shift)
var arrow_keys_text_y = self.arrow_keys_start_y + (self.key_height + self.key_shift) - 5
draw_text_transformed_color(arrow_keys_text_x, arrow_keys_text_y, self.arrow_keys_text, self.text_scale_16, self.text_scale_16, 0, c_white, c_white, c_white, c_white, self.text_alpha)

// type collect all coins text
draw_set_halign(fa_middle)
draw_text_transformed_color(self.collect_coins_start_x, self.collect_coins_start_y, self.collect_all_coins_text, self.text_scale_16, self.text_scale_16, 0, c_white, c_white, c_white, c_white, self.text_alpha)