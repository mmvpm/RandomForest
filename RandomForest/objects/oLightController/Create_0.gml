self.light_u_pos = shader_get_uniform(shLight, "u_pos")
self.light_power = shader_get_uniform(shLight, "power")
self.light_radius = shader_get_uniform(shLight, "radius")
self.light_dir = shader_get_uniform(shLight, "u_dir")
self.light_fov = shader_get_uniform(shLight, "u_fov")

self.shadow_u_pos = shader_get_uniform(shShadow, "u_pos")

vertex_format_begin()
vertex_format_add_position_3d()
self.vf = vertex_format_end()
self.vb = vertex_create_buffer()

self.shadow_surf = noone
