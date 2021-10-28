switch (self.state) {
	case skeleton_states.react:
		self.react_animation_ended = true
		break
	case skeleton_states.attack:
		self.attack_animation_ended = true
		break
	case skeleton_states.hurt:
		self.hurt_animation_ended = true
		break
	case skeleton_states.die:
		self.die_animation_ended = true
		break
}