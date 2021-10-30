function funPlayerCollideWithSolid(new_x, new_y) {	
	var result = false
	
	var solid_list = ds_list_create()
	var solid_list_size = instance_place_list(new_x, new_y, oSolid, solid_list, false)
	for (var i = 0; i < solid_list_size; ++i) {
		result |= solid_list[|i].is_solid // at least one true
	}
	ds_list_destroy(solid_list)
	
	return result
}