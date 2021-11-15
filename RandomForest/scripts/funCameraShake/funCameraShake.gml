function funCameraShake(duration = 30, delay = 3, power = 1) {
	if (power < oCamera.camera_shake_power) {
		return
	}
	if (duration < oCamera.camera_shake_counter) {
		return
	}
	oCamera.camera_shake_counter = duration
	oCamera.camera_shake_power = power
	oCamera.camera_shake_delay = delay
}