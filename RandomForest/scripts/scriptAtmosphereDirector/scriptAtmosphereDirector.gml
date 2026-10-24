/// Initializes a persistent scheduler with gameplay-independent randomness.
function funAtmosphereDirectorCreate() {
    self.choices={}
    var groups=variable_struct_get_names(self.catalog)
    for (var i=0;i<array_length(groups);++i) variable_struct_set(self.choices,groups[i],1)
    self.mix_random={seed:max(1,floor(get_timer()) mod 2147483647)}
    self.auto_mode=true
    self.audio_group=""
    self.remaining=0
    self.calm_runs=0
    self.was_silence=false
    self.last_source=-1
    self.last_track=""
}

/// Picks stable beds, quiet gaps and rare accents from the approved pool.
function funAtmosphereDirectorPick(group,first=false) {
    var items=variable_struct_get(self.catalog,group),calm_count=0
    for (var i=0;i<array_length(items);++i)
        if (items[i].weight>0 and items[i].role=="calm") calm_count++
    var weights=[],total=0
    for (var i=0;i<array_length(items);++i) {
        var item=items[i],weight=item.weight
        // A sole calm recording can continue without restarting its voice or adding a fade.
        var continue_calm=calm_count==1 and item.role=="calm"
        if (!self.was_silence and !continue_calm and (item.id==self.last_track or item.source_id==self.last_source)) weight=0
        if (item.role=="accent" and calm_count>0 and (first or self.calm_runs<2)) weight=0
        array_push(weights,weight);total+=weight
    }
    var quiet_weight=!first and !self.was_silence and (self.calm_runs>0 or calm_count==0) ? (group=="fog" ? 3 : 1) : 0
    total+=quiet_weight
    var roll=funWeatherRandom(self.mix_random)*total,choice=0
    for (var i=0;i<array_length(weights);++i) {
        roll-=weights[i]
        if (roll<0) {choice=i+1;break;}
    }
    variable_struct_set(self.choices,group,choice)
    self.was_silence=choice==0
    if (choice==0) {self.remaining=12+funWeatherRandom(self.mix_random)*10;return;}
    var selected=items[choice-1]
    self.last_track=selected.id;self.last_source=selected.source_id
    self.calm_runs=selected.role=="accent" ? 0 : min(2,self.calm_runs+1)
    self.remaining=selected.min_seconds+funWeatherRandom(self.mix_random)*(selected.max_seconds-selected.min_seconds)
}

/// Holds segment time through its fade and defers rotation just before weather changes.
function funAtmosphereDirectorStep(group,dt,weather_remaining=999999) {
    var reference=group=="rain" or group=="storm" or group=="drips"
    if (self.audio_group!=group) {
        self.audio_group=group
        self.remaining=0;self.calm_runs=0;self.was_silence=false
        if (self.auto_mode and !reference) funAtmosphereDirectorPick(group,true)
    }
    if (!self.auto_mode or reference or self.mix_elapsed<self.mix_duration) return;
    self.remaining-=dt
    if (self.remaining<=0 and weather_remaining>15) funAtmosphereDirectorPick(group)
}
