// draw c key
draw_sprite_ext(sKeyC, 0, self.c_key_start_x, self.c_key_start_y, self.key_scale, self.key_scale, 0, c_white, self.sprite_alpha)

// set up font for controls
draw_set_halign(fa_left)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_24)

// type c key text
var c_key_text_x = self.c_key_start_x + (self.key_width + self.key_shift)
var c_key_text_y = self.c_key_start_y + self.key_height / 2 - 1
draw_text_transformed_color(c_key_text_x, c_key_text_y, self.c_key_text, self.text_scale_16, self.text_scale_16, 0, c_white, c_white, c_white, c_white, self.text_alpha)

// type help text
draw_set_halign(fa_middle)
draw_text_transformed_color(self.help_start_x, self.help_start_y, self.help_text, self.text_scale_16, self.text_scale_16, 0, c_white, c_white, c_white, c_white, self.text_alpha)
