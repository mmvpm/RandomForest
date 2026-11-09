/// Fails this isolated run without writing the user's save.
function funAtmosphereSmokeAssert(condition,label) {
    if (!condition) show_error("ATMOSPHERE_SCENE_FAIL " + label,true)
}

/// Compares native float gains at six decimals without the runner's near-zero epsilon.
function funAtmosphereSmokeGainMatches(voice,target) {
    return round(audio_sound_get_gain(voice)*1000000)==round(target*1000000)
}

/// Initializes deterministic settings while leaving the native mixer running.
function funAtmosphereSmokeCreate() {
    self.stage=0
    self.frames=0
    global.is_debug=false
    global.is_fullscreen=false
    global.music_enabled=true
    global.sfx_enabled=true
    global.ending_stage=0
    global.special_level_completed=false
    global.current_level=31
    global.is_training_completed=true
    for (var i=0;i<array_length(global.black_room_config.scenes);++i)
        variable_struct_set(global.black_room_seen,global.black_room_config.scenes[i].id,true)
    funApplyAudioSettings()
    // Automated checks remain inaudible; channel gain and transport remain native.
    audio_master_gain(0)
    funUpdateFullscreen()
}

/// Advances a checkpoint after the current room has finished its native events.
function funAtmosphereSmokeNext(stage) {
    self.stage=stage
    self.frames=0
}

/// Saves the actual menu output before a room changes its target gain.
function funAtmosphereSmokeRememberMenu() {
    self.menu_recordings=[]
    var streams=[oWeatherAudio.active,oWeatherAudio.outgoing]
    for (var i=0;i<array_length(streams);++i) {
        var stream=streams[i]
        if (!is_undefined(stream)) array_push(self.menu_recordings,
            {voice:stream.voice,gain:audio_sound_get_gain(stream.voice)})
    }
}

/// Checks a native channel against its curve with the mixer's GML comparison tolerance.
function funAtmosphereSmokeCurve(voice,expected,label) {
    var actual=audio_sound_get_gain(voice)
    funAtmosphereSmokeAssert(abs(round(actual*1000000)-round(expected*1000000))<=10,label)
}

/// Verifies every frame of the one-second entrance and both fading menu recordings.
function funAtmosphereSmokeWeatherEntry() {
    var owner=oWeatherAudio
    funAtmosphereSmokeAssert(owner.active.file=="rain.ogg" and owner.mix_duration==1,"weather starts immediately with a one-second mix")
    funAtmosphereSmokeAssert(is_undefined(owner.mix_pending),"weather cancels stale menu goal")
    var t=clamp(owner.mix_elapsed,0,1)
    var blend=t*t*(3-2*t)
    funAtmosphereSmokeCurve(owner.active.voice,0.09*blend,"native rain entrance curve")
    if (self.frames==1 or self.frames==30 or self.frames==60)
        show_debug_message("ATMOSPHERE_WEATHER_CURVE stage="+string(self.stage)+" frame="+string(self.frames)
            +" gain="+string_format(audio_sound_get_gain(owner.active.voice),0,9)+" streams="+string(owner.live_streams))
    for (var i=0;i<array_length(self.menu_recordings);++i) {
        var recording=self.menu_recordings[i]
        if (audio_is_playing(recording.voice))
            funAtmosphereSmokeCurve(recording.voice,recording.gain*(1-blend),"native menu exit curve")
    }
}

/// Verifies that menu entry cannot resume any paused gameplay recording.
function funAtmosphereSmokeMenuEntry() {
    for (var i=0;i<array_length(self.menu_recordings);++i) {
        var voice=self.menu_recordings[i].voice
        funAtmosphereSmokeAssert(!audio_is_playing(voice),"gameplay recording is never resumed in menu")
        var current=[oWeatherAudio.active,oWeatherAudio.outgoing,oWeatherAudio.menu_tail]
        for(var j=0;j<array_length(current);++j)
            if (!is_undefined(current[j])) funAtmosphereSmokeAssert(current[j].voice!=voice,"menu has released the old gameplay recording")
    }
    funAtmosphereSmokeAssert(oWeatherAudio.active.file!="rain.ogg","menu contains only clear forest")
    var t=oWeatherAudio.scene_gain
    funAtmosphereSmokeCurve(oWeatherAudio.active.voice,oWeatherAudio.active.base_gain*0.5*t*t*(3-2*t),"native one-second half-volume menu entrance")
    if (self.frames==1 or self.frames==30 or self.frames==60)
        show_debug_message("ATMOSPHERE_MENU_CURVE stage="+string(self.stage)+" frame="+string(self.frames)
            +" gain="+string_format(audio_sound_get_gain(oWeatherAudio.active.voice),0,9))
}

/// Exercises actual rooms, native stream positions, story silence and the shared toggle.
function funAtmosphereSmokeStep() {
    self.frames++
    if (self.frames>1200) show_error("ATMOSPHERE_SCENE_TIMEOUT " + string(self.stage),true)
    if (instance_exists(oWeatherAudio)) {
        var limit=is_undefined(oWeatherAudio.menu_tail) ? 2 : 3
        funAtmosphereSmokeAssert(oWeatherAudio.live_streams<=limit,"bounded atmosphere streams")
    }
    switch (self.stage) {
        case 0:
            if (room!=rMenu or self.frames<300) return;
            if (oMenu.startup_intro.active or oWeatherAudio.scene_gain<1 or oWeatherAudio.ui_gain>0.5) return;
            funAtmosphereSmokeAssert(oWeatherAudio.audio_group=="night","cold menu follows night theme")
            funAtmosphereSmokeAssert(!is_undefined(oWeatherAudio.active),"menu starts nature after intro")
            self.voice=oWeatherAudio.active.voice
            show_debug_message("ATMOSPHERE_MENU_GAIN native="+string_format(audio_sound_get_gain(self.voice),0,12)
                +" internal="+string_format(oWeatherAudio.active.gain,0,12)+" ui="+string_format(oWeatherAudio.ui_gain,0,12)
                +" scene="+string_format(oWeatherAudio.scene_gain,0,12)
                +" applied="+string_format(oWeatherAudio.active.applied_gain,0,12))
            funAtmosphereSmokeAssert(funAtmosphereSmokeGainMatches(self.voice,oWeatherAudio.active.gain*0.5),"menu nature is half volume")
            funAtmosphereSmokeAssert(funAtmosphereSmokeGainMatches(soundDialogueTyping,1.15),"typing native resource gain is 115 percent")
            self.position=audio_sound_get_track_position(self.voice)
            funMenuOpenLevelSelect()
            funAtmosphereSmokeNext(1)
            break
        case 1:
            if (room!=rLevelSelect or self.frames<60) return;
            funAtmosphereSmokeAssert(oWeatherAudio.active.voice==self.voice,"menu handoff preserves channel")
            funAtmosphereSmokeAssert(audio_sound_get_track_position(self.voice)>self.position,"menu transport advances")
            // Skip quickly through evening; only the settled day page should sound.
            oLevelSelect.page_index=2
            with (oLevelSelect) funMenuBackgroundSetTheme("evening")
            funAtmosphereSmokeNext(2)
            break
        case 2:
            if (self.frames<5) return;
            oLevelSelect.page_index=0
            with (oLevelSelect) funMenuBackgroundSetTheme("day")
            funAtmosphereSmokeNext(3)
            break
        case 3:
            if (self.frames<240) return;
            funAtmosphereSmokeAssert(oWeatherAudio.audio_group=="day","settled day page replaces night")
            self.voice=oWeatherAudio.active.voice
            funOpenLevel(0)
            funAtmosphereSmokeNext(4)
            break
        case 4:
            if (self.frames<90 or room==rLevelSelect) return;
            funAtmosphereSmokeAssert(oWeatherAudio.active.voice==self.voice,"day replay retains day menu voice")
            funAtmosphereSmokeAssert(funAtmosphereSmokeGainMatches(self.voice,oWeatherAudio.active.gain),"gameplay retains full volume")
            self.last_portal_gain=audio_sound_get_gain(self.voice)
            self.checked_results_tail=false
            with (oCoin) instance_destroy()
            oPlayer.x=oDoor.x
            oPlayer.y=oDoor.y+12
            funAtmosphereSmokeNext(5)
            break
        case 5:
            if (audio_is_playing(self.voice)) {
                var gain=audio_sound_get_gain(self.voice)
                funAtmosphereSmokeAssert(gain<=self.last_portal_gain,"portal exit keeps the original monotonic fade")
                self.last_portal_gain=gain
                if (instance_exists(oLevelPassing)) {
                    self.checked_results_tail=true
                    funAtmosphereSmokeAssert(!audio_is_paused(self.voice),"results continue the fading tail")
                }
            }
            if (!instance_exists(oLevelPassing) or self.frames<90) return;
            funAtmosphereSmokeAssert(self.checked_results_tail,"original portal tail reaches results")
            funAtmosphereSmokeAssert(oWeatherAudio.live_streams==0 and !audio_is_playing(self.voice),"results end silent")
            instance_activate_all()
            funRestartPlayingLevel()
            funAtmosphereSmokeNext(6)
            break
        case 6:
            if (self.frames<75 or instance_exists(oLevelPassing)) return;
            funAtmosphereSmokeAssert(oWeatherAudio.active.voice!=self.voice,"retry after results starts a fresh recording")
            funAtmosphereSmokeAssert(oWeatherAudio.scene_gain==1 and oWeatherAudio.ui_gain==1,"retry restores the original full-volume entrance")
            self.voice=oWeatherAudio.active.voice
            keyboard_key_press(global.key_pause)
            funAtmosphereSmokeNext(7)
            break
        case 7:
            keyboard_key_release(global.key_pause)
            if (self.frames<5) return;
            funAtmosphereSmokeAssert(audio_is_paused(self.voice),"pause suspends native stream")
            funRestartCurrentRun()
            funAtmosphereSmokeNext(8)
            break
        case 8:
            if (self.frames<60) return;
            funAtmosphereSmokeAssert(oWeatherAudio.active.voice==self.voice and audio_is_playing(self.voice),"pause retry resumes same stream")
            keyboard_key_press(global.key_pause)
            funAtmosphereSmokeNext(16)
            break
        case 16:
            keyboard_key_release(global.key_pause)
            if (self.frames<5) return;
            oPauseMenu.current_index=3
            keyboard_key_press(vk_enter)
            funAtmosphereSmokeNext(17)
            break
        case 17:
            keyboard_key_release(vk_enter)
            if (room!=rMenu or self.frames<180) return;
            funAtmosphereSmokeAssert(oWeatherAudio.audio_group=="night" and audio_is_playing(oWeatherAudio.active.voice),"pause exit restores the night menu forest")
            // Enter day directly from the night menu, without visiting a day page.
            funOpenLevel(0)
            funAtmosphereSmokeNext(18)
            break
        case 18:
            if (room==rMenu or self.frames<180) return;
            funAtmosphereSmokeAssert(oWeatherAudio.audio_group=="day","direct day replay overrides night menu")
            global.black_room_seen.ck_after_01=false
            with (oCoin) instance_destroy()
            oPlayer.x=oDoor.x
            oPlayer.y=oDoor.y+12
            funAtmosphereSmokeNext(9)
            break
        case 9:
            if (room!=rBlackRoom or self.frames<180) return;
            funAtmosphereSmokeAssert(oWeatherAudio.live_streams==0,"ordinary black room has no background")
            funFinishBlackRoomScene()
            funAtmosphereSmokeNext(10)
            break
        case 10:
            if (self.frames<180) return;
            funAtmosphereSmokeAssert(oWeatherAudio.live_streams==0,"story results also stay silent")
            instance_activate_all()
            funOpenStoryEnding()
            funAtmosphereSmokeNext(11)
            break
        case 11:
            if (room!=rBlackRoom or self.frames<120) return;
            funAtmosphereSmokeAssert(oWeatherAudio.live_streams==0,"first finale has no background")
            global.ending_stage=1
            room_goto(rMenu)
            funAtmosphereSmokeNext(12)
            break
        case 12:
            if (room!=rMenu or self.frames<90) return;
            funAtmosphereSmokeAssert(oWeatherAudio.live_streams==0,"broken menu has no background")
            funOpenStoryEnding(true)
            funAtmosphereSmokeNext(13)
            break
        case 13:
            if (room!=rBlackRoom or self.frames<120) return;
            funAtmosphereSmokeAssert(oWeatherAudio.live_streams==0,"true ending has no background")
            global.ending_stage=2
            room_goto(rMenu)
            funAtmosphereSmokeNext(14)
            break
        case 14:
            if (room!=rMenu or self.frames<180) return;
            funAtmosphereSmokeAssert(oWeatherAudio.audio_group=="night" and oWeatherAudio.live_streams>0,"ordinary menu returns after ending")
            global.music_enabled=false
            funApplyAudioSettings()
            funAtmosphereSmokeNext(15)
            break
        case 15:
            if (self.frames<5) return;
            funAtmosphereSmokeAssert(oWeatherAudio.live_streams==0,"background toggle mutes all ambience")
            global.music_enabled=true
            funApplyAudioSettings()
            global.forest_weather=funWeatherCreate(123,"night")
            funWeatherSetPhase(global.forest_weather,"rain",999999)
            global.forest_weather.rain=0.5
            funAtmosphereSmokeNext(19)
            break
        case 19:
            if(self.frames<120)return;
            funAtmosphereSmokeRememberMenu()
            funOpenLevel(35)
            funAtmosphereSmokeNext(20)
            break
        case 20:
            funAtmosphereSmokeWeatherEntry()
            if(self.frames<65)return;
            funAtmosphereSmokeAssert(oWeatherAudio.live_streams==1,"single rain recording after one second")
            with(oCoin)instance_destroy()
            oPlayer.x=oDoor.x
            oPlayer.y=oDoor.y+12
            funAtmosphereSmokeNext(21)
            break
        case 21:
            if(!instance_exists(oLevelPassing) or self.frames<100)return;
            funAtmosphereSmokeAssert(oWeatherAudio.live_streams==0,"rain results remain silent")
            with(oLevelPassing)__funContinueLevel()
            funAtmosphereSmokeNext(22)
            break
        case 22:
            var t=oWeatherAudio.scene_gain
            funAtmosphereSmokeCurve(oWeatherAudio.active.voice,0.09*t*t*(3-2*t),"results keep original one-second entrance")
            if(self.frames<75)return;
            keyboard_key_press(global.key_pause)
            funAtmosphereSmokeNext(23)
            break
        case 23:
            keyboard_key_release(global.key_pause)
            if(self.frames<5)return;
            funAtmosphereSmokeRememberMenu()
            oPauseMenu.current_index=3
            keyboard_key_press(vk_enter)
            funAtmosphereSmokeNext(24)
            break
        case 24:
            keyboard_key_release(vk_enter)
            funAtmosphereSmokeMenuEntry()
            if(self.frames<90)return;
            with(oMenu)funMenuBackgroundSetTheme("evening")
            funAtmosphereSmokeNext(25)
            break
        case 25:
            if(self.frames<40)return;
            funAtmosphereSmokeAssert(!is_undefined(oWeatherAudio.outgoing),"clear page transition is in flight")
            self.voice=oWeatherAudio.active.voice
            self.mix_time=oWeatherAudio.mix_elapsed
            funWeatherSetPhase(global.forest_weather,"dry",999999)
            global.forest_weather.rain=0
            funOpenLevel(25)
            funAtmosphereSmokeNext(26)
            break
        case 26:
            funAtmosphereSmokeAssert(oWeatherAudio.active.voice==self.voice,"clear entry preserves menu recording")
            funAtmosphereSmokeAssert(oWeatherAudio.mix_duration==2,"clear entry keeps two-second page transition")
            if(self.frames==1)funAtmosphereSmokeAssert(
                abs(round(oWeatherAudio.mix_elapsed*600)-round(self.mix_time*600)-10)<=1,"clear entry preserves elapsed mix time")
            if(self.frames<130)return;
            keyboard_key_press(global.key_pause)
            funAtmosphereSmokeNext(27)
            break
        case 27:
            keyboard_key_release(global.key_pause)
            if(self.frames<5)return;
            oPauseMenu.current_index=3
            keyboard_key_press(vk_enter)
            funAtmosphereSmokeNext(28)
            break
        case 28:
            keyboard_key_release(vk_enter)
            if(self.frames<90)return;
            with(oMenu)funMenuBackgroundSetTheme("evening")
            funAtmosphereSmokeNext(29)
            break
        case 29:
            if(self.frames<40)return;
            funAtmosphereSmokeRememberMenu()
            funAtmosphereSmokeAssert(array_length(self.menu_recordings)==2,"both menu recordings are audible before rain")
            funWeatherSetPhase(global.forest_weather,"rain",999999)
            global.forest_weather.rain=0.5
            funOpenLevel(25)
            funAtmosphereSmokeNext(30)
            break
        case 30:
            funAtmosphereSmokeWeatherEntry()
            if(self.frames<55)funAtmosphereSmokeAssert(oWeatherAudio.live_streams==3,"both menu tails fade alongside rain")
            if(self.frames<65)return;
            funAtmosphereSmokeAssert(oWeatherAudio.live_streams==1,"extra menu tail released after one second")
            keyboard_key_press(global.key_pause)
            funAtmosphereSmokeNext(31)
            break
        case 31:
            keyboard_key_release(global.key_pause)
            if(self.frames<5)return;
            funAtmosphereSmokeRememberMenu()
            global.current_level=0
            oPauseMenu.current_index=3
            keyboard_key_press(vk_enter)
            funAtmosphereSmokeNext(32)
            break
        case 32:
            keyboard_key_release(vk_enter)
            funAtmosphereSmokeMenuEntry()
            if(self.frames<90)return;
            funAtmosphereSmokeAssert(oWeatherAudio.audio_group=="day","different-theme menu starts clear immediately")
            show_debug_message("ATMOSPHERE_SCENE_PASS")
            game_end()
            break
    }
}
