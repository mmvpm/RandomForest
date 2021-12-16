function funBlurSurface(surf, ksize, width, height, radius, std, b_color_r, b_color_g, b_color_b, b_part) {
	var size_location = shader_get_uniform(shBlur, "size")
	var ksize_location = shader_get_uniform(shBlur, "kSize")
	var std_location = shader_get_uniform(shBlur, "std")
	var b_part_location= shader_get_uniform(shBlur, "b_part")
	var b_color_location= shader_get_uniform(shBlur, "b_color")
	var direction_location = shader_get_uniform(shBlur, "direction")

	gpu_set_blendenable(false)

	shader_set(shBlur)
	shader_set_uniform_f(size_location, width, height, radius)
	shader_set_uniform_i(ksize_location, ksize)
	shader_set_uniform_f(std_location, std)
	shader_set_uniform_f(b_part_location, b_part)
	shader_set_uniform_f(b_color_location, b_color_r, b_color_g, b_color_b, 1.0)
	
	var surf_x = surface_create(width, height)
	
	surface_set_target(surf_x)
	
	shader_set_uniform_f(direction_location, 1.0, 0.0)
	draw_surface(surf, 0, 0)
	
	surface_reset_target()
	
	var surf_y = surface_create(width, height)
	surface_set_target(surf_y)
	
	shader_set_uniform_f(direction_location, 0.0, 1.0)
	draw_surface(surf_x, 0, 0)

	shader_reset()
	surface_reset_target()
	
	surface_free(surf_x)
	
	gpu_set_blendenable(true)
	
	return surf_y
}