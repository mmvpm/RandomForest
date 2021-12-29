// set up font
draw_set_halign(fa_middle)
draw_set_valign(fa_middle)
draw_set_font(global.default_font_24)

// draw text
self.text_scale = self.text_size / 24
var text_x = self.x - camera_get_view_x(view_camera[0])
var text_y = self.y - camera_get_view_y(view_camera[0])
draw_text_transformed_color(text_x, text_y, self.text, self.text_scale, self.text_scale, 0, c_white, c_white, c_white, c_white, self.text_alpha_current)