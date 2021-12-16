self.flight_speed = 20
self.is_collected = false // becomes true when collide with Player

// bloom
var inst = instance_create_layer(self.x, self.y, "Bloom", oCoinBloom)
inst.following = self
