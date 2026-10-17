"""Register small behaviour modules, enemy subclasses and independent attack objects."""
import copy
from theme_assets import PROJECT,read_resource,write_resource,register_resources
from forest_enemy_assets import sprite,WORK
from forest_enemy_pixels import barrel_cast
from PIL import Image
import numpy as np


def event(kind,number=0):
    """Return native event metadata for one GameMaker object event."""
    return {'$GMEvent':'v1','%Name':'','collisionObjectId':None,'eventNum':number,'eventType':kind,'isDnD':False,'name':'','resourceType':'GMEvent','resourceVersion':'2.0'}


def object_resource(name,parent,events,art=None):
    """Register one child without inheriting unrelated existing combat events."""
    meta=copy.deepcopy(read_resource(PROJECT/'objects/oEnemy/oEnemy.yy'));meta.update(name=name,**{'%Name':name},visible=True,parentObjectId={'name':parent,'path':f'objects/{parent}/{parent}.yy'},eventList=[event(kind,number) for kind,number in events])
    if art:meta['spriteId']={'name':art,'path':f'sprites/{art}/{art}.yy'}
    write_resource(PROJECT/f'objects/{name}/{name}.yy',meta);return ('objects',name)


def write_event(name,file,body):
    """Keep event adapters short; behaviour is owned by separately named script modules."""
    (PROJECT/f'objects/{name}/{file}.gml').write_text('/// Executes the forest enemy event.\n'+body+'\n')


def attack_sprites():
    """Derive visible attack silhouettes separately from each enemy's vulnerable body."""
    entries=[]
    # Keep the complete native bomber splash; eight frames still take sixteen game steps.
    folder=WORK/'frames/barrel/night/attack';source=WORK/'sources/barrel/attack';burst=[]
    for i in range(9,17):
        image=Image.open(folder/f'{i:03d}.png').convert('RGBA')
        caster=barrel_cast(Image.open(source/f'frame-{i+1:03d}.png').convert('RGBA'),image,i)
        a=np.array(image);a[np.array(caster)[:,:,3]>0]=0;burst.append(Image.fromarray(a))
    entries.append(sprite('sForestSeedBurst',burst,[132,51],30))
    return entries


def main():
    """Connect six behaviours and their native assets to the actual project."""
    entries=[]
    for name in ['scriptForestEnemyCore','scriptForestEnemyCombat','scriptForestEnemyGround','scriptForestEnemyFlying','scriptForestEnemyAttacks','scriptForestEnemyGlow','scriptForestEnemyAudio','scriptForestEnemyMotion','scriptForestEnemySlime','scriptForestEnemyMaw']:
        write_resource(PROJECT/f'scripts/{name}/{name}.yy',{'$GMScript':'v1','%Name':name,'name':name,'isCompatibility':False,'isDnD':False,'parent':{'name':'Scripts','path':'folders/Scripts.yy'},'resourceType':'GMScript','resourceVersion':'2.0'});entries.append(('scripts',name))
    entries.append(object_resource('oForestEnemy','oEnemy',[(3,0),(8,0),(7,7),(12,0)]))
    write_event('oForestEnemy','Step_0','funForestEnemyStep()')
    write_event('oForestEnemy','Draw_0','funForestEnemyDraw()')
    write_event('oForestEnemy','Other_7','funForestEnemyAnimationEnd()')
    write_event('oForestEnemy','CleanUp_0','funForestEnemyCancelAttacks()\nfunForestEnemyRemoveGlow()')
    glow=copy.deepcopy(read_resource(PROJECT/'objects/oBungaloBloom/oBungaloBloom.yy'))
    glow.update(name='oForestEnemyBloom',**{'%Name':'oForestEnemyBloom'},eventList=[event(0,0),event(3,2),event(8,0)])
    write_resource(PROJECT/'objects/oForestEnemyBloom/oForestEnemyBloom.yy',glow);entries.append(('objects','oForestEnemyBloom'))
    write_event('oForestEnemyBloom','Create_0','self.following=noone')
    write_event('oForestEnemyBloom','Step_2','funForestEnemyGlowStep()')
    write_event('oForestEnemyBloom','Draw_0','funForestEnemyGlowDraw()')
    for kind,name,art in [('slime','oResinSlime','sResinSlimeIdle'),('barrel','oBarkBomber','sBarkBomberIdle'),('bat','oForestBat','sForestBatFly'),('guard','oBarkGuard','sBarkGuardIdle'),('sweeper','oRootReaper','sRootReaperIdle'),('maw','oRootMaw','sRootMawIdle')]:
        entries.append(object_resource(name,'oForestEnemy',[(0,0)],art));write_event(name,'Create_0',f'funForestEnemyInitialize("{kind}")')
    entries.append(object_resource('oForestStrike','oEnemy',[(0,0),(3,0)]));p=PROJECT/'objects/oForestStrike/oForestStrike.yy';meta=read_resource(p);meta['visible']=False;write_resource(p,meta)
    write_event('oForestStrike','Create_0','self.damage=1\nself.can_damage_player=false\nself.is_dead=false\nself.counts_as_enemy=false\nself.image_speed=0')
    write_event('oForestStrike','Step_0','funForestStrikeStep()')
    entries.append(object_resource('oForestProjectile','oEnemy',[(0,0),(3,0)],'sForestSeed'))
    write_event('oForestProjectile','Create_0','self.damage=1\nself.can_damage_player=true\nself.is_dead=false\nself.counts_as_enemy=false\nself.sprite_index=sForestSeed\nself.mask_index=sForestSeed\nself.life=150\nself.fuse=0\nself.blasting=false\nself.stomp_knockback_direction=0\nself.ground_impact=false\nself.impact_y=self.y')
    write_event('oForestProjectile','Step_0','funForestProjectileStep()')
    entries+=attack_sprites();register_resources(entries);from forest_enemy_collision_assets import main as collision_assets;collision_assets();print(f'Registered {len(entries)} behaviour/attack resources')


if __name__=='__main__':main()
