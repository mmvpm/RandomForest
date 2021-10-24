switch (self.state) {
	case slime_states.attack:
		self.attack_animation_ended = true
		break
	case slime_states.hurt:
		self.hurt_animation_ended = true
		break
	case slime_states.die:
		self.die_animation_ended = true
		break
}