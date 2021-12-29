// set up font for controls
draw_set_halign(fa_middle)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_24)

// type help text
draw_text_transformed_color(self.help_top_start_x, self.help_top_start_y, self.help_top_text, self.text_scale_16, self.text_scale_16, 0, c_white, c_white, c_white, c_white, self.text_alpha)

draw_text_transformed_color(self.help_bottom_start_x, self.help_bottom_start_y, self.help_bottom_text, self.text_scale_16, self.text_scale_16, 0, c_white, c_white, c_white, c_white, self.text_alpha)
