"""Install small rectangular colliders and authored pose offsets, without animated pixel masks."""
import importlib.util
import json
import re
import shutil
import sys
from pathlib import Path

from PIL import Image

from forest_enemy_assets import sprite
from theme_assets import ROOT, PROJECT, read_resource, write_resource, register_resources, append_entries

DATA = ROOT / 'tools/forest_enemy_pose_data.json'
PREFIXES = ('sResinSlime', 'sBarkBomber', 'sBarkGuard', 'sRootReaper', 'sForestBat', 'sRootMaw')


def source_pose_data():
    """Recover a few pose anchors and attack rectangles once from the pre-revision authoring masks."""
    if DATA.exists():
        return read_resource(DATA)
    backup = ROOT / '.temp/enemy_revision/before'
    data = {}
    for folder in sorted((backup / 'sprites').iterdir()):
        name = folder.name
        if not name.endswith('Body') or not name.startswith(PREFIXES):
            continue
        base = name[:-4]
        meta = read_resource(folder / (name + '.yy'))
        ox, oy = meta['sequence']['xorigin'], meta['sequence']['yorigin']
        frames = []
        for f in meta['frames']:
            image = Image.open(folder / (f['name'] + '.png')).convert('RGBA')
            bounds = image.getchannel('A').getbbox()
            dx = dy = 0
            cy = -10
            if bounds:
                cx = (bounds[0] + bounds[2] - 1) / 2 - ox
                cy = (bounds[1] + bounds[3] - 1) / 2 - oy
                if base.startswith(('sResinSlime', 'sRootReaper')):
                    dx = -cx
                if base.startswith('sResinSlime'):
                    dy = oy - bounds[3]
                if base in ('sForestBatIdle', 'sForestBatWake'):
                    dx, dy = -cx, -cy
            frames.append({'x': dx, 'y': dy, 'light_y': cy + dy, 'strike': []})
        strike = backup / f'sprites/{base}Strike/{base}Strike.yy'
        if strike.exists():
            sm = read_resource(strike)
            for pose, f in zip(frames, sm['frames'], strict=True):
                b = Image.open(strike.parent / (f['name'] + '.png')).getchannel('A').getbbox()
                if b:
                    rect = [b[0]-ox+pose['x'], b[1]-oy+pose['y'],
                            b[2]-ox+pose['x'], b[3]-oy+pose['y']]
                    if base.startswith('sRootReaper'):
                        rect[0] = max(-6, rect[0])
                    pose['strike'] = rect
        data[base] = frames
    # The plant already has explicit root/jaw anchors; no pixel outline is needed at runtime.
    sys.path.insert(0, str(ROOT / '.temp/new_enemy_study/tools'))
    spec = importlib.util.spec_from_file_location('maw_parts', ROOT / '.temp/new_enemy_study/tools/root_maw.py')
    parts = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(parts)
    plant = next(e for e in read_resource(ROOT / '.temp/simple_motion_study/manifest.json')['enemies']
                 if e['slug'] == 'root_maw')
    for state in plant['states']:
        poses = data['sRootMaw' + state['state'].capitalize()]
        for pose, anchor in zip(poses, state['anchors'], strict=True):
            bud = tuple(anchor['bud'])
            upper = parts.jaw_layer(parts.JAW, (1, 5), bud, anchor['opening'] + anchor['pitch'])
            lower = parts.jaw_layer(parts.LOWER, (1, 1), bud, -anchor['opening'] + anchor['pitch'])
            upper.alpha_composite(lower)
            b = upper.getbbox()
            head = [b[0]-14, b[1]-38, b[2]-14, b[3]-38]
            elbow = (round(10+(bud[0]-17)*.5), round(25+(bud[1]-12)*.25))
            regions = [head]
            for a, z in [((14, 31), elbow), (elbow, bud)]:
                regions.append([min(a[0],z[0])-16, min(a[1],z[1])-40,
                                max(a[0],z[0])-11, max(a[1],z[1])-35])
            pose['parts'] = regions
    write_resource(DATA, data)
    return data


def gml(value):
    """Encode the small authoring tables as native GML literals."""
    if isinstance(value, dict):
        return '{' + ','.join(k+':'+gml(v) for k,v in value.items()) + '}'
    if isinstance(value, list):
        return '[' + ','.join(gml(v) for v in value) + ']'
    return json.dumps(value)


def install_pose_script(data):
    """Expose explicit pose offsets; geometry never depends on runtime image pixels."""
    name = 'scriptForestEnemyPoses'
    write_resource(PROJECT/f'scripts/{name}/{name}.yy', {
        '$GMScript':'v1','%Name':name,'name':name,'isCompatibility':False,'isDnD':False,
        'parent':{'name':'Scripts','path':'folders/Scripts.yy'},'resourceType':'GMScript','resourceVersion':'2.0'})
    rows = '\n'.join('        '+k+':'+gml(v)+',' for k,v in data.items())
    (PROJECT/f'scripts/{name}/{name}.gml').write_text(
        '/// Returns author-approved pose anchors and simple attack regions.\n'
        'function funForestEnemyPoseFrames(art) {\n    static poses={\n'+rows+
        '\n    }\n    return variable_struct_get(poses,sprite_get_name(art))\n}\n\n'
        '/// Selects the current authored pose without coupling physics to sprite bounds.\n'
        'function funForestEnemyPose() {\n    var frames=funForestEnemyPoseFrames(self.sprite_index)\n'
        '    return frames[clamp(floor(self.image_index),0,array_length(frames)-1)]\n}\n')
    return ('scripts', name)


def install_masks():
    """Use one fixed rectangle per body and shared simple rectangles for attacks and blasts."""
    entries=[]
    for name,w,h,origin in [
        ('sResinSlimeCollision',14,13,(7,13)),('sBarkBomberCollision',17,17,(8,17)),
        ('sBarkGuardCollision',14,20,(7,20)),('sRootReaperCollision',12,19,(6,19)),
        ('sForestBatCollision',14,12,(7,6)),('sRootMawCollision',50,38,(11,38)),
        ('sForestStrikeCollision',1,1,(0,0)),('sForestBlastCollision',41,41,(20,28))]:
        entries.append(sprite(name,[Image.new('RGBA',(w,h),'white')],origin,1))
    # A sharp ochre thorn reads differently from the round, blinking spore bomb.
    image=Image.new('RGBA',(9,3))
    for x in range(7): image.putpixel((x,1),(119,80,45,255))
    for x,y in [(5,0),(6,0),(7,1),(5,2),(6,2)]:image.putpixel((x,y),(221,170,82,255))
    image.putpixel((8,1),(246,216,143,255))
    entries.append(sprite('sBarkGuardThorn',[image],(4,1),1))
    thorn=PROJECT/'sprites/sBarkGuardThorn/sBarkGuardThorn.yy'
    meta=read_resource(thorn)
    meta.update(bboxMode=2,bbox_left=3,bbox_top=0,bbox_right=5,bbox_bottom=2)
    write_resource(thorn,meta)
    # Existing shell keeps its pixels but uses the cheap rectangular five-pixel core.
    p=PROJECT/'sprites/sForestSeed/sForestSeed.yy';m=read_resource(p)
    m.update(collisionKind=1,bboxMode=2,bbox_left=1,bbox_top=1,bbox_right=5,bbox_bottom=5)
    write_resource(p,m)
    return entries


def archive_pixel_masks():
    """Remove only obsolete generated colliders, keeping an exact research backup."""
    project_path=PROJECT/'RandomForest.yyp'
    project=read_resource(project_path)
    obsolete={r['id']['name'] for r in project['resources'] if r['id']['path'].startswith('sprites/')
              and (r['id']['name'].startswith(PREFIXES+('sSkeleton',)) and
                   ('Body' in r['id']['name'] or r['id']['name'].endswith('Strike'))
                   or r['id']['name']=='sForestSeedBlastBody')}
    for path,section,key in [(project_path,'resources',lambda e:e['id']['name']),
                             (PROJECT/'RandomForest.resource_order','ResourceOrderSettings',lambda e:e['name'])]:
        lines=path.read_text().splitlines(keepends=True)
        # Resource rows are one-line entries; preserve unrelated project formatting.
        lines=[line for line in lines if not any(re.search(r'"(?:name|%Name)"\s*:\s*"'+re.escape(n)+r'"',line) for n in obsolete)]
        path.write_text(''.join(lines))
    archive=ROOT/'.temp/enemy_revision/obsolete-colliders';archive.mkdir(parents=True,exist_ok=True)
    for name in obsolete:
        folder=PROJECT/'sprites'/name
        if folder.exists():
            if not (archive/name).exists():shutil.move(str(folder),archive/name)
            else:shutil.rmtree(folder)
    return len(obsolete)


def organize_folders():
    """Group native animations in the editor without renaming resource IDs or image paths."""
    project_path=PROJECT/'RandomForest.yyp';project=read_resource(project_path)
    folders={f['folderPath'] for f in project['Folders']}
    mapping=dict(zip(PREFIXES,('ResinSlime','BarkBomber','BarkGuard','RootReaper','ForestBat','RootMaw')))
    mapping['sForest']='ForestProjectiles'
    additions=[]
    for folder in set(mapping.values()):
        path=f'folders/Sprites/{folder}.yy'
        if path not in folders:
            additions.append({'$GMFolder':'','%Name':folder,'folderPath':path,'name':folder,
                              'resourceType':'GMFolder','resourceVersion':'2.0'})
    append_entries(project_path,'Folders',additions)
    for path in (PROJECT/'sprites').glob('*/*.yy'):
        match=next((folder for prefix,folder in mapping.items() if path.stem.startswith(prefix)),None)
        if match:
            meta=read_resource(path);meta['parent']={'name':match,'path':f'folders/Sprites/{match}.yy'}
            write_resource(path,meta)


def main():
    """Replace expensive mask resources and retain small reproducible authoring tables."""
    data=source_pose_data()
    entries=[install_pose_script(data)]+install_masks()
    removed=archive_pixel_masks()
    register_resources(entries)
    organize_folders()
    print(f'Installed {len(entries)} pose/collider resources; archived {removed} pixel-mask sprites.')


if __name__=='__main__':main()
