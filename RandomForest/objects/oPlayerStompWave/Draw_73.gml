/// Refracts only the moving boundary after world drawing and before the GUI.
if (!surface_exists(application_surface) or self.radius <= 0) exit
var cam = view_camera[0]
var view_x = camera_get_view_x(cam), view_y = camera_get_view_y(cam)
var view_w = camera_get_view_width(cam), view_h = camera_get_view_height(cam)
var surf_w = surface_get_width(application_surface), surf_h = surface_get_height(application_surface)
if (surface_exists(self.wave_surface)
    and (surface_get_width(self.wave_surface) != surf_w or surface_get_height(self.wave_surface) != surf_h)) {
    surface_free(self.wave_surface)
    self.wave_surface = -1
}
if (!surface_exists(self.wave_surface)) self.wave_surface = surface_create(surf_w, surf_h)
if (!surface_exists(self.wave_surface)) exit
surface_copy(self.wave_surface, 0, 0, application_surface)
if (shader_is_compiled(shStompWave)) {
    shader_set(shStompWave)
    shader_set_uniform_f(self.size_uniform, surf_w, surf_h)
    shader_set_uniform_f(self.center_uniform, (self.x - view_x) * surf_w / view_w, (self.y - view_y) * surf_h / view_h)
    shader_set_uniform_f(self.radius_uniform, self.radius * surf_w / view_w)
    draw_surface_ext(self.wave_surface, view_x, view_y, view_w / surf_w, view_h / surf_h, 0, c_white, 1)
    shader_reset()
}
