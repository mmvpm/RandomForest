// Commit only when the opening finishes; retries before that replay the opening.
++self.elapsed
if (self.elapsed >= self.duration) {
	global.campaign_intro_seen = true
	funSaveGameState()
	instance_activate_all()
	funOpenLevel(0)
	instance_destroy()
}
