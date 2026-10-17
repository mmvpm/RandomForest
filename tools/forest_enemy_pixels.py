"""Retarget imagegen material modules into unchanged donor alpha and motion."""
from pathlib import Path
import numpy as np
from PIL import Image
import cv2

RAMPS={
 'slime':[(42,35,54),(89,53,73),(141,81,101),(184,114,124),(211,154,137)],
 'barrel':[(26,24,39),(50,43,65),(77,64,90),(112,94,123),(141,125,143)],
 'bat':[(24,22,39),(44,35,64),(74,52,87),(111,86,122),(148,122,155)],
 'guard':[(40,28,25),(74,48,37),(119,72,47),(158,108,70),(189,155,116)],
 'sweeper':[(22,21,34),(43,37,57),(67,55,81),(101,86,113),(143,127,144)]}

# Coherent clay and wood planes from the clean reference; never alternate colors by pixel position.
GUARD_PALETTES={
 'day':[(45,26,31),(67,42,43),(122,69,52),(174,114,76),(202,155,98),(241,180,67),(219,189,141)],
 'evening':[(24,24,36),(46,42,54),(81,69,73),(126,103,100),(160,137,118),(187,140,77),(173,153,140)],
 'night':[(15,15,24),(32,28,43),(52,43,65),(86,68,88),(125,104,120),(193,132,76),(153,132,151)],
 'morning':[(43,31,25),(77,51,38),(133,94,59),(182,138,91),(211,180,127),(235,169,64),(223,198,160)]}


def highlight_guard_burst(image, mask, index):
    """Give only the detached night ground volley warm, readable planes against the forest."""
    if index < 3:
        return image
    a=np.array(image);body=np.array(mask)[:,:,3]>0
    yy,xx=np.indices(body.shape)
    cells=(a[:,:,3]>0)&~body&(xx>=32)
    brightness=a[:,:,:3].mean(axis=2)
    for low,high,color in [(0,45,(76,47,48)),(45,85,(159,91,64)),
                           (85,125,(215,150,86)),(125,256,(244,207,144))]:
        a[cells&(brightness>=low)&(brightness<high),:3]=color
    return Image.fromarray(a)


def clean_guard(source,theme):
    """Retain the source's large authored color clusters and replace metal tones with clay and wood."""
    a=np.array(source);out=a.copy();palette=GUARD_PALETTES[theme]
    colors={(32,32,32):0,(64,37,27):1,(86,50,38):2,(118,77,63):3,(146,123,108):4,
            (246,219,114):5,(237,217,196):6,(255,255,255):6,(219,200,193):6,
            (109,72,59):3,(145,122,107):4}
    for rgb,index in colors.items():out[np.all(a[:,:,:3]==rgb,axis=2)&(a[:,:,3]>0),:3]=palette[index]
    out[a[:,:,3]==0]=0
    return Image.fromarray(out)


def barrel_caster_opacity(image,index):
    """Keep the held bomb before release, then the connected caster rather than a rectangular crop."""
    a=np.array(image);opaque=a[:,:,3]>0
    if index<2:return opaque
    colored=opaque&~np.all(a[:,:,:3]==255,axis=2)
    _,labels,_,_=cv2.connectedComponentsWithStats(colored.astype('uint8'),8)
    core=labels[34:51,78:95];ids,counts=np.unique(core[core>0],return_counts=True)
    return labels==ids[np.argmax(counts)] if len(ids) else np.zeros_like(opaque)


def barrel_cast(image,art,index):
    """Separate caster pixels without changing the canvas or trimming any splash silhouette."""
    a=np.array(art);a[~barrel_caster_opacity(image,index)]=0
    return Image.fromarray(a)


def body_mask(image,kind,state,index):
    """Separate the opaque body from weapon shafts, detached bombs and white attack effects."""
    a=np.array(image);opaque=a[:,:,3]>=128;rgb=a[:,:,:3];yy,xx=np.indices(opaque.shape)
    if kind=='slime':
        keep=opaque & ~((rgb[:,:,0]==107)&(rgb[:,:,1]==182)) & ~((rgb[:,:,0]==88)&(rgb[:,:,1]==125))
        keep &= ~np.all(rgb==[242,247,246],axis=2)
    elif kind=='barrel':
        keep=opaque&(xx>=78)&(xx<=94)&(yy>=34)&(yy<=50)
        if state=='attack':keep &= barrel_caster_opacity(image,index)
    elif kind=='bat':keep=opaque&~np.all(rgb==255,axis=2)
    elif kind=='guard':keep=opaque&(xx>=14)&(xx<=31)&(yy<=23)&~np.all(rgb==[32,32,32],axis=2)
    else:
        keep=opaque&(rgb[:,:,0]<100)
        # The light staff and its dark shaft are not a hurtbox; track the hood's moving cluster.
        core=opaque&(rgb[:,:,0]==11)
        if core.any():
            pts=np.argwhere(core);center=np.median(pts[:,1]);keep &= xx>=center-7
    if kind in ('slime','bat') and keep.any():
        n,labels,stats,_=cv2.connectedComponentsWithStats(keep.astype('uint8'),8)
        if n>1:keep=labels==(1+np.argmax(stats[1:,cv2.CC_STAT_AREA]))
        # Facial holes remain physical body pixels, while detached flashes stay outside.
        filled=cv2.morphologyEx(keep.astype('uint8'),cv2.MORPH_CLOSE,np.ones((2,2),'uint8'))>0
        keep |= filled&opaque
    out=np.zeros_like(a);out[keep]=[255,255,255,255]
    return Image.fromarray(out)


def canonical_module(concept,maximum):
    """Recover a small, fixed material module through the same local pixel-grid reconstruction."""
    import sys,io
    vendor=Path(__file__).resolve().parents[1]/'.temp/forest_world_study/setpieces/extracted/vendor/rd-pixel-art-fixer/python'
    sys.path.insert(0,str(vendor))
    from pixelfixer.api import process
    image=Image.open(concept).convert('RGBA');image=image.crop(image.getbbox());buffer=io.BytesIO();image.save(buffer,format='PNG')
    result=process(buffer.getvalue(),force_step=max(image.width/maximum[0],image.height/maximum[1]),k_colors=24)
    native=Image.open(io.BytesIO(result['png'])).convert('RGBA');return native.crop(native.getbbox())


def themed_color(rgb,theme,kind):
    """Choose distinct material schemes under forest light, rather than applying a green day tint."""
    c=np.array(rgb,dtype=float)
    if kind=='slime':
        if theme=='night':c=c*np.array([.68,.76,1.03])+[0,2,9]
        elif theme=='morning':c=c*np.array([1.10,.95,.61])+[7,8,3]
        else:c=c*.80+[0,1,5]
    elif kind=='guard':
        if theme=='evening':c=c*np.array([.64,.77,.90])+[7,4,14]
        elif theme=='night':c=c*np.array([.41,.56,.77])+[9,9,21]
        elif theme=='morning':c=c*np.array([.94,1.04,1.08])+[8,8,3]
        else:c=c*.88
    else:c=c*.88
    return tuple(np.clip(np.rint(c),0,220).astype('uint8'))


def redesign(source,kind,theme,module,mask):
    """Redraw bark, resin, root bindings and fur inside the donor's exact per-frame opacity."""
    if kind=='guard':return clean_guard(source,theme)
    a=np.array(source);out=a.copy();body=np.array(mask)[:,:,3]>0;yy,xx=np.indices(body.shape)
    ys,xs=np.where(body)
    center_x=int(np.median(xs)) if len(xs) else source.width//2
    top=int(ys.min()) if len(ys) else 0;bottom=int(ys.max()) if len(ys) else source.height-1
    ramp=RAMPS[kind];reference=np.array(module)
    for y,x in np.argwhere(a[:,:,3]>0):
        rgb=a[y,x,:3];light=float(rgb@[.2126,.7152,.0722]);rank=min(4,int(light/48))
        color=ramp[rank]
        local_x=x-center_x;local_y=y-top
        if kind=='slime':
            if body[y,x] and light>90:
                # Resin clouds and seed inclusions move with the deforming body, not the screen.
                grain=(local_x*3+local_y*5)%17
                color=ramp[2 if grain<3 else 3 if light>125 else 2]
            elif rgb[1]>rgb[0]*1.35:color=(102,79,68)
            if light>220:color=(209,172,107) if body[y,x] else (155,132,151)
        elif kind=='barrel':
            if light>220:color=(200,152,82)
            elif abs(int(rgb[0])-int(rgb[1]))<20 and light>90:color=(135,113,133) if local_x%4 else (91,78,101)
            elif body[y,x] and light>80:color=ramp[2 if (x-center_x)%4==0 else 3]
        elif kind=='bat':
            if light>220:color=(193,147,85)
            elif body[y,x]:
                # Veined membranes flank a soft fur breast; the single-color donor gains real materials.
                mid=abs(local_x)<4;fur=mid and local_y>max(2,(bottom-top)//3)
                color=ramp[3 if fur and (local_x+local_y)%4 else 2 if mid else 1 if (local_x+2*local_y)%6 else 2]
        elif kind=='sweeper':
            if light>100:color=(153,132,135) if (x+y)%5 else (112,94,117)
            elif body[y,x]:color=ramp[2 if (local_x*2+local_y)%7<2 else 1 if light<20 else 3]
            else:color=ramp[1]
        # A restrained sample of the reviewed module supplies material detail, never new silhouette cells.
        if body[y,x] and kind in ('barrel','sweeper') and (local_x+local_y)%11==0 and light>35:
            u=int((local_x+12)/24*(module.width-1));v=int((y-top)/max(1,bottom-top)*(module.height-1))
            sample=reference[max(0,min(module.height-1,v)),max(0,min(module.width-1,u))]
            if sample[3]>220:color=tuple(sample[:3])
        out[y,x,:3]=themed_color(color,theme,kind)
    out[a[:,:,3]==0]=0
    return Image.fromarray(out)
