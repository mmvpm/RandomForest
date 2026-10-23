/// @description Background moving

self.x = camera_get_view_x(view_camera[0]) * self.background_to_view_ratio_x
self.y = camera_get_view_y(view_camera[0]) * self.background_to_view_ratio_y

layer_x(self.layer_id, self.x)
layer_y(self.layer_id, self.y)

// Fade only the evening backdrop with the same visible rain amount; no shaders or surfaces.
if (self.rain_background_id != -1) {
    layer_x(self.rain_layer_id,self.x)
    layer_y(self.rain_layer_id,self.y)
    var amount = 0
    if (instance_exists(oAmbientSystem))
        amount = clamp(oAmbientSystem.weather.rain*2,0,1)
    layer_background_alpha(self.rain_background_id,amount)
}
