/// Loads only approved recordings into the persistent atmosphere owner.
function funWeatherAudioCreate() {
    self.audio_directory="weather_audio/"
    self.catalog=json_parse(funReadGeneratedLevelFile(self.audio_directory+"catalog.json"))
    funAtmosphereMixCreate()
    funAtmosphereDirectorCreate()
    self.scene_gain=0
    self.portal_fading=false
    self.level_entry_pending=true
    self.continue_after_death=false
}

/// Frees atmosphere alone, preserving music and ordinary gameplay sound behavior.
function funWeatherAudioStop() {
    funAtmosphereMixStop()
    self.scene_gain=0
    // A completed portal remains silent until the next gameplay room starts.
}

/// Starts each gameplay room from silence while retaining an existing recording's position.
function funWeatherAudioEnterLevel() {
    // Death restarts the same continuous attempt without touching voices or envelopes.
    if (self.continue_after_death) {
        self.continue_after_death=false
        return;
    }
    self.portal_fading=false
    self.scene_gain=0
    self.level_entry_pending=true
    // The preceding room is already silent; discard an unfinished weather overlap.
    funAtmosphereMixRelease(self.outgoing)
    self.outgoing=undefined
    self.mix_pending=undefined
    self.mix_requested=""
    funWeatherAudioSceneFade(true,0)
}

/// Keeps the portal's outgoing nature audible while gameplay gives way to results.
function funWeatherAudioBeginPortalFade() {
    self.portal_fading=true
}

/// Continues approved ambience through restarts, level changes and sword aiming.
function funWeatherAudioStep() {
    if (!global.sfx_enabled) {funWeatherAudioStop();return;}
    var dt=1/game_get_speed(gamespeed_fps)
    if (room==rMenu or room==rLevelSelect) {funWeatherAudioStop();return;}
    if (instance_exists(oPauseMenu) and oPauseMenu.paused) {
        funAtmosphereMixPause();return;
    }
    if (self.portal_fading) {
        funWeatherAudioSceneFade(false,dt)
        if (self.scene_gain==0) funWeatherAudioStop()
        return;
    }
    if (room==rBlackRoom or instance_exists(oLevelPassing)) {funWeatherAudioStop();return;}
    if (!instance_exists(oAmbientSystem) or (!instance_exists(oPlayer) and !instance_exists(oTapController))) {
        funAtmosphereMixPause();return;
    }
    var weather=global.forest_weather
    var group=weather.phase=="dry" or weather.phase=="seeds" ? funCurrentLevelTheme() : weather.phase
    funAtmosphereDirectorStep(group,dt,weather.remaining)
    var choice=variable_struct_get(self.choices,group)
    if (self.level_entry_pending and choice==0 and self.auto_mode) {
        // A new level starts with a recording rather than inheriting a scheduled quiet gap.
        self.was_silence=true
        funAtmosphereDirectorPick(group,true)
        choice=variable_struct_get(self.choices,group)
    }
    var item=choice==0 ? undefined : variable_struct_get(self.catalog,group)[choice-1]
    // Retain the complete outgoing tail; imminent weather already blocks new Auto rotations.
    funAtmosphereMixSelect(item,12)
    if (self.level_entry_pending) {
        // The one-second level envelope alone handles entry, never a second 12s fade.
        self.mix_elapsed=self.mix_duration
        self.level_entry_pending=false
    }
    if (!is_undefined(self.active) and self.active.file=="rain.ogg" and (group=="rain" or group=="storm"))
        self.active.scale=clamp(weather.rain/(group=="storm" ? 1 : .5),0,1)
    self.scene_gain=min(1,self.scene_gain+dt)
    funAtmosphereMixStep(dt,funWeatherAudioSceneEnvelope())
}

/// Returns the shared one-second entrance/exit curve.
function funWeatherAudioSceneEnvelope() {
    return self.scene_gain*self.scene_gain*(3-2*self.scene_gain)
}

/// Fades level entry or portal exit without resuming any suspended voice.
function funWeatherAudioSceneFade(audible,dt) {
    self.scene_gain=clamp(self.scene_gain+(audible ? dt : -dt),0,1)
    var envelope=funWeatherAudioSceneEnvelope()
    var streams=[self.active,self.outgoing]
    for (var i=0;i<array_length(streams);++i) {
        var stream=streams[i]
        if (is_undefined(stream)) continue
        funAtmosphereMixGain(stream,stream.gain,envelope)
    }
}
