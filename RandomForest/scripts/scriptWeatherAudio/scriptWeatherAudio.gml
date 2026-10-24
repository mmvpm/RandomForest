/// Creates one session owner for the two approved streaming recordings.
function funWeatherAudioCreate() {
    self.channels = [
        {file:"weather_audio/rain.ogg", asset:-1, voice:-1, gain:0, quiet:0},
        {file:"weather_audio/drips.ogg", asset:-1, voice:-1, gain:0, quiet:0}
    ]
}

/// Releases a channel before destroying its streaming asset.
function funWeatherAudioRelease(channel) {
    if (channel.voice != -1) audio_stop_sound(channel.voice)
    if (channel.asset != -1) audio_destroy_stream(channel.asset)
    channel.voice = -1
    channel.asset = -1
    channel.gain = 0
    channel.quiet = 0
}

/// Stops weather alone on mute or shutdown without touching music and gameplay effects.
function funWeatherAudioStop() {
    for (var i = 0; i < array_length(self.channels); ++i) funWeatherAudioRelease(self.channels[i])
}

/// Keeps rain audible until its quiet tail can overlap the incoming residual drops.
function funWeatherAudioFamily(weather) {
    var peak = weather.rain_kind == "storm" ? 1 : 0.5
    if (weather.phase == "drips" and weather.target_rain == 0 and weather.rain <= peak * 0.12) return "drips"
    if (funWeatherIsRaining(weather)) return weather.rain_kind
    return weather.phase == "drips" ? "drips" : ""
}

/// Starts only audible recordings and frees each outgoing stream after its 1.2-second fade.
function funWeatherAudioChannel(channel, gain, dt) {
    if (channel.voice != -1 and !audio_is_playing(channel.voice) and !audio_is_paused(channel.voice))
        funWeatherAudioRelease(channel)
    if (gain > 0 and channel.voice == -1) {
        channel.asset = audio_create_stream(channel.file)
        if (channel.asset < 0) return;
        channel.voice = audio_play_sound(channel.asset, -5, true, 0)
        if (channel.voice < 0) { funWeatherAudioRelease(channel); return; }
    }
    if (channel.voice == -1) return;
    if (audio_is_paused(channel.voice)) audio_resume_sound(channel.voice)
    if (channel.gain != gain) {
        channel.gain = gain
        audio_sound_gain(channel.voice, gain, 1200)
    }
    channel.quiet = gain > 0 ? 0 : channel.quiet + dt
    if (channel.quiet >= 1.3) funWeatherAudioRelease(channel)
}

/// Follows session weather and retains the same recording through levels, pause and aiming.
function funWeatherAudioStep() {
    if (!global.sfx_enabled) { funWeatherAudioStop(); return; }
    if (!instance_exists(oAmbientSystem) or (!instance_exists(oPlayer) and !instance_exists(oTapController))) {
        for (var i = 0; i < array_length(self.channels); ++i) {
            var voice = self.channels[i].voice
            if (voice != -1 and audio_is_playing(voice)) audio_pause_sound(voice)
        }
        return;
    }
    var weather = global.forest_weather
    var family = funWeatherAudioFamily(weather)
    var rain_gain = 0
    if (family == "rain") rain_gain = 0.09 * clamp(weather.rain / 0.5, 0, 1)
    if (family == "storm") rain_gain = 0.12 * clamp(weather.rain, 0, 1)
    var dt = 1 / game_get_speed(gamespeed_fps)
    funWeatherAudioChannel(self.channels[0], rain_gain, dt)
    funWeatherAudioChannel(self.channels[1], family == "drips" ? 0.09 : 0, dt)
}
