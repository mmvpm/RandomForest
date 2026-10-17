"""Build a review gallery from exactly the sprites and body masks installed in the game."""
import json,shutil
from PIL import Image,ImageDraw
from theme_assets import ROOT,PROJECT,read_resource,write_resource
from forest_enemy_assets import WORK


def paths(name):
    """Resolve compiled resource frame order to project-relative image paths."""
    meta=read_resource(PROJECT/f'sprites/{name}/{name}.yy')
    return [f'../../RandomForest/sprites/{name}/{frame["name"]}.png' for frame in meta['frames']]


def main():
    """Expose original/redesigned animation, body overlays and real forest lighting."""
    data=read_resource(WORK/'manifest.json');backgrounds={};terrain={}
    poses=read_resource(ROOT/'tools/forest_enemy_pose_data.json')
    for time in ('day','evening','night','morning'):
        suffix='' if time=='day' else time.capitalize();bgname='sBackground'+suffix
        backgrounds[time]=paths(bgname)[0];terrain[time]=paths('sPlatforms'+suffix)[0]
    data.update(backgrounds=backgrounds,terrain=terrain)
    for enemy in data['enemies']:
        enemy['original_art']=enemy['kind'] in ('bat','sweeper')
        base='sBungaloBloom' if enemy['kind']=='sweeper' else 'sSlimeBloom' if enemy['kind'] in ('slime','maw') else 'sSkeletonBloom'
        enemy['glows']={}
        for time in enemy['themes']:
            name=base+('' if time=='day' else time.capitalize());meta=read_resource(PROJECT/f'sprites/{name}/{name}.yy')
            enemy['glows'][time]={'file':paths(name)[0],'origin':[meta['sequence']['xorigin'],meta['sequence']['yorigin']]}
        if enemy['kind']=='maw':
            meta=read_resource(PROJECT/'sprites/sRootMawRosette/sRootMawRosette.yy')
            enemy['rosette']={'frames':paths('sRootMawRosette'),'origin':[meta['sequence']['xorigin'],meta['sequence']['yorigin']], 'durations':[360,240,360,420,360,240,360,420]}
        for anim in enemy['animations']:
            anim['original']=[str(f.relative_to(WORK)) for f in sorted((WORK/'sources'/enemy['kind']/anim['state']).glob('*.png'))]
            anim['masks']=paths(anim['body'])*anim['count'];anim['frames']={time:paths(name+('Bare' if enemy['kind']=='maw' else '')) for time,name in anim['variants'].items()}
            bounds=[Image.open(WORK/f).getchannel('A').point(lambda a:255 if a>=4 else 0).getbbox() for f in anim['frames'][enemy['themes'][0]]]
            bounds=[b for b in bounds if b]
            anim['draw_bounds']=[min(b[0] for b in bounds),min(b[1] for b in bounds),max(b[2] for b in bounds),max(b[3] for b in bounds)]
            base=next(iter(anim['variants'].values()))
            # This reference view shows native source poses, before physical in-place drawing offsets.
            anim['glow_offsets']=[[-p['x'],p['light_y']-p['y']] for p in poses[base]]
            glow=base+'Bloom'
            if enemy['kind']=='maw' and (PROJECT/f'sprites/{glow}/{glow}.yy').exists():
                meta=read_resource(PROJECT/f'sprites/{glow}/{glow}.yy')
                anim['glow_frames']=paths(glow)
                anim['glow_origin']=[meta['sequence']['xorigin'],meta['sequence']['yorigin']]
    (WORK/'gallery-data.js').write_text('window.FOREST_ENEMY_GALLERY='+json.dumps(data,ensure_ascii=False)+';\n')
    donor_enemies=[e for e in data['enemies'] if e['kind']!='maw']
    board=Image.new('RGB',(960,len(donor_enemies)*130),'#141825');draw=ImageDraw.Draw(board)
    for row,e in enumerate(donor_enemies):
        a=next(a for a in e['animations'] if a['state']==('fly' if e['kind']=='bat' else 'idle'))
        draw.text((8,row*130+5),e['kind'],fill='#dfd4c7')
        original=Image.open(WORK/a['original'][0]).convert('RGBA');original=original.crop(original.getbbox());original=original.resize((original.width*4,original.height*4),Image.Resampling.NEAREST);board.paste(original,(20,row*130+26),original)
        for col,t in enumerate(e['themes']):
            im=Image.open(WORK/a['frames'][t][0]).convert('RGBA');im=im.crop(im.getbbox());im=im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST)
            x=210+col*185;board.paste(im,(x,row*130+26),im);draw.text((x,row*130+7),t,fill='#d7cbd5')
    board.save(WORK/'skins-overview.png');print('Gallery uses actual installed frames, masks and source-game backgrounds')


if __name__=='__main__':main()
