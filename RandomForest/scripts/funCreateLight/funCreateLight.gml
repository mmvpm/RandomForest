function funCreateLight(x_pos, y_pos, object, radius = noone, power = noone, color = noone) {
	var inst = instance_create_layer(x_pos, y_pos, "Lighting", object)
	if (radius != noone) {
		inst.radius = radius
	}
	
	if (power != noone) {
		inst.light_power = power
	}
	
	if (color != noone) {
		inst.light_color = color
	}
	
	return inst
}