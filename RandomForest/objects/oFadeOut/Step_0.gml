self.global_alpha += self.alpha_step

if (self.global_alpha >= 1) {
	instance_destroy()
	if (self.end_function != undefined) {
		self.end_function()
	}
}