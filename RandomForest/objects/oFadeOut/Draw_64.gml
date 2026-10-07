// set up
draw_set_color(c_black)
draw_set_alpha(self.global_alpha)

// draw black rectangle
var width = camera_get_view_width(view_camera[0])
var height = camera_get_view_height(view_camera[0])
draw_rectangle(0, 0, width, height, 0)

// reset
draw_set_alpha(1.0)
draw_set_color(c_white)

// Step may release the next scene only after this fully opaque GUI draw.
if (self.global_alpha >= 1) self.black_frame_drawn = true
