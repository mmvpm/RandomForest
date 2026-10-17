/// Records real playback only in the isolated fixture and checks cue timing and duplication.
function funForestSmokePlaySound(sound, priority, loop) {
    var kind=variable_instance_exists(self,"forest_kind") ? self.forest_kind : "projectile"
    var serial=variable_instance_exists(self,"attack_serial") ? self.attack_serial : -1
    if (sound==soundBarkBomberBurst) {
        funForestSmokeAssert(self.blasting and self.life==16,"burst at immediate detonation")
        for (var i=0;i<array_length(global.forest_sound_events);++i) {
            var previous=global.forest_sound_events[i]
            funForestSmokeAssert(previous.owner!=self.id or previous.sound!=sound,"one cue per bomb")
        }
    }
    else {
        funForestSmokeAssert(kind!="barrel","silent bomb release")
        if (sound!=soundResinSlimeLand and sound!=soundForestBatWake) {
            funForestSmokeAssert(self.state=="attack" and self.attack_spawned,"cue at committed attack")
            for (var i=0;i<array_length(global.forest_sound_events);++i) {
                var previous=global.forest_sound_events[i]
                funForestSmokeAssert(previous.owner!=self.id or previous.sound!=sound or previous.serial!=serial,"one cue per attack")
            }
        }
        if (sound==soundForestBatWake) {
            for (var i=0;i<array_length(global.forest_sound_events);++i) {
                var previous=global.forest_sound_events[i]
                funForestSmokeAssert(previous.owner!=self.id or previous.sound!=sound,"one initial wake per bat")
            }
        }
        if (sound==soundResinSlimeLand) funForestSmokeAssert(!self.air_navigation_active,"landing after airborne movement")
    }
    array_push(global.forest_sound_events,{owner:self.id,sound:sound,serial:serial,kind:kind})
    var voice=audio_play_sound(sound,priority,loop)
    funForestSmokeAssert(audio_is_playing(voice),"real selected cue is playing: "+audio_get_name(sound))
    return voice
}

/// Verifies the common effects setting and that all ten actual cues were reached in live battles.
function funForestSmokeCheckSelectedAudio() {
    var sounds=[soundResinSlimeLand,soundResinSlimeAttack,soundBarkBomberBurst,soundForestBatAttack,
        soundForestBatWake,soundBarkGuardShot,soundBarkGuardImpact,soundRootReaperSweep,soundRootReaperSlam,soundRootMawBite]
    var saved=global.sfx_enabled
    global.sfx_enabled=false
    funApplySfxSetting()
    for (var i=0;i<array_length(sounds);++i) funForestSmokeAssert(audio_sound_get_gain(sounds[i])==0,"effects mute "+audio_get_name(sounds[i]))
    global.sfx_enabled=true
    funApplySfxSetting()
    for (var i=0;i<array_length(sounds);++i) {
        var sound=sounds[i],count=0
        funForestSmokeAssert(audio_sound_get_gain(sound)==1,"effects enable "+audio_get_name(sound))
        for (var j=0;j<array_length(global.forest_sound_events);++j) if (global.forest_sound_events[j].sound==sound) count+=1
        funForestSmokeAssert(count>0,"live cue exercised "+audio_get_name(sound))
        show_debug_message("FOREST_AUDIO_CUE "+audio_get_name(sound)+" count="+string(count)+" length="+string(audio_sound_length(sound)))
    }
    global.sfx_enabled=saved
    funApplySfxSetting()
    show_debug_message("FOREST_AUDIO_PASS all ten cues play, correct timing, no repeated attack/wake cues, effects toggle")
}
