/// @description Draw health bar

var float_health = self.health / self.max_health // in [0, 1]

var strip_index = 5 // index of health strip in sprite ~ last index
var bar_image_index = ceil(float_health * (strip_index - 1)) // [0, 1] -> {0, 1, 2, 3, 4}

var strip_width = 12 + float_health * 49 + 1 // in [13, 62], where 62 is sHealthBar width
var strip_height = 11 // sHealthBar height

var bar_x = 12 // x coordinate on the screen
var bar_y = 12 // y coordinate on the screen

draw_sprite(sHealthBar, bar_image_index, bar_x, bar_y)
draw_sprite_part(sHealthBar, strip_index, 0, 0, strip_width, strip_height, bar_x, bar_y)