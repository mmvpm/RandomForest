/// Repeats the action hint only after the dialogue input grace period.
if (!self.awaiting_transform or self.transform_running or self.space_guard > 0) exit
draw_set_font(global.dialogue_font_12)
draw_set_halign(fa_center)
draw_set_valign(fa_bottom)
draw_set_color(c_white)
draw_set_alpha(1)
draw_text(240, 246, "Пробел: превращение (на земле)")
draw_set_halign(fa_left)
draw_set_valign(fa_top)
