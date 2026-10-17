"""Import original-motion forest enemies and pixel body masks as native GameMaker resources."""
import copy,json,shutil,uuid
from pathlib import Path
import numpy as np
from PIL import Image
from theme_assets import ROOT,PROJECT,read_resource,write_resource,register_resources
from lighting_assets import copy_frames,pixel_digest
from forest_enemy_pixels import body_mask,canonical_module,redesign,barrel_cast,highlight_guard_burst

WORK=ROOT/'.temp/enemy_integration'
DOWNLOADS=Path.home()/'Downloads/sprites/characters'
ORIGINAL_KINDS={'bat','sweeper'}
DEFINITIONS={
 'slime':dict(folder='slime-dungeonenemy1-slime-348',prefix='sResinSlime',name='Смоляной прыгун',themes=['evening','night','morning'],origin=[30,39],states=['idle','hop','attack','hurt','death']),
 'barrel':dict(folder='penusbmic-dungeon-enemy-pack-2-barrel-bomber',prefix='sBarkBomber',name='Коробейник спор',themes=['night'],origin=[86,51],states=['idle','run','attack','hurt','death']),
 'bat':dict(folder='penusbmic-dungeon-enemy-pack-3-dungeon-bat',prefix='sForestBat',name='Вересковая мышь',themes=['night'],origin=[27,51],states=['idle','fly','attack','hurt','death','wake']),
 'guard':dict(folder='sci-fi-character-pack-7-mud-guard-droid',prefix='sBarkGuard',name='Берестяной страж',themes=['day','evening','night','morning'],origin=[23,24],states=['idle','run','attack-1','attack-2','hurt','death']),
 'sweeper':dict(folder='penusbmic-sci-fi-dark-edition-character-add-on-shock-sweeper',prefix='sRootReaper',name='Полый жнец',themes=['night'],origin=[28,31],states=['idle','walk','attack-sweep','attack-slam','hurt','death','wake','jump','fall'])}


def state_name(state):
    """Keep animation names readable and independent of downloaded directory spelling."""
    return ''.join(part.capitalize() for part in state.replace('-',' ').split())


def sprite(name,images,origin,fps=10,precise=False):
    """Write ordered native frames with one layer, explicit origins and ordinary rectangular masks."""
    meta=copy.deepcopy(read_resource(PROJECT/'sprites/sPlayerIdle/sPlayerIdle.yy'))
    meta.update(name=name,**{'%Name':name},width=images[0].width,height=images[0].height,origin=9,bboxMode=0,collisionKind=4 if precise else 1,collisionTolerance=0)
    meta['parent']={'name':'Sprites','path':'folders/Sprites.yy'}
    frame_ids=[str(uuid.uuid5(uuid.NAMESPACE_URL,f'{name}/frame/{i}')) for i in range(len(images))]
    layer=str(uuid.uuid5(uuid.NAMESPACE_URL,f'{name}/layer'))
    frame=copy.deepcopy(meta['frames'][0]);meta['frames']=[]
    for fid in frame_ids:meta['frames'].append(dict(frame,name=fid,**{'%Name':fid}))
    meta['layers'][0].update(name=layer,**{'%Name':layer})
    seq=meta['sequence'];seq.update(name=name,**{'%Name':name},length=float(len(images)),xorigin=origin[0],yorigin=origin[1],playbackSpeed=float(fps))
    key=copy.deepcopy(seq['tracks'][0]['keyframes']['Keyframes'][0]);keys=[]
    for i,fid in enumerate(frame_ids):
        k=copy.deepcopy(key);k.update(Key=float(i),id=str(uuid.uuid5(uuid.NAMESPACE_URL,f'{name}/key/{i}')))
        k['Channels']['0']['Id']={'name':fid,'path':f'sprites/{name}/{name}.yy'};keys.append(k)
    seq['tracks'][0]['keyframes']['Keyframes']=keys
    bounds=[im.getbbox() for im in images if im.getbbox()]
    if bounds:
        meta.update(bbox_left=min(b[0] for b in bounds),bbox_top=min(b[1] for b in bounds),bbox_right=max(b[2] for b in bounds)-1,bbox_bottom=max(b[3] for b in bounds)-1)
    write_resource(PROJECT/f'sprites/{name}/{name}.yy',meta)
    for im,fid in zip(images,frame_ids,strict=True):
        p=PROJECT/f'sprites/{name}';im.save(p/f'{fid}.png');lp=p/'layers'/fid;lp.mkdir(parents=True,exist_ok=True);im.save(lp/f'{layer}.png')
    return ('sprites',name)


def import_donors():
    """Bake all requested skins while retaining donor frame sizes, opacity and ordered poses."""
    entries=[];records=[]
    for kind,definition in DEFINITIONS.items():
        source=DOWNLOADS/definition['folder']/'frames-fixed-v3';local=WORK/'sources'/kind
        if not local.exists():shutil.copytree(source,local)
        module=None
        if kind not in ORIGINAL_KINDS and kind!='guard':
            module=canonical_module(WORK/'concepts'/f'{kind}.png',[24,24]);module.save(WORK/'concepts'/f'{kind}-native.png')
        record=dict(kind=kind,**definition,animations=[])
        for state in definition['states']:
            files=sorted((local/state).glob('*.png'));frames=[Image.open(f).convert('RGBA') for f in files];masks=[]
            for i,im in enumerate(frames):
                mask=body_mask(im,kind,state,i)
                if not mask.getbbox():
                    alternate=frames[0] if i else frames[-1];mask=body_mask(alternate,kind,state,i)
                    if not mask.getbbox():mask=body_mask(Image.open(sorted((local/'idle').glob('*.png'))[0]).convert('RGBA'),kind,'idle',0)
                    a=np.array(mask);a[np.array(im)[:,:,3]<128]=0;mask=Image.fromarray(a)
                masks.append(mask)
            base=definition['prefix']+state_name(state)
            animation={'state':state,'body':definition['prefix']+'Collision','count':len(frames),'fps':8 if state=='idle' else 12 if state in ('hop','run','walk','fly') else 10,'variants':{}}
            for theme in definition['themes']:
                art=[im.copy() for im in frames] if kind in ORIGINAL_KINDS else [redesign(im,kind,theme,module,m) for im,m in zip(frames,masks,strict=True)]
                if kind=='guard' and state=='attack-2' and theme=='night':
                    art=[highlight_guard_burst(im,mask,i) for i,(im,mask) in enumerate(zip(art,masks,strict=True))]
                # Preserve the complete donor animation and separate the caster by connected pixels.
                if kind=='barrel' and state=='attack':
                    cast=[barrel_cast(source,image,i) for i,(source,image) in enumerate(zip(frames,art,strict=True))]
                    entries.append(sprite(base+'Cast',cast,definition['origin'],animation['fps']))
                suffix='' if theme==definition['themes'][0] else theme.capitalize()
                name=base+suffix;entries.append(sprite(name,art,definition['origin'],animation['fps']))
                folder=WORK/'frames'/kind/theme/state;folder.mkdir(parents=True,exist_ok=True)
                for i,im in enumerate(art):im.save(folder/f'{i:03d}.png')
                if kind in ORIGINAL_KINDS:
                    # Keep the downloaded PNGs themselves, including their original pixel colors and alpha.
                    meta=read_resource(PROJECT/f'sprites/{name}/{name}.yy')
                    for i,(source,frame) in enumerate(zip(files,meta['frames'],strict=True)):
                        shutil.copyfile(source,folder/f'{i:03d}.png')
                        shutil.copyfile(source,PROJECT/f'sprites/{name}/{frame["name"]}.png')
                        shutil.copyfile(source,PROJECT/f'sprites/{name}/layers/{frame["name"]}/{meta["layers"][0]["name"]}.png')
                mp=WORK/'masks'/kind/state;mp.mkdir(parents=True,exist_ok=True)
                for i,im in enumerate(masks):im.save(mp/f'{i:03d}.png')
                animation['variants'][theme]=name
            record['animations'].append(animation)
        records.append(record)
    return entries,records


def import_suchnik():
    """Replace only existing evening skeleton art, retaining every approved Suchnik source PNG exactly."""
    source=ROOT/'.temp/new_enemy_study';data=read_resource(source/'enemies/suchnik.json');entries=[]
    backup=WORK/'previous-skeleton-evening';backup.mkdir(exist_ok=True)
    for state in data['states']:
        base=state['source_sprite'];target=base+'Evening';paths=[source/f for f in state['frames']]
        if base.endswith('Bloom'):continue
        if not (backup/target).exists():shutil.copytree(PROJECT/f'sprites/{target}',backup/target)
        copy_frames(base,target,paths)
    # The donor's bloom outlines are kept for the unchanged combat feedback layer.
    selection=read_resource(ROOT/'tools/lighting_selection.json')
    for state in data['states']:
        target=state['source_sprite']+'Evening'
        if state['source_sprite'].endswith('Bloom'):continue
        meta=read_resource(PROJECT/f'sprites/{target}/{target}.yy')
        selection.setdefault('art_overrides',{})[target]='suchnik'
        selection['sprites'][target]=pixel_digest([PROJECT/f'sprites/{target}/{f["name"]}.png' for f in meta['frames']])
    write_resource(ROOT/'tools/lighting_selection.json',selection)
    return entries


def import_maw():
    """Copy the latest approved jaw, body masks and independent rosette modules without recoloring."""
    source=ROOT/'.temp/simple_motion_study';enemy=next(e for e in read_resource(source/'manifest.json')['enemies'] if e['slug']=='root_maw');entries=[]
    record=dict(kind='maw',prefix='sRootMaw',origin=enemy['origin'],themes=['night'],name=enemy['name'],animations=[])
    for state in enemy['states']:
        name='sRootMaw'+state_name(state['state']);frames=[Image.open(source/f).convert('RGBA') for f in state['frames']]
        entries.append(sprite(name,frames,enemy['origin'],1000/state['ms'][0]))
        bare_sheet=Image.open(source/state['bare_sheet']).convert('RGBA')
        bare=[bare_sheet.crop((i*state['width'],0,(i+1)*state['width'],state['height'])) for i in range(len(frames))]
        entries.append(sprite(name+'Bare',bare,enemy['origin'],1000/state['ms'][0]))
        record['animations'].append({'state':state['state'],'count':len(frames),'fps':1000/state['ms'][0],'body':'sRootMawCollision','variants':{'night':name}})
    rosettes=[Image.open(source/f'parts/root_maw/rosette-{i}.png').convert('RGBA') for i in range(8)]
    entries.append(sprite('sRootMawRosette',rosettes,[9,11],3));return entries,record


def main():
    """Install reviewed material designs and existing prototypes into the actual game project."""
    entries,records=import_donors();entries+=import_suchnik();maw,record=import_maw();entries+=maw;records.append(record)
    # A seed shell has an explicit 5-pixel body, independent of its blast feedback.
    seed=Image.new('RGBA',(7,7));pixels=seed.load()
    for y in range(1,6):
        for x in range(1,6):
            if (x-3)**2+(y-3)**2<=7:pixels[x,y]=(143 if (x+y)%3 else 185,110,76,255)
    entries.append(sprite('sForestSeed',[seed],[3,3],1))
    register_resources(entries);write_resource(WORK/'manifest.json',{'enemies':records,'pixel_motion':'original native frame alpha and body poses; caster bomb separated from free projectile','source':'frames-fixed-v3','concepts':'built-in imagegen','masks':'fixed rectangular colliders and small authored attack regions'})
    from forest_enemy_collision_assets import main as collision_assets
    collision_assets()
    print(f'Imported {len(entries)} native sprite resources; Suchnik evening names retained')


if __name__=='__main__':main()
