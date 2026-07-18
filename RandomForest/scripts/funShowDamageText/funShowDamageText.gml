/// @description Create a short damage number above the damaged instance.
/// @param {Id.Instance} damaged_instance
/// @param {Real} damage_amount
/// @param {Bool} is_player
function funShowDamageText(damaged_instance, damage_amount, is_player) {
	if (damage_amount <= 0) {
		return noone
	}

	var cam = view_camera[0]
	var view_left = camera_get_view_x(cam)
	var view_top = camera_get_view_y(cam)
	var view_right = view_left + camera_get_view_width(cam)

	var spawn_x = round(clamp(damaged_instance.x, view_left + 8, view_right - 8))
	var spawn_y = round(max(damaged_instance.bbox_top - 4, view_top + 8))
	var damage_text = instance_create_depth(
		spawn_x,
		spawn_y,
		damaged_instance.depth - 1,
		oDamageText
	)

	var displayed_damage = floor(damage_amount)
	damage_text.text = "-" + string(displayed_damage)
	damage_text.text_color = is_player
		? c_white
		: make_color_rgb(182, 190, 194)

	return damage_text
}
