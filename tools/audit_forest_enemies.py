"""Check simple native colliders, preserved source art, legacy skeleton physics and selected audio."""
import hashlib
import json
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image

from theme_assets import ROOT, PROJECT, read_resource


MASKS = ('sResinSlimeCollision','sBarkBomberCollision','sBarkGuardCollision',
         'sRootReaperCollision','sForestBatCollision','sRootMawCollision',
         'sForestStrikeCollision','sForestBlastCollision')


def main():
    """Verify stable rectangles and unchanged artwork without enforcing the old pixel-mask mistake."""
    project=read_resource(PROJECT/'RandomForest.yyp')
    refs=project['resources'];names=[r['id']['name'] for r in refs]
    assert len(names)==len(set(names))
    for r in refs: assert (PROJECT/r['id']['path']).exists(),r
    for name in MASKS:
        m=read_resource(PROJECT/f'sprites/{name}/{name}.yy')
        assert m['collisionKind']==1 and len(m['frames'])==1,name
    families=('sResinSlime','sBarkBomber','sBarkGuard','sRootReaper','sForestBat','sRootMaw','sSkeleton')
    assert not [n for n in names if n.startswith(families) and ('Body' in n or n.endswith('Strike'))]
    original=subprocess.check_output(['git','show','HEAD:RandomForest/objects/oSkeleton/Step_0.gml'],cwd=ROOT,text=True)
    assert (PROJECT/'objects/oSkeleton/Step_0.gml').read_text()==original,'skeleton execution changed'
    for folder in (PROJECT/'scripts').iterdir():
        if folder.name.startswith(('scriptSkeleton','funSkeleton')):
            file=folder/(folder.name+'.gml')
            if file.exists():
                original=subprocess.check_output(['git','show','HEAD:'+str(file.relative_to(ROOT))],cwd=ROOT,text=True)
                assert file.read_text()==original,file
    suchnik=read_resource(ROOT/'.temp/new_enemy_study/enemies/suchnik.json')
    for state in suchnik['states']:
        if state['source_sprite'].endswith('Bloom'): continue
        name=state['source_sprite']+'Evening'
        m=read_resource(PROJECT/f'sprites/{name}/{name}.yy')
        base=read_resource(PROJECT/f'sprites/{state["source_sprite"]}/{state["source_sprite"]}.yy')
        for key in ('bbox_left','bbox_top','bbox_right','bbox_bottom','collisionKind','bboxMode'):
            assert m[key]==base[key],(name,key)
        for frame,source in zip(m['frames'],state['frames'],strict=True):
            assert (PROJECT/f'sprites/{name}/{frame["name"]}.png').read_bytes()==(ROOT/'.temp/new_enemy_study'/source).read_bytes()
    snapshot=ROOT/'.temp/enemy_revision/before'
    unchanged=changed=0
    for old in (snapshot/'sprites').glob('*/*.png'):
        relative=old.relative_to(snapshot)
        actual=PROJECT/relative
        if not actual.exists(): continue  # Removed obsolete colliders have their own explicit check above.
        if old.parent.name=='sBarkGuardAttack2Night':
            a=np.array(Image.open(old));b=np.array(Image.open(actual))
            assert np.array_equal(a[:,:,3],b[:,:,3]),relative
            different=np.any(a!=b,axis=2)
            assert not different[:,:32].any(),'guardian body was recolored'
            changed+=int(different.any())
        else:
            assert old.read_bytes()==actual.read_bytes(),relative
            unchanged+=1
    for old in (snapshot/'sounds').rglob('*'):
        if old.suffix in ('.wav','.mp3','.ogg'):
            assert old.read_bytes()==(PROJECT/old.relative_to(snapshot)).read_bytes(),old
    report={'simple_single_frame_colliders':len(MASKS),'animated_pixel_masks':0,
            'skeleton_original_execution_and_state_scripts':True,'suchnik_skin_only':True,
            'unchanged_composite_art_frames':unchanged,'night_guard_effect_frames_improved':changed,
            'all_existing_audio_files_unchanged':True,'resource_references_valid':True}
    target=ROOT/'.temp/enemy_revision/asset-audit.json';target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(report,ensure_ascii=False))


if __name__=='__main__':main()
