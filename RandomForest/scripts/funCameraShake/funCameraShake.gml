function funCameraShake(power = 1, duration = 30, delay = 3) {
	oCamera.camera_shake_counter = duration
	oCamera.camera_shake_power = power
	oCamera.camera_shake_delay = delay
}