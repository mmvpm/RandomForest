/// Reconstructs a colony member's gradual shelter state when a room is reloaded.
function funWeatherMothInitial(weather, index) {
    var delay = index * (weather.ecology_wet ? 0.22 : 0.28)
    var progress = clamp((weather.ecology_time-delay)/0.7,0,1)
    return weather.ecology_wet ? 1-progress : progress
}

/// Fades residents one after another without changing their accepted flight or appearance.
function funWeatherMothVisibility(weather, moth, index, dt) {
    var target = weather.ecology_wet ? 0 : 1
    if (moth.weather_alpha == target) return;
    var delay = index * (weather.ecology_wet ? 0.22 : 0.28)
    if (weather.ecology_time < delay) return;
    moth.weather_alpha += clamp(target-moth.weather_alpha,-dt/0.7,dt/0.7)
}

/// Stops new fireflies of both colours during rain, as selected by the author.
function funWeatherFireflySpawnAllowed() {
    if (!variable_global_exists("forest_weather")) return true
    return !global.forest_weather.ecology_wet
}

/// Prevents a new room from replacing a gradual dry-weather return with an initial batch.
function funWeatherFirefliesReturning() {
    if (!variable_global_exists("forest_weather")) return false
    return !global.forest_weather.ecology_wet and global.forest_weather.ecology_time < 12
}

/// Retires existing fireflies at real stone during rain without changing their movement.
function funWeatherFireflyHitWall(firefly) {
    if (funWeatherFireflySpawnAllowed() or !instance_exists(oAmbientSystem)) return false
    var ambient = oAmbientSystem
    var column = floor(firefly.x/12), row = floor(firefly.y/12)
    if (column < 0 or row < 0 or column >= ambient.grid_width or row >= ambient.grid_height) return true
    return ambient.tiles[row*ambient.grid_width+column] != 0
}
