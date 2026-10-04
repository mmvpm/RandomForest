/// Shows a compact cooldown above the player, without adding a permanent HUD row.
if (!self.stomp_unlocked or self.stomp_cooldown_counter <= 0 or !self.visible
	or self.image_alpha == 0 or self.state == player_states.die
	or self.state == player_states.stomp or self.state == player_states.story_transform) exit
var cam = view_camera[0]
var pos_x = clamp(round(self.x - camera_get_view_x(cam)), 36, 444)
var pos_y = clamp(round(self.bbox_top - camera_get_view_y(cam) - 16), 12, 244)
gpu_set_tex_filter(false)
draw_set_alpha(0.85)
draw_sprite(sKeySpace, 0, pos_x - 24, pos_y)
draw_set_font(global.damage_font_10)
draw_set_color(c_white)
draw_set_halign(fa_left)
draw_set_valign(fa_top)
draw_text(pos_x + 14, pos_y, string(ceil(self.stomp_cooldown_counter / game_get_speed(gamespeed_fps))))
draw_set_alpha(1)
