/// Formats a frame count as seconds and frames.
function funGetTimeString(frame_count) {
	var frames_per_second = 60
	var seconds = floor(frame_count / frames_per_second)
	var frames = floor(frame_count % frames_per_second)
	var seconds_text = string(seconds)
	var frames_text = string(frames)

	if (seconds < 10) {
		seconds_text = "0" + seconds_text
	}
	if (frames < 10) {
		frames_text = "0" + frames_text
	}

	return seconds_text + ":" + frames_text
}
