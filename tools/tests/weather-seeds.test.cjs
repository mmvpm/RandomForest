/** Exercise actual weather and seed draw code through gradual and interrupted transitions. */
'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const root=path.resolve(__dirname,'../../RandomForest/scripts');
let alpha=1,lines=[];
const context=vm.createContext({self:{},floor:Math.floor,round:Math.round,min:Math.min,max:Math.max,sin:Math.sin,
  clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,
  array_length:a=>a.length,array_push:(a,v)=>a.push(v),
  make_colour_rgb:()=>0,draw_set_colour(){},draw_set_alpha:value=>alpha=value,
  draw_line:(...points)=>lines.push({alpha,points}),draw_point(){}
});

/** Translate only operators, leaving both production functions under test unchanged. */
function load(name){vm.runInContext(fs.readFileSync(path.join(root,name,name+'.gml'),'utf8').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||').replace(/\bmod\b/g,'%'),context);}
load('scriptForestWeather');load('scriptAmbientDraw');
const weather=context.funWeatherCreate(123,'day');context.self.weather=weather;
context.funWeatherSetPhase(weather,'dry');

/** Collect head alphas from the real bounded renderer. */
function draw(){lines=[];context.funAmbientDrawSeeds(0,0);return lines.filter((_,i)=>i%2===0);}

/** Advance the production model at 60 Hz without invoking procedural map generation. */
function advance(frames){for(let i=0;i<frames;i++)context.funWeatherUpdate(weather,1/60);}

assert.equal(draw().length,0);context.funWeatherSetPhase(weather,'seeds');assert.equal(draw().length,0);
advance(1);let heads=draw();assert(heads.length>0&&heads.length<4);assert(heads.every(h=>h.alpha<.02));
advance(59);const early=draw();assert(early.length>1&&early.length<28);
advance(180);heads=draw();assert.equal(heads.length,28);assert(heads.every(h=>Math.abs(h.alpha-.7)<1e-9));
const full=weather.seed_amount;context.funWeatherSetPhase(weather,'dry');assert.equal(weather.seed_amount,full,'phase change does not reset particles');
advance(60);heads=draw();assert(heads.some(h=>h.alpha<.7)&&heads.length>0);
advance(180);assert.equal(draw().length,0);assert.equal(weather.seed_amount,0);
context.funWeatherSetPhase(weather,'seeds');advance(60);const halfway=weather.seed_amount;
context.funWeatherSetPhase(weather,'dry');advance(20);assert(weather.seed_amount<halfway&&weather.seed_amount>0);
const interrupted=weather.seed_amount;context.funWeatherSetPhase(weather,'seeds');assert.equal(weather.seed_amount,interrupted);
advance(240);weather.theme='night';context.funWeatherSetPhase(weather,'rain');advance(1);
assert(draw().length>0,'seeds leave a soft tail as precipitation starts');advance(240);assert.equal(draw().length,0);
console.log('PASS: four-second staggered seeds, original 28-seed steady art, interrupted fade, no phase-reset pop and smooth rain suppression');
