/// Fails the isolated portal check without touching the user's save.
function funPortalAudioAssert(condition,label) {
    if (!condition) show_error("PORTAL_AUDIO_FAIL " + label,true)
}

/// Starts a small silent test window; native audio channels still run normally.
function funThemeSmokeCreate() {
    self.stage=0
    self.frames=0
    self.checked_results_tail=false
    self.checked_story_tail=false
    self.checked_half_entry=false
    self.checked_full_entry=false
    self.last_gain=1
    self.pending_shot=""
    global.is_debug=false
    global.ending_stage=0
    global.special_level_completed=false
    global.is_fullscreen=false
    global.music_enabled=false
    global.sfx_enabled=true
    global.is_training_completed=true
    for (var i=0;i<array_length(global.black_room_config.scenes);++i)
        variable_struct_set(global.black_room_seen,global.black_room_config.scenes[i].id,true)
    funApplyAudioSettings()
    audio_master_gain(0)
    funUpdateFullscreen()
}

/// Enters the actual berry-gated portal so its production Step starts the fade.
function funPortalAudioTouchDoor() {
    with (oCoin) instance_destroy()
    oTimeCounter.time_counter=42
    oPlayer.x=oDoor.x
    oPlayer.y=oDoor.y+12
    self.portal_voice=oWeatherAudio.active.voice
    self.last_gain=audio_sound_get_gain(self.portal_voice)
    self.frames=0
}

/// Checks actual voice gains across portal/results, pause/menu and a story portal.
function funThemeSmokeStep() {
    self.frames++
    if (self.frames>1000) show_error("PORTAL_AUDIO_TIMEOUT " + string(self.stage),true)
    switch (self.stage) {
        case 0:
            if (room!=rMenu or self.frames<25) return;
            funOpenLevel(0)
            self.stage=1
            self.frames=0
            break
        case 1:
            if (self.frames<3 or is_undefined(oWeatherAudio.active)) return;
            funPortalAudioAssert(oWeatherAudio.scene_gain>0 and oWeatherAudio.scene_gain<1,"level entry fades from zero")
            self.last_gain=0
            self.stage=2
            self.frames=0
            break
        case 2:
            var gain=audio_sound_get_gain(oWeatherAudio.active.voice)
            funPortalAudioAssert(gain>=self.last_gain,"native entrance gain is monotonic")
            self.last_gain=gain
            var target=oWeatherAudio.active.base_gain*oWeatherAudio.active.scale*oWeatherAudio.volume
            if (abs(oWeatherAudio.scene_gain-0.5)<0.0001) {
                show_debug_message("PORTAL_AUDIO_HALF native="+string_format(gain,0,8)+" target="+string_format(target,0,8)
                    +" applied="+string_format(oWeatherAudio.active.applied_gain,0,8))
                funPortalAudioAssert(oWeatherAudio.active.applied_gain==target*0.5,"half volume scheduled after half a second")
                funPortalAudioAssert(gain==target*0.5,"native gain follows the half-second envelope")
                self.checked_half_entry=true
            }
            if (oWeatherAudio.scene_gain>=1 and !self.checked_full_entry) {
                show_debug_message("PORTAL_AUDIO_FULL native="+string_format(gain,0,8)+" target="+string_format(target,0,8)
                    +" applied="+string_format(oWeatherAudio.active.applied_gain,0,8))
                funPortalAudioAssert(oWeatherAudio.active.applied_gain==target,"full gain scheduled at one second, no 12s layer")
                funPortalAudioAssert(gain==target,"full native gain at one second")
                self.checked_full_entry=true
            }
            if (self.frames<75) return;
            funPortalAudioAssert(gain==target,"native voice keeps the full target")
            funPortalAudioAssert(self.checked_half_entry and self.checked_full_entry,"native one-second curve checked")
            funPortalAudioAssert(oWeatherAudio.scene_gain==1,"entry reaches full envelope")
            funPortalAudioTouchDoor()
            self.stage=3
            break
        case 3:
            if (audio_is_playing(self.portal_voice)) {
                var gain=audio_sound_get_gain(self.portal_voice)
                funPortalAudioAssert(gain<=self.last_gain,"native portal gain is monotonic")
                self.last_gain=gain
                if (instance_exists(oLevelPassing)) {
                    self.checked_results_tail=true
                    funPortalAudioAssert(!audio_is_paused(self.portal_voice),"results keep the tail playing while fading")
                }
            }
            if (self.frames<80) return;
            funPortalAudioAssert(self.checked_results_tail,"real portal tail crosses into results")
            funPortalAudioAssert(oWeatherAudio.live_streams==0 and !audio_is_playing(self.portal_voice),"results end silent")
            show_debug_message("PORTAL_AUDIO_RESULTS_PASS")
            instance_activate_all()
            funOpenLevel(0)
            self.stage=4
            self.frames=0
            break
        case 4:
            if (self.frames<3 or is_undefined(oWeatherAudio.active)) return;
            funPortalAudioAssert(oWeatherAudio.scene_gain<1,"next level has its own fade-in")
            self.stage=5
            self.frames=0
            break
        case 5:
            if (self.frames<75) return;
            self.pause_voice=oWeatherAudio.active.voice
            keyboard_key_press(global.key_pause)
            self.stage=6
            self.frames=0
            break
        case 6:
            keyboard_key_release(global.key_pause)
            if (self.frames<4) return;
            funPortalAudioAssert(oPauseMenu.paused and audio_is_paused(self.pause_voice),"pause is immediately silent")
            funPortalAudioAssert(oWeatherAudio.scene_gain==1,"pause does not fade")
            oPauseMenu.current_index=3
            keyboard_key_press(vk_enter)
            self.stage=7
            self.frames=0
            break
        case 7:
            keyboard_key_release(vk_enter)
            if (room!=rMenu) return;
            funPortalAudioAssert(!audio_is_playing(self.pause_voice),"pause-to-menu never revives the voice")
            if (self.frames<6) return;
            funPortalAudioAssert(oWeatherAudio.live_streams==0,"main menu releases suspended streams")
            show_debug_message("PORTAL_AUDIO_PAUSE_MENU_PASS")
            global.black_room_seen.ck_after_01=false
            funOpenLevel(0)
            self.stage=8
            self.frames=0
            break
        case 8:
            if (self.frames<3 or is_undefined(oWeatherAudio.active)) return;
            self.stage=9
            self.frames=0
            break
        case 9:
            if (self.frames<75) return;
            funPortalAudioTouchDoor()
            self.stage=10
            break
        case 10:
            if (room==rBlackRoom and audio_is_playing(self.portal_voice)) {
                self.checked_story_tail=true
                funPortalAudioAssert(!audio_is_paused(self.portal_voice),"story portal tail keeps fading")
            }
            if (self.frames<90) return;
            funPortalAudioAssert(room==rBlackRoom and self.checked_story_tail,"real portal opens story room during fade")
            funPortalAudioAssert(oWeatherAudio.live_streams==0,"story room ends silent")
            if (!instance_exists(oDialogue)) return;
            funPortalAudioAssert(oDialogue.line_height==18 and oDialogue.rows_per_page==4,"fixed original dialogue layout")
            funPortalAudioAssert(!variable_global_exists("dialogue_font_size"),"temporary font controls removed")
            draw_set_font(global.dialogue_font_12)
            funPortalAudioAssert(string_height("М")==16,"approved size 12")
            show_debug_message("PORTAL_AUDIO_PASS")
            game_end()
            break
    }
}

/// Keeps the shared isolated build interface without changing production drawing.
function funThemeSmokeDraw() {
}
