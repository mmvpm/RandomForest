/// @description On collision with Player

//if (!self.is_collected) {
	self.is_collected = true
	oCoinCollector.coins_collected += 1
	move_towards_point(150, 450, 1)
//}