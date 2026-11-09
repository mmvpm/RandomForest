/// Loads only approved recordings into the persistent atmosphere owner.
function funWeatherAudioCreate() {
    self.audio_directory="weather_audio/"
    self.catalog=json_parse(funReadGeneratedLevelFile(self.audio_directory+"catalog.json"))
    funAtmosphereMixCreate()
    funAtmosphereDirectorCreate()
    self.scene_gain=0
    self.ui_gain=1
    self.portal_fading=false
    self.level_entry_pending=true
    self.continue_after_death=false
    self.scene_theme=""
    self.scene_kind=""
    self.menu_pending_theme=""
    self.menu_pending_time=0
}

/// Releases owned background streams without touching action sounds.
function funWeatherAudioStop() {
    funAtmosphereMixStop()
    self.scene_gain=0
}

/// Restores the original level entrance after results; live retries retain their voices.
function funWeatherAudioEnterLevel() {
    if (self.continue_after_death) {
        self.continue_after_death=false
        return;
    }
    if (self.portal_fading or self.scene_gain==0) {
        self.scene_gain=0
        self.ui_gain=1
        self.level_entry_pending=true
        // Fast Next must cancel the old overlap and use only the one-second entrance.
        funAtmosphereMixRelease(self.outgoing)
        self.outgoing=undefined
        funAtmosphereMixRelease(self.menu_tail)
        self.menu_tail=undefined
        self.mix_pending=undefined
        self.mix_requested=""
        funWeatherAudioSceneFade(true,0)
    }
    self.continue_after_death=false
    self.portal_fading=false
    self.level_entry_pending=self.scene_gain==0
}

/// Starts the original one-second exit, which keeps fading over the results screen.
function funWeatherAudioBeginPortalFade() {
    self.portal_fading=true
}

/// Starts a fresh clear menu entrance without resuming suspended gameplay weather.
function funWeatherAudioEnterMenu() {
    funWeatherAudioStop()
    self.portal_fading=false
    self.ui_gain=0.5
    self.scene_theme=""
    self.menu_pending_theme=""
    self.menu_pending_time=0
    self.level_entry_pending=true
}

/// Continues approved ambience through restarts, level changes and sword aiming.
function funWeatherAudioStep() {
    if (!global.music_enabled) {funWeatherAudioStop();return;}
    var dt=1/game_get_speed(gamespeed_fps)
    var kind=funAtmosphereSceneKind()
    if (kind=="suspended") {funAtmosphereMixPause();return;}
    if (instance_exists(oPauseMenu) and oPauseMenu.paused) {
        funAtmosphereMixPause();return;
    }
    var from_menu=self.scene_kind=="menu" and kind=="game"
    if (kind=="menu" and self.scene_kind!="menu") funWeatherAudioEnterMenu()
    self.scene_kind=kind
    if (self.portal_fading) {
        funWeatherAudioSceneFade(false,dt)
        if (self.scene_gain==0) funWeatherAudioStop()
        return;
    }
    if (kind=="silent" or kind=="results") {funWeatherAudioStop();return;}
    // UI is half as loud; keep the same voice and ease back to gameplay over 0.5 s.
    var ui_target=kind=="menu" ? 0.5 : 1
    self.ui_gain+=clamp(ui_target-self.ui_gain,-dt,dt)
    var theme=funAtmosphereSceneTheme(kind)
    if (!funAtmosphereMenuReady(kind,theme,dt)) {
        funAtmosphereMixStep(dt,funWeatherAudioSceneEnvelope());return;
    }
    var group=funAtmosphereSceneGroup(kind,theme)
    var transition=from_menu or kind!="game" or theme!=self.scene_theme ? 2 : 12
    var weather_entry=from_menu and group!=theme
    var weather_remaining=kind=="game" ? global.forest_weather.remaining : 999999
    var first_stream=is_undefined(self.active) and is_undefined(self.outgoing) and self.scene_gain==0
    self.scene_theme=theme
    funAtmosphereDirectorStep(group,dt,weather_remaining)
    var choice=variable_struct_get(self.choices,group)
    if ((self.level_entry_pending or first_stream) and choice==0 and self.auto_mode) {
        // Silence after a scene must not delay its first audible atmosphere.
        self.was_silence=true
        funAtmosphereDirectorPick(group,true)
        choice=variable_struct_get(self.choices,group)
    }
    var item=choice==0 ? undefined : variable_struct_get(self.catalog,group)[choice-1]
    if (weather_entry) {
        funAtmosphereMixEnterWeather(item)
        self.scene_gain=1
        self.ui_gain=1
    } else funAtmosphereMixSelect(item,transition)
    if (!weather_entry and (self.level_entry_pending or first_stream)) {
        // The one-second level envelope alone handles entry, never a second 12s fade.
        self.mix_elapsed=self.mix_duration
    }
    self.level_entry_pending=false
    if (!is_undefined(self.active) and self.active.file=="rain.ogg" and (group=="rain" or group=="storm")) {
        var rain_scale=global.forest_weather.rain/(group=="storm" ? 1 : .5)
        self.active.scale=clamp(rain_scale,0,1)
    }
    self.scene_gain=min(1,self.scene_gain+dt)
    funAtmosphereMixStep(dt,funWeatherAudioSceneEnvelope())
}

/// Combines scene fades with the independent, quieter interface level.
function funWeatherAudioSceneEnvelope() {
    return self.scene_gain*self.scene_gain*(3-2*self.scene_gain)*self.ui_gain
}

/// Fades level entry or portal exit without resuming any suspended voice.
function funWeatherAudioSceneFade(audible,dt) {
    self.scene_gain=clamp(self.scene_gain+(audible ? dt : -dt),0,1)
    var envelope=funWeatherAudioSceneEnvelope()
    var streams=[self.active,self.outgoing,self.menu_tail]
    for (var i=0;i<array_length(streams);++i) {
        var stream=streams[i]
        if (is_undefined(stream)) continue
        funAtmosphereMixGain(stream,stream.gain,envelope)
    }
}
