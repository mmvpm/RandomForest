switch (self.state) {
	case player_states.idle:
		self.idle_animation_ended = true
		break
	case player_states.attack:
		self.attack_animation_ended = true
		break
	case player_states.hurt:
		self.hurt_animation_ended = true
		break
	case player_states.die:
		self.die_animation_ended = true
		break
}