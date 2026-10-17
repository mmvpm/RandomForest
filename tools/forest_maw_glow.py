"""Bake frame-matched Root Maw halos; never alter the approved body or collision artwork."""
from PIL import Image, ImageChops, ImageFilter

from forest_enemy_assets import sprite
from theme_assets import sprite_frames, sprite_resource, register_resources

PADDING = 24
STATES = ('Idle', 'Prepare', 'Attack', 'Recover', 'Hurt')


def glow_frame(body, rosette):
    """Spread the existing night halo colour softly around the complete living silhouette."""
    alpha = Image.new('L', (body.width + PADDING * 2, body.height + PADDING * 2))
    alpha.paste(body.getchannel('A'), (PADDING, PADDING))
    # Leaves have their own clock and are unflipped; their small union covers either facing.
    alpha.paste(rosette, (PADDING + 14 - 9, PADDING + 38 - 11), rosette)
    alpha = alpha.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(6))
    colour = sprite_frames('sSlimeBloomNight')[0].getpixel((35, 35))
    image = Image.new('RGBA', alpha.size, colour[:3] + (0,))
    image.putalpha(alpha.point(lambda a: round(a * colour[3] / 255)))
    return image


def main():
    """Keep each aura's frame clock and origin identical to its owner, including mirrored attacks."""
    leaves = sprite_frames('sRootMawRosette')
    rosette = Image.new('L', leaves[0].size)
    for frame in leaves:
        rosette = ImageChops.lighter(rosette, frame.getchannel('A'))
    rosette = ImageChops.lighter(rosette, rosette.transpose(Image.Transpose.FLIP_LEFT_RIGHT))
    entries = []
    for state in STATES:
        name = 'sRootMaw' + state
        meta = sprite_resource(name)
        frames = [glow_frame(frame, rosette) for frame in sprite_frames(name + 'Bare')]
        entries.append(sprite(name + 'Bloom', frames,
                              (meta['sequence']['xorigin'] + PADDING,
                               meta['sequence']['yorigin'] + PADDING),
                              meta['sequence']['playbackSpeed']))
    register_resources(entries)
    print('Baked five living Root Maw halo animations with matching frame clocks.')


if __name__ == '__main__':
    main()
