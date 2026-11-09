/// Owns two normal streams and one extra menu tail during a weather entrance.
function funAtmosphereMixCreate() {
    self.active=undefined
    self.outgoing=undefined
    self.menu_tail=undefined
    self.mix_pending=undefined
    self.mix_requested=""
    self.mix_elapsed=12
    self.mix_duration=12
    self.out_time=0
    self.volume=1
    self.muted=false
    self.audio_error=""
    self.live_streams=0
    self.peak_streams=0
}

/// Stops one owned voice before releasing its streaming asset.
function funAtmosphereMixRelease(stream) {
    if (is_undefined(stream)) return;
    audio_stop_sound(stream.voice)
    audio_destroy_stream(stream.asset)
    self.live_streams--
}

/// Starts from the actual current gain; shared recordings retain their playback position.
function funAtmosphereMixBegin(item,seconds) {
    var file=is_undefined(item) ? "" : item.file
    self.mix_elapsed=0
    self.mix_duration=seconds
    if (!is_undefined(self.active) and self.active.file==file) {
        self.active.start_gain=self.active.gain
        self.active.base_gain=item.gain
        self.active.track=item.id
        self.active.title=item.id+" · "+item.label
        return;
    }
    self.outgoing=self.active
    if (!is_undefined(self.outgoing)) self.outgoing.start_gain=self.outgoing.gain
    self.active=undefined
    if (is_undefined(item)) return;
    var asset=audio_create_stream(self.audio_directory+file)
    if (asset<0) {self.audio_error="Не открыт: "+file;return;}
    var voice=audio_play_sound(asset,-5,true,0)
    if (voice<0) {audio_destroy_stream(asset);self.audio_error="Нет аудиоканала";return;}
    self.active={asset:asset,voice:voice,file:file,track:item.id,title:item.id+" · "+item.label,
        duration:audio_sound_length(asset),paused:false,base_gain:item.gain,start_gain:0,gain:0,applied_gain:0,scale:1}
    self.live_streams++
    self.peak_streams=max(self.peak_streams,self.live_streams)
    self.audio_error=""
}

/// Coalesces requests so an audible outgoing stream is never cut to open a third voice.
function funAtmosphereMixSelect(item,seconds=12) {
    var key=is_undefined(item) ? "silence" : item.id+":"+item.file+":"+string(item.gain)
    if (key==self.mix_requested) return;
    self.mix_requested=key
    if (!is_undefined(self.outgoing) or !is_undefined(self.menu_tail)) {
        self.mix_pending={item:item,seconds:seconds}
        // A menu/daylight change must not wait for a long weather fade to finish.
        if (seconds<self.mix_duration-self.mix_elapsed) {
            if (!is_undefined(self.active)) self.active.start_gain=self.active.gain
            if (!is_undefined(self.outgoing)) self.outgoing.start_gain=self.outgoing.gain
            if (!is_undefined(self.menu_tail)) self.menu_tail.start_gain=self.menu_tail.gain
            self.mix_elapsed=0
            self.mix_duration=seconds
        }
        return;
    }
    funAtmosphereMixBegin(item,seconds)
}

/// Replaces the menu's pending goal while fading both audible menu recordings for one second.
function funAtmosphereMixEnterWeather(item) {
    var streams=[self.active,self.outgoing]
    for (var i=0;i<array_length(streams);++i) {
        var stream=streams[i]
        if (is_undefined(stream)) continue
        // Preserve the actual menu output when the scene switches to full gameplay gain.
        stream.gain=stream.applied_gain
        stream.start_gain=stream.gain
    }
    var menu_tail=self.outgoing
    self.outgoing=undefined
    self.mix_pending=undefined
    self.mix_requested=""
    funAtmosphereMixSelect(item,1)
    self.menu_tail=menu_tail
}

/// Applies only meaningful changes, leaving music and gameplay voices independent.
function funAtmosphereMixGain(stream,gain,output_gain=1) {
    stream.gain=gain
    var applied_gain=gain*output_gain
    if (stream.applied_gain==applied_gain) return;
    stream.applied_gain=applied_gain
    audio_sound_gain(stream.voice,applied_gain,0)
}

/// Uses zero-slope envelope edges instead of an abrupt linear gain handoff.
function funAtmosphereMixStep(dt,output_gain=1) {
    var streams=[self.active,self.outgoing,self.menu_tail]
    for (var i=0;i<array_length(streams);++i) {
        var stream=streams[i]
        if (!is_undefined(stream) and stream.paused) {
            audio_resume_sound(stream.voice);stream.paused=false
        }
    }
    if (!is_undefined(self.active) and !audio_is_playing(self.active.voice)) {
        funAtmosphereMixStop();return;
    }
    self.mix_elapsed=min(self.mix_duration,self.mix_elapsed+dt)
    var t=clamp(self.mix_elapsed/self.mix_duration,0,1)
    var blend=t*t*(3-2*t)
    var master=self.muted ? 0 : self.volume
    if (!is_undefined(self.active)) {
        funAtmosphereMixGain(self.active,self.muted ? 0 : lerp(self.active.start_gain,self.active.base_gain*master*self.active.scale,blend),output_gain)
    }
    if (!is_undefined(self.outgoing)) {
        funAtmosphereMixGain(self.outgoing,self.muted ? 0 : self.outgoing.start_gain*(1-blend),output_gain)
    }
    if (!is_undefined(self.menu_tail)) {
        funAtmosphereMixGain(self.menu_tail,self.muted ? 0 : self.menu_tail.start_gain*(1-blend),output_gain)
    }
    self.out_time=max(0,self.mix_duration-self.mix_elapsed)
    if (t<1) return;
    funAtmosphereMixRelease(self.outgoing)
    self.outgoing=undefined
    funAtmosphereMixRelease(self.menu_tail)
    self.menu_tail=undefined
    if (!is_undefined(self.mix_pending)) {
        var request=self.mix_pending
        self.mix_pending=undefined
        funAtmosphereMixBegin(request.item,request.seconds)
    }
}

/// Suspends voices without resetting envelope time or playback position.
function funAtmosphereMixPause() {
    var streams=[self.active,self.outgoing,self.menu_tail]
    for (var i=0;i<array_length(streams);++i) {
        var stream=streams[i]
        if (!is_undefined(stream) and audio_is_playing(stream.voice)) {
            audio_pause_sound(stream.voice);stream.paused=true
        }
    }
}

/// Releases atmosphere resources once on mute, cleanup or shutdown.
function funAtmosphereMixStop() {
    funAtmosphereMixRelease(self.active);self.active=undefined
    funAtmosphereMixRelease(self.outgoing);self.outgoing=undefined
    funAtmosphereMixRelease(self.menu_tail);self.menu_tail=undefined
    self.mix_pending=undefined
    self.mix_requested=""
    self.mix_elapsed=self.mix_duration
}

/// Names the actual sounding track and any outgoing overlap for debug.
function funAtmosphereMixLabel() {
    var label=is_undefined(self.active) ? "Тишина" : self.active.title
    if (!is_undefined(self.outgoing)) label=self.outgoing.track+" > "+label
    if (!is_undefined(self.menu_tail)) label=self.menu_tail.track+" + "+label
    return label
}
