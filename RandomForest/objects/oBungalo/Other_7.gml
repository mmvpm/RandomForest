switch (self.state) {
	case bungalo_states.attack:
		self.attack_animation_ended = true
		break
	case bungalo_states.hurt:
		self.hurt_animation_ended = true
		break
	case bungalo_states.die:
		self.die_animation_ended = true
		break
}