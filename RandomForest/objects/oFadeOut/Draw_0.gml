// set up
draw_set_color(c_black)
draw_set_alpha(self.global_alpha)

// draw black rectangle
draw_rectangle(0, 0, room_width, room_height, 0)

// reset
draw_set_alpha(1.0)
draw_set_color(c_white)