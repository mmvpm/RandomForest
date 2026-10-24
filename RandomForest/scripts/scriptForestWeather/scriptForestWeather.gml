/// Returns a private random sample without consuming gameplay randomness.
function funWeatherRandom(weather) {
    weather.seed = (weather.seed * 48271) mod 2147483647
    return weather.seed / 2147483647
}

/// Limits daylight to the two approved dry states without changing night-time transitions.
function funWeatherPhaseAllowed(phase, theme) {
    return (theme != "day" and theme != "morning") or phase == "dry" or phase == "seeds"
}

/// Adapts an existing session to the new room's lighting, preserving valid periods and timers.
function funWeatherApplyTheme(weather, theme) {
    weather.theme = theme
    if (!funWeatherPhaseAllowed(weather.phase,theme)) funWeatherSetPhase(weather,"dry")
    // A valid dry phase may still carry a fading evening fog/rain tail across the door.
    if (theme == "day" or theme == "morning") {
        weather.rain = 0;weather.fog = 0;weather.wetness = 0
        funWeatherSyncWildlife(weather,0)
    }
}

/// Lists the permitted weighted exits of the six-state weather machine.
function funWeatherChoices(phase, theme = "evening") {
    if (theme == "day" or theme == "morning")
        return [{phase:phase == "seeds" ? "dry" : "seeds",weight:1}]
    switch (phase) {
        case "rain": return [{phase:"drips",weight:8},{phase:"storm",weight:2}]
        case "storm": return [{phase:"rain",weight:3},{phase:"drips",weight:7}]
        case "drips": return [{phase:"dry",weight:5},{phase:"fog",weight:2},{phase:"seeds",weight:3}]
        case "seeds": return [{phase:"dry",weight:5},{phase:"fog",weight:3},{phase:"storm",weight:1},{phase:"rain",weight:1}]
        case "fog": return [{phase:"dry",weight:5},{phase:"seeds",weight:3},{phase:"storm",weight:1},{phase:"rain",weight:1}]
        default: return [{phase:"seeds",weight:4},{phase:"fog",weight:3},{phase:"storm",weight:1},{phase:"rain",weight:2}]
    }
}

/// Returns active-play duration bounds in seconds for an authored weather state.
function funWeatherDuration(phase) {
    if (phase == "storm") return [60,120]
    if (phase == "dry" or phase == "seeds") return [180,240]
    return [120,180]
}

/// Selects a weighted state without creating an unintended transition.
function funWeatherPick(weather, choices) {
    var total = 0
    for (var i = 0; i < array_length(choices); ++i) total += choices[i].weight
    var roll = funWeatherRandom(weather) * total
    for (var i = 0; i < array_length(choices); ++i) {
        roll -= choices[i].weight
        if (roll < 0) return choices[i].phase
    }
    return choices[array_length(choices)-1].phase
}

/// Includes the visible tail of rainfall before wildlife and residual drops return.
function funWeatherIsRaining(weather) {
    return weather.target_rain > 0 or weather.rain >= 0.005
}

/// Tracks one continuous rainy episode or dry return across room changes.
function funWeatherSyncWildlife(weather, dt) {
    var wet = funWeatherIsRaining(weather)
    if (wet != weather.ecology_wet) {
        weather.ecology_wet = wet
        weather.ecology_time = 0
    } else weather.ecology_time += dt
}

/// Starts a long weather period; wind stays fixed for the entire uninterrupted rain episode.
function funWeatherSetPhase(weather, phase, duration = 0) {
    if (!funWeatherPhaseAllowed(phase,weather.theme)) phase = "dry"
    var was_raining = funWeatherIsRaining(weather)
    weather.phase = phase
    weather.phase_age = 0
    weather.target_rain = 0
    weather.target_fog = 0
    if (phase == "rain" or phase == "storm") {
        weather.target_rain = phase == "storm" ? 1 : 0.5
        weather.rain_kind = phase
        if (!was_raining) {
            var winds = [0,0.18,-0.18]
            weather.wind = winds[floor(funWeatherRandom(weather)*3)]
        }
    }
    if (phase == "fog") weather.target_fog = 1
    if (phase == "drips") weather.wetness = 1
    var bounds = funWeatherDuration(phase)
    weather.duration = bounds[0] + funWeatherRandom(weather) * (bounds[1]-bounds[0])
    if (duration > 0) weather.duration = duration
    weather.remaining = weather.duration
}

/// Creates one session's weather; dry starting states are deliberately more common.
function funWeatherCreate(seed, theme = "evening") {
    var weather = {seed:max(1,floor(seed) mod 2147483647),phase:"dry",phase_age:0,theme:theme,
        remaining:0,duration:0,rain:0,fog:0,target_rain:0,target_fog:0,wetness:0,
        wind:0.18,time:0,rain_kind:"rain",
        ecology_wet:false,ecology_time:1000000,seed_amount:0,seed_x:0,seed_y:0,seed_points:[]}
    for (var i = 0; i < 100; ++i) array_push(weather.seed_points,
        {x:funWeatherRandom(weather)*640,y:funWeatherRandom(weather)*360})
    var initial = [{phase:"dry",weight:50},{phase:"seeds",weight:25},{phase:"fog",weight:15},
        {phase:"rain",weight:8},{phase:"storm",weight:2}]
    if (theme == "day" or theme == "morning") initial = [{phase:"dry",weight:2},{phase:"seeds",weight:1}]
    funWeatherSetPhase(weather,funWeatherPick(weather,initial))
    weather.rain = weather.target_rain
    weather.fog = weather.target_fog
    funWeatherSyncWildlife(weather,0)
    return weather
}

/// Keeps the same state, timer and wind through level changes, death and restart.
function funWeatherSession() {
    if (!variable_global_exists("forest_weather")) global.forest_weather = funWeatherCreate(get_timer(),funCurrentLevelTheme())
    return global.forest_weather
}

/// Advances the state machine and the already-approved visual fields during active gameplay.
function funWeatherUpdate(weather, dt) {
    weather.time += dt
    weather.phase_age += dt
    weather.remaining -= dt
    if (weather.remaining <= 0) funWeatherSetPhase(weather,funWeatherPick(weather,funWeatherChoices(weather.phase,weather.theme)))
    weather.rain = lerp(weather.rain,weather.target_rain,min(1,dt*0.35))
    weather.fog = lerp(weather.fog,weather.target_fog,min(1,dt*0.16))
    if (weather.target_rain > 0) weather.fog = max(0,weather.fog-dt*0.5)
    weather.wetness = clamp(weather.wetness+dt*(weather.rain*0.08-0.006),0,1)
    if (weather.phase == "drips") weather.wetness = max(0.2,weather.wetness)
    funWeatherSyncWildlife(weather,dt)
    // One four-second envelope drives staggered seeds without creating particle instances.
    weather.seed_amount = clamp(weather.seed_amount + dt * (weather.phase == "seeds" ? 0.25 : -0.25), 0, 1)
    weather.seed_x = (weather.seed_x+dt*(3+weather.wind*10)) mod 640
    weather.seed_y = (weather.seed_y-dt*18) mod 360
}
