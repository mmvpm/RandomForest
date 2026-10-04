/// Keeps the required story action visible after its dialogue panel closes.
if (!self.dialogue_finished or self.portal_ready or self.transform_running) exit
draw_set_font(global.dialogue_font_12)
draw_set_halign(fa_center)
draw_set_valign(fa_bottom)
draw_set_color(c_white)
draw_set_alpha(1)
draw_text(240, 246, "Space: превращение (на земле)")
draw_set_halign(fa_left)
draw_set_valign(fa_top)
