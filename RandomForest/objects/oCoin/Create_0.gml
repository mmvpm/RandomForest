self.flight_speed = 20
self.is_collected = false // becomes true when collide with Player

self.inner_light = funCreateLight(self.x, self.y, oCoinLight)
self.ambient_light = funCreateLight(self.x, self.y, oLight, noone, noone, oCoinLight.light_color)
