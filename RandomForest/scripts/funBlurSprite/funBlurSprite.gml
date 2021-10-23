function funBlurSprite(surf, ksize, width, height, radius, std, b_color_r, b_color_g, b_color_b, b_part) {
	var size_location = shader_get_uniform(shBlur, "size")
	var ksize_location = shader_get_uniform(shBlur, "kSize")
	var std_location = shader_get_uniform(shBlur, "std")
	var b_part_location= shader_get_uniform(shBlur, "b_part")
	var b_color_location= shader_get_uniform(shBlur, "b_color")


	var surf_c = surface_create(width, height)
	surface_copy(surf_c, 0, 0, surf)
	surface_set_target(surf_c)
	shader_set(shBlur)
	shader_set_uniform_f(size_location, width, height, radius)
	shader_set_uniform_i(ksize_location, ksize)
	shader_set_uniform_f(std_location, std)
	shader_set_uniform_f(b_part_location, b_part)
	shader_set_uniform_f(b_color_location, b_color_r, b_color_g, b_color_b, 1.0)
	
	draw_surface(surf_c, 0, 0)
	
	shader_reset()
	surface_reset_target()
	
	return sprite_create_from_surface(
		surf_c,
		0, 0, width, height, 
		0, 0, 0, 0
	)
}