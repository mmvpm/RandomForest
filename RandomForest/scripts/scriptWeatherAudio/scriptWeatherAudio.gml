/// Loads only approved recordings into the persistent atmosphere owner.
function funWeatherAudioCreate() {
    self.audio_directory="weather_audio/"
    self.catalog=json_parse(funReadGeneratedLevelFile(self.audio_directory+"catalog.json"))
    funAtmosphereMixCreate()
    funAtmosphereDirectorCreate()
}

/// Frees atmosphere alone, preserving music and ordinary gameplay sound behavior.
function funWeatherAudioStop() {
    funAtmosphereMixStop()
}

/// Continues approved ambience through restarts, level changes and sword aiming.
function funWeatherAudioStep() {
    if (room==rMenu) {funWeatherAudioStop();return;}
    if (!global.sfx_enabled) {funWeatherAudioStop();return;}
    if (!instance_exists(oAmbientSystem) or (!instance_exists(oPlayer) and !instance_exists(oTapController))) {
        funAtmosphereMixPause();return;
    }
    var weather=global.forest_weather
    var group=weather.phase=="dry" or weather.phase=="seeds" ? funCurrentLevelTheme() : weather.phase
    var dt=1/game_get_speed(gamespeed_fps)
    funAtmosphereDirectorStep(group,dt,weather.remaining)
    var choice=variable_struct_get(self.choices,group)
    var item=choice==0 ? undefined : variable_struct_get(self.catalog,group)[choice-1]
    // Retain the complete outgoing tail; imminent weather already blocks new Auto rotations.
    funAtmosphereMixSelect(item,12)
    if (!is_undefined(self.active) and self.active.file=="rain.ogg" and (group=="rain" or group=="storm"))
        self.active.scale=clamp(weather.rain/(group=="storm" ? 1 : .5),0,1)
    funAtmosphereMixStep(dt)
}
