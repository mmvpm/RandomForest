/// Returns one wave crossing the enemy's body, once per enemy per wave.
function funPlayerStompWaveDamage() {
    for (var i = 0; i < instance_number(oPlayerStompWave); ++i) {
        var wave = instance_find(oPlayerStompWave, i)
        if (ds_list_find_index(wave.hit_enemies, self.id) != -1) continue
        var near_x = clamp(wave.x, self.bbox_left, self.bbox_right)
        var near_y = clamp(wave.y, self.bbox_top, self.bbox_bottom)
        var near_distance = point_distance(wave.x, wave.y, near_x, near_y)
        var far_x = max(abs(self.bbox_left - wave.x), abs(self.bbox_right - wave.x))
        var far_y = max(abs(self.bbox_top - wave.y), abs(self.bbox_bottom - wave.y))
        var far_distance = sqrt(far_x * far_x + far_y * far_y)
        if (near_distance <= wave.radius and far_distance >= wave.previous_radius) {
            ds_list_add(wave.hit_enemies, self.id)
            return wave
        }
    }
    return noone
}
