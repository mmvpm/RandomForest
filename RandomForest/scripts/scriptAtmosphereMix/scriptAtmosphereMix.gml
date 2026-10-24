/// Owns at most two atmosphere streams and one latest pending transition.
function funAtmosphereMixCreate() {
    self.active=undefined
    self.outgoing=undefined
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
        duration:audio_sound_length(asset),paused:false,base_gain:item.gain,start_gain:0,gain:0,scale:1}
    self.live_streams++
    self.peak_streams=max(self.peak_streams,self.live_streams)
    self.audio_error=""
}

/// Coalesces requests so an audible outgoing stream is never cut to open a third voice.
function funAtmosphereMixSelect(item,seconds=12) {
    var key=is_undefined(item) ? "silence" : item.id+":"+item.file+":"+string(item.gain)
    if (key==self.mix_requested) return;
    self.mix_requested=key
    if (!is_undefined(self.outgoing)) {
        self.mix_pending={item:item,seconds:seconds}
        return;
    }
    funAtmosphereMixBegin(item,seconds)
}

/// Applies only meaningful changes, leaving music and gameplay voices independent.
function funAtmosphereMixGain(stream,gain) {
    if (stream.gain==gain) return;
    stream.gain=gain
    audio_sound_gain(stream.voice,gain,0)
}

/// Uses zero-slope envelope edges instead of an abrupt linear gain handoff.
function funAtmosphereMixStep(dt) {
    if (!is_undefined(self.active) and self.active.paused) {
        audio_resume_sound(self.active.voice);self.active.paused=false
    }
    if (!is_undefined(self.outgoing) and self.outgoing.paused) {
        audio_resume_sound(self.outgoing.voice);self.outgoing.paused=false
    }
    if (!is_undefined(self.active) and !audio_is_playing(self.active.voice)) {
        funAtmosphereMixStop();return;
    }
    self.mix_elapsed=min(self.mix_duration,self.mix_elapsed+dt)
    var t=clamp(self.mix_elapsed/self.mix_duration,0,1)
    var blend=t*t*(3-2*t)
    var master=self.muted ? 0 : self.volume
    if (!is_undefined(self.active)) {
        funAtmosphereMixGain(self.active,self.muted ? 0 : lerp(self.active.start_gain,self.active.base_gain*master*self.active.scale,blend))
    }
    if (!is_undefined(self.outgoing)) {
        funAtmosphereMixGain(self.outgoing,self.muted ? 0 : self.outgoing.start_gain*(1-blend))
    }
    self.out_time=max(0,self.mix_duration-self.mix_elapsed)
    if (t<1) return;
    funAtmosphereMixRelease(self.outgoing)
    self.outgoing=undefined
    if (!is_undefined(self.mix_pending)) {
        var request=self.mix_pending
        self.mix_pending=undefined
        funAtmosphereMixBegin(request.item,request.seconds)
    }
}

/// Suspends voices without resetting envelope time or playback position.
function funAtmosphereMixPause() {
    if (!is_undefined(self.active) and audio_is_playing(self.active.voice)) {audio_pause_sound(self.active.voice);self.active.paused=true;}
    if (!is_undefined(self.outgoing) and audio_is_playing(self.outgoing.voice)) {audio_pause_sound(self.outgoing.voice);self.outgoing.paused=true;}
}

/// Releases atmosphere resources once on mute, cleanup or shutdown.
function funAtmosphereMixStop() {
    funAtmosphereMixRelease(self.active);self.active=undefined
    funAtmosphereMixRelease(self.outgoing);self.outgoing=undefined
    self.mix_pending=undefined
    self.mix_requested=""
    self.mix_elapsed=self.mix_duration
}

/// Names the actual sounding track and any outgoing overlap for debug.
function funAtmosphereMixLabel() {
    var label=is_undefined(self.active) ? "Тишина" : self.active.title
    if (!is_undefined(self.outgoing)) label=self.outgoing.track+" > "+label
    return label
}
