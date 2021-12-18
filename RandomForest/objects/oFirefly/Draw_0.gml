var b = layer_get_id("Background")
var b_x = layer_get_x(b)
var b_y = layer_get_y(b)

draw_sprite_ext(self.sprite_index, 0, b_x + self.x, b_y + self.y, 1, 1, 0, c_white, 0.6)