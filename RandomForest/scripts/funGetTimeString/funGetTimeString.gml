function funGetTimeString(time) {
	var minutes = floor(time / 60)
	var seconds = floor(time % 60)
	var string_minutes = string(minutes)
	var string_seconds = string(seconds)

	if (minutes < 10) {
		string_minutes = "0" + string_minutes
	}
	if (seconds < 10) {
		string_seconds = "0" + string_seconds
	}

	return string_minutes + ":" + string_seconds
}