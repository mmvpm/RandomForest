/** Exercise actual rain emission through gradual onset, weather changes and room-local resets. */
'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const root=path.resolve(__dirname,'../../RandomForest/scripts');
const context=vm.createContext({self:{},global:{music_enabled:true},view_camera:[0],
 floor:Math.floor,round:Math.round,min:Math.min,max:Math.max,abs:Math.abs,sin:Math.sin,frac:v=>v-Math.floor(v),
 clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,
 array_length:a=>a.length,array_push:(a,v)=>a.push(v),array_delete:(a,i,n)=>a.splice(i,n),
 camera_get_view_x:()=>0,camera_get_view_y:()=>0});
/** Translate operators while retaining the production weather and emitter logic. */
function load(name){vm.runInContext(fs.readFileSync(path.join(root,name,name+'.gml'),'utf8').replace(/^#macro (\w+) (.+)$/gm,'const $1 = $2;').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||').replace(/\bmod\b/g,'%'),context);}
load('scriptForestWeather');load('scriptAmbientRain');
/** Start a controlled natural weather change with its original visual intensity fields. */
function begin(theme,from,to){
 const w=context.funWeatherCreate(123,theme);context.funWeatherSetPhase(w,from,999999);w.rain=0;w.fog=w.target_fog;
 context.self={weather:w};context.funAmbientResetRain();context.funWeatherSetPhase(w,to,999999);return w;
}
/** Advance both production weather and complete drop lifetimes at the normal frame rate. */
function step(w,frames){for(let i=0;i<frames;i++){context.funWeatherUpdate(w,1/60);context.funAmbientRainStep();assert(context.self.rain_drops.length<=600);}}
const report=[];
for(const theme of ['evening','night'])for(const from of ['dry','fog'])for(const to of ['rain','storm']){
 const w=begin(theme,from,to),seconds=[];let previous=0;
 assert.equal(context.funWeatherRainDensity(w),0);
 for(let second=1;second<=12;second++){
  step(w,60);const emitted=context.self.rain_birth_index-3;
  seconds.push({second,births:emitted-previous,alive:context.self.rain_drops.length,density:context.funWeatherRainDensity(w)});previous=emitted;
 }
 assert(seconds[0].births<seconds[2].births,'first sparse drops precede denser rain');
 assert(seconds[2].births<seconds[5].births&&seconds[5].births<seconds[11].births,'rain grows throughout the twelve-second sound transition');
 assert(seconds[2].density<.08,'first drops leave a quiet opening');assert(seconds[5].density<.2,'the first drizzle is not already a full shower');assert.equal(seconds[11].density,1);
 report.push({theme,from,to,seconds});
}
for(const from of ['dry','fog'])for(const to of ['rain','storm'])assert.deepEqual(
 report.find(r=>r.theme==='evening'&&r.from===from&&r.to===to).seconds,
 report.find(r=>r.theme==='night'&&r.from===from&&r.to===to).seconds,'lighting cannot change the rain onset');
// Existing rainy sessions and the approved steady rain keep their original birth rates and art.
for(const [phase,amount,births,height,vy,alpha] of [['rain',.5,3,5,4.8,.24],['storm',1,8,7,6.6,.28]]){
 const w=begin('night','dry',phase);w.rain=amount;w.rain_onset=1;
 for(let i=0;i<60;i++)context.funAmbientRainStep();
 assert.equal(context.self.rain_birth_index-3,births*60);
 for(const drop of context.self.rain_drops){assert.equal(drop.height,height);assert.equal(drop.life,65);assert.equal(drop.vy,vy);assert(Math.abs(drop.alpha-alpha)<1e-12);}
}
let coldRain=0;
for(let seed=1;seed<=500;seed++){
 const w=context.funWeatherCreate(seed,'night');assert.equal(w.rain_onset,1);
 if(w.target_rain>0)coldRain++;
}
assert(coldRain>0,'cold rainy sessions must be exercised');
// Room-local particles may reset; the session's onset must continue through restarts and intensity changes.
const w=begin('night','dry','rain');step(w,180);const progress=w.rain_onset;
context.funAmbientResetRain();assert.equal(w.rain_onset,progress);
context.funWeatherApplyTheme(w,'evening');assert.equal(w.rain_onset,progress);
context.funWeatherSetPhase(w,'storm',999999);assert.equal(w.rain_onset,progress);
step(w,180);const stormProgress=w.rain_onset;context.funWeatherSetPhase(w,'rain',999999);assert.equal(w.rain_onset,stormProgress);
context.funWeatherSetPhase(w,'drips',999999);step(w,1200);assert.equal(w.rain_onset,stormProgress,'ending rain cannot restart or accelerate the onset');
context.funWeatherSetPhase(w,'rain',999999);assert.equal(w.rain_onset,0,'a new rainy episode starts sparse again');
// Sound settings cannot affect the visual onset or spawn sequence.
const runs=[];
for(const enabled of [true,false]){context.global.music_enabled=enabled;const w=begin('night','dry','rain');step(w,360);runs.push(JSON.stringify(context.self.rain_drops));}
assert.equal(runs[0],runs[1]);
console.log('PASS: eight gradual rain onsets, identical evening/night density, original steady geometry/rates, cold weather, restart/intensity continuity and mute independence');
console.log(JSON.stringify(report));
