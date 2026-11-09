/** Exercise the selected V08, continuous motion, prepared black frames, audio alignment and skip lifetime. */
'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'../../RandomForest'),read=f=>fs.readFileSync(path.join(root,f),'utf8');
const translate=s=>s.replace(/\bstatic positions\b/g,'var positions').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||').replace(/\bexit\b/g,'return').replace(/repeat \(24\)/g,'for(var iteration=0;iteration<24;iteration++)');
let now=0,clicked=false,actions=0,nextSurface=0;const cues=[],stopped=[],freed=[],keys=new Set(),surfaces=new Set(),letters=[];
const c=vm.createContext({self:{},global:{sfx_enabled:true,default_font_24:1},get_timer:()=>now,
    min:Math.min,max:Math.max,floor:Math.floor,round:Math.round,power:Math.pow,sqr:x=>x*x,
    clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,
    soundStartupIntro:'intro',vk_enter:'enter',vk_space:'space',vk_escape:'escape',mb_left:'left',
    keyboard_check_pressed:key=>keys.has(key),mouse_check_button_pressed:()=>clicked,
    audio_sound_length:()=>2.3,audio_play_sound:(asset,priority,loop,gain,offset)=>{assert.equal(asset,'intro');assert.equal(loop,false);assert.equal(gain,1);const handle=100+cues.length;cues.push({handle,now,offset});return handle;},
    audio_stop_sound:handle=>stopped.push(handle),
    surface_exists:id=>surfaces.has(id),surface_create:()=>{surfaces.add(++nextSurface);return nextSurface;},surface_free:id=>{surfaces.delete(id);freed.push(id);},
    surface_set_target(){},surface_reset_target(){},draw_clear_alpha(){},gpu_get_blendmode_ext_sepalpha:()=>[1,2,3,4],gpu_set_blendmode_ext_sepalpha(){},gpu_set_blendmode_ext(){},gpu_get_texfilter:()=>false,gpu_set_tex_filter(){},
    bm_src_alpha:1,bm_inv_src_alpha:2,bm_one:3,c_black:0,c_white:0xffffff,fa_left:0,fa_center:1,fa_middle:1,
    draw_set_alpha(){},draw_set_color(){},draw_circle(){},draw_rectangle(){},draw_set_font(){},draw_set_halign(){},draw_set_valign(){},draw_surface_ext(){},font_cache_glyph(){},
    draw_text_transformed:(x,y,text,sx,sy)=>letters.push({x,y,text,sx,sy}),make_colour_rgb:(r,g,b)=>r+g*256+b*65536,merge_colour:(a,b,t)=>a+(b-a)*t,
    point_distance:(x,y,a,b)=>Math.hypot(x-a,y-b),string_length:s=>s.length,string_ord_at:(s,i)=>s.charCodeAt(i-1),string_char_at:(s,i)=>s[i-1],string_copy:(s,i,n)=>s.slice(i-1,i-1+n),string_width:s=>s.length*10,
    instance_exists:()=>false,oSettings:'settings',oFadeOut:'fade',funMenuBackgroundStep(){},funMenuBackgroundCleanup(){},funBrokenMenuCleanup(){},
});
for(const script of ['scriptIntroFirefly','scriptStartupIntro'])vm.runInContext(translate(read(`scripts/${script}/${script}.gml`)),c);
const point=seconds=>[c.funIntroFlightSample(seconds*60,0),c.funIntroFlightSample(seconds*60,1)];
assert.deepEqual(point(0),[134.75,142.5]);assert.deepEqual(point(5),[386,114]);
assert.deepEqual(point(1.5),[78,129]);
const epsilon=.00001,left=point(1.5-epsilon),join=point(1.5),right=point(1.5+epsilon);
const incoming=join.map((v,i)=>(v-left[i])/epsilon),outgoing=join.map((v,i)=>(right[i]-v)/epsilon);
assert(Math.hypot(...incoming.map((v,i)=>v-outgoing[i]))<.03,'continuous velocity vector across the return join');
assert(Math.abs(Math.hypot(...incoming)-32.449645)<.02);
let prev=point(.25);
for(let i=1;i<=120;i++){const p=point(.25+i/300);assert(p[0]<prev[0]&&p[1]<prev[1],'no back-and-forth jitter on initial departure');prev=p;}
assert.notEqual(c.funIntroFlightSample(15.01,0),c.funIntroFlightSample(15.02,0),'subframe movement is not rounded to GUI pixels');
for(let f=165;f<330;f+=.25){assert.equal(c.funIntroFlightSample(f,0),386);assert.equal(c.funIntroFlightSample(f,1),114);assert.equal(c.funIntroFlightProgress(f),1);}
for(const x of [100,135,240,330,380]){const frame=c.funIntroFlightFrameAtX(x);assert(frame>=90&&frame<=165);assert(Math.abs(c.funIntroFlightSample(frame,0)-x)<.0001);}

/** Present the two actual preparation Draws before advancing the scene clock. */
function prepare(){c.funStartupIntroDraw();now+=16667;c.funStartupIntroDraw();assert.equal(c.self.startup_intro.ready,true);return c.self.startup_intro.origin_time;}

c.funStartupIntroStart();assert.equal(cues.length,0);now+=5000000;c.funStartupIntroStep();assert.equal(c.self.startup_intro.frame,-18,'Create/initial graphics stalls do not advance the intro');
let origin=prepare();now=origin-1;c.funStartupIntroStep();assert(c.self.startup_intro.frame<0);assert.equal(cues.length,0);
now=origin;c.funStartupIntroStep();assert.equal(c.self.startup_intro.frame,0,'300ms of black after preparation');
now=origin+460000;c.funStartupIntroStep();assert.equal(cues.length,0);
now=origin+1010000;c.funStartupIntroStep();assert.equal(cues.length,1);assert(Math.abs(cues[0].offset-.0125416666666667)<1e-8);
assert(Math.abs((cues[0].now-origin)/1e6+1.2525416666666667-cues[0].offset-2.25)<1e-8,'sound moved 0.5 seconds earlier than crest/stop alignment');
now=origin+1600000;c.funStartupIntroStep();assert.equal(c.self.startup_intro.frame,96);
now=origin+2750000;c.funStartupIntroStep();assert.equal(c.self.startup_intro.frame,165);
now=origin+5149000;c.funStartupIntroStep();assert.equal(c.self.startup_intro.active,true);
now=origin+5150000;c.funStartupIntroStep();assert.equal(c.self.startup_intro.active,false);assert.equal(c.self.startup_intro.sound,-1);assert.equal(surfaces.size,0);
assert(!read('scripts/scriptStartupIntro/scriptStartupIntro.gml').includes('audio_sound_get_track_position'),'mixer block updates cannot shake the light');

const menuStep=`(function(){${translate(read('objects/oMenu/Step_0.gml'))}})()`;
for(const afterSound of [false,true])for(const key of ['enter','space','escape','mouse']){
    keys.clear();clicked=false;c.self={broken_menu:false,functions:[()=>actions++],current_index:0,immediate_actions:[true]};
    c.funStartupIntroStart();if(afterSound){origin=prepare();now=origin+1600000;c.funStartupIntroStep();}
    const handle=c.self.startup_intro.sound;if(key==='mouse')clicked=true;else keys.add(key);
    vm.runInContext(menuStep,c);assert.equal(c.self.startup_intro.active,false);assert.equal(c.self.mouse_allowed_counter,10);assert.equal(actions,0);assert.equal(surfaces.size,0);if(handle!==-1)assert.equal(stopped.at(-1),handle);
}
keys.clear();clicked=false;c.funStartupIntroStart();origin=prepare();now=origin+1600000;c.funStartupIntroStep();const handle=c.self.startup_intro.sound;
vm.runInContext(translate(read('objects/oMenu/CleanUp_0.gml')),c);assert.equal(stopped.at(-1),handle);assert.equal(surfaces.size,0);
c.global.sfx_enabled=false;const before=cues.length;c.funStartupIntroStart();origin=prepare();now=origin+2750000;c.funStartupIntroStep();assert.equal(cues.length,before);assert.equal(c.self.startup_intro.frame,165);now=origin+5150000;c.funStartupIntroStep();assert.equal(c.self.startup_intro.active,false);
const resource=JSON.parse(read('sounds/soundStartupIntro/soundStartupIntro.yy').replace(/,\s*([}\]])/g,'$1'));assert(Math.abs(resource.volume-10**(-10/20)*.7)<1e-7,'GameMaker stores the authored gain with finite decimal precision');assert.equal(resource.preload,true);assert.equal(resource.duration,2.3);
assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'sounds/soundStartupIntro/soundStartupIntro.wav'))).digest('hex'),'520eae2b72764057ce4c18677a9d94a19c56d4e43671767e355dd8fd443d7c1e','original cue bytes unchanged');
let route;Object.assign(c,{alarm:[],rMenu:'menu',window_center(){},room_goto:room=>route=room,funOpenStoryEnding:real=>route=real?'true':'finale'});
for(const [stage,completed,expected] of [[0,false,'menu'],[0,true,'finale'],[1,true,'true'],[2,true,'menu']]){Object.assign(c.global,{ending_stage:stage,special_level_completed:completed,startup_intro_pending:true});vm.runInContext(translate(read('objects/oLoading/Alarm_0.gml')),c);assert.equal(route,expected);assert.equal(c.global.startup_intro_pending,expected==='menu');}
console.log('PASS: V08 subpixel trajectory, continuous join, prepared 300ms black, original cue -30% shifted 0.5s earlier, skip/cleanup/mute and ending routes.');
