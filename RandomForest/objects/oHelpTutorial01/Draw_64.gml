// draw arrow keys
draw_sprite_ext(sKeyX, 0, self.x_key_start_x, self.x_key_start_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)


// set up font for controls
draw_set_halign(fa_left)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_24)

// type arrow keys text
var x_key_text_x = self.x_key_start_x + (self.key_width + self.key_shift)
var x_key_text_y = self.x_key_start_y + self.key_height / 2 - 1 //+ self.key_shift)
draw_text_transformed_color(x_key_text_x, x_key_text_y, self.x_key_text, self.text_scale_16, self.text_scale_16, 0, c_white, c_white, c_white, c_white, self.text_alpha)