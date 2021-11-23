function funCreateLight(
	x_pos, y_pos, object, 
	radius = noone, power = noone, color = noone, 
	count = noone, dir = noone, fov = noone, step = noone
) {
	var inst = instance_create_layer(x_pos, y_pos, "Lighting", object)
	if (radius != noone) {
		inst.light_radius = radius
	}
	
	if (power != noone) {
		inst.light_power = power
	}
	
	if (color != noone) {
		inst.light_color = color
	}
	
	if (dir != noone) {
		inst.light_dir = dir
	}
	
	if (fov != noone) {
		inst.light_fov = fov
	}
	
	if (count != noone) {
		inst.light_count = count
	}
	
	if (step != noone) {
		inst.light_step = step
	}
	
	return inst
}