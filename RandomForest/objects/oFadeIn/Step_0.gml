self.global_alpha -= self.alpha_step

if (self.global_alpha <= 0) {
	instance_destroy()
}