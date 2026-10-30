/// Covers background glows with the live collision geometry, before drawing actors.
draw_set_alpha(1)
draw_set_color(c_black)
with (oSolid) draw_rectangle(bbox_left, bbox_top, bbox_right + 1, bbox_bottom + 1, false)
draw_set_color(c_white)
