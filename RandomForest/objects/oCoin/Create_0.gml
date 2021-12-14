self.flight_speed = 20
self.is_collected = false // becomes true when collide with Player

// bloom
var inst = instance_create_depth(self.x, self.y, self.depth + 5, oCoinBloom)
inst.following = self
