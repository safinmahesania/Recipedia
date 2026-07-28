"""Generates the Recipedia launcher icon and splash art.

Drawn programmatically rather than exported from a design tool so the whole set
regenerates from one source of truth. Run it, commit the output.

The mark: a white bowl on the brand coral, with three ingredients dropping in.
Chosen because it survives 48px — the bowl is one solid silhouette and the
ingredients read as three dots at that size, which is exactly what the app
does: things you have, going into a dish.
"""
from PIL import Image, ImageDraw
import os, math

CORAL      = (255, 79, 90)
CORAL_DEEP = (217, 59, 70)
WHITE      = (255, 255, 255)
CREAM      = (255, 226, 228)

S = 1024  # master size


def rounded_mask(size, radius):
    m = Image.new('L', (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size - 1, size - 1],
                                        radius=radius, fill=255)
    return m


def gradient(size, top, bottom):
    g = Image.new('RGB', (size, size))
    d = ImageDraw.Draw(g)
    for y in range(size):
        f = y / (size - 1)
        d.line([(0, y), (size, y)],
               fill=tuple(round(top[i] + (bottom[i] - top[i]) * f) for i in range(3)))
    return g


def draw_mark(img, scale=1.0, offset=(0, 0)):
    """Bowl + three ingredients, centred. scale is relative to a 1024 canvas."""
    d = ImageDraw.Draw(img)
    cx = img.size[0] / 2 + offset[0]
    cy = img.size[1] / 2 + offset[1]
    u = S * scale / 1024  # one design unit

    # --- bowl: a half-disc with a flat rim above it ---
    bowl_w = 470 * u
    bowl_h = 250 * u
    bowl_top = cy + 20 * u
    d.pieslice(
        [cx - bowl_w / 2, bowl_top - bowl_h, cx + bowl_w / 2, bowl_top + bowl_h],
        start=0, end=180, fill=WHITE)

    # rim, slightly wider, sitting on the bowl's mouth
    rim_w = 530 * u
    rim_h = 54 * u
    d.rounded_rectangle(
        [cx - rim_w / 2, bowl_top - rim_h / 2, cx + rim_w / 2, bowl_top + rim_h / 2],
        radius=rim_h / 2, fill=WHITE)

    # --- three ingredients dropping in, largest in the middle ---
    for dx, dy, r, col in [
        (-150 * u, -150 * u, 46 * u, CREAM),
        (10 * u,  -232 * u, 62 * u, WHITE),
        (162 * u, -132 * u, 40 * u, CREAM),
    ]:
        d.ellipse([cx + dx - r, cy + dy - r, cx + dx + r, cy + dy + r], fill=col)

    # a sprig on the largest one, so it reads as food rather than bubbles
    sx, sy = cx + 10 * u, cy - 232 * u - 62 * u
    d.line([(sx, sy + 10 * u), (sx, sy - 34 * u)], fill=WHITE, width=int(11 * u))
    d.ellipse([sx - 34 * u, sy - 44 * u, sx + 2 * u, sy - 8 * u], fill=WHITE)


def legacy_icon(size):
    base = gradient(S, CORAL, CORAL_DEEP)
    draw_mark(base)
    base.putalpha(rounded_mask(S, int(S * 0.22)))
    return base.resize((size, size), Image.LANCZOS)


def adaptive_foreground(size):
    """Transparent, mark inside the 66% safe zone Android may crop to."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    draw_mark(img, scale=0.62)
    return img.resize((size, size), Image.LANCZOS)


def store_icon(size=512):
    base = gradient(S, CORAL, CORAL_DEEP)
    draw_mark(base)
    return base.convert('RGB').resize((size, size), Image.LANCZOS)


def splash_mark(size=512):
    """White mark on transparent, for the launch screen over a coral window."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    draw_mark(img, scale=0.78)
    return img.resize((size, size), Image.LANCZOS)


DENSITIES = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
FOREGROUND = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}
SPLASH = {'mdpi': 128, 'hdpi': 192, 'xhdpi': 256, 'xxhdpi': 384, 'xxxhdpi': 512}

out = 'android/app/src/main/res'
for d, px in DENSITIES.items():
    os.makedirs(f'{out}/mipmap-{d}', exist_ok=True)
    legacy_icon(px).save(f'{out}/mipmap-{d}/ic_launcher.png')
    adaptive_foreground(FOREGROUND[d]).save(f'{out}/mipmap-{d}/ic_launcher_foreground.png')
    os.makedirs(f'{out}/drawable-{d}', exist_ok=True)
    splash_mark(SPLASH[d]).save(f'{out}/drawable-{d}/splash_logo.png')

os.makedirs('store', exist_ok=True)
store_icon().save('store/play-store-icon-512.png')
legacy_icon(1024).save('store/icon-master-1024.png')

print('legacy + adaptive + splash written for', len(DENSITIES), 'densities')
