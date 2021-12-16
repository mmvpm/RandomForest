// attack
self.damage = 1

// move
self.current_speed = 6
self.flight_range = 360
self.flight_time_counter = self.flight_range / self.current_speed

// collide with enemy
self.collide_with_enemy_counter = 3

// start effect
self.effect_created = false

// for camera shake on landing
self.was_shake_effect = false

// self.shift_of_player_y

// self.current_angle
// self.image_angle

var inst = instance_create_layer(self.x, self.y, "Bloom", oSwordBloom)
inst.following = self