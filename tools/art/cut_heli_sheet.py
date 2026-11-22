"""Cuts the helicopter / jet / bomb / explosion sheet (flat grey background) into
transparent PNGs. Usage: python3 cut_heli_sheet.py <sheet.jpg> <out_dir>
Also writes heli_idle.png (heli_gunner without the painted muzzle flash)."""
import sys, os
from PIL import Image, ImageFilter
import numpy as np
from scipy import ndimage
src = Image.open(sys.argv[1]).convert('RGB')
A = np.asarray(src).astype(np.float32)
# Estimate the background as a smooth field from pixels close to the grey.
grey = np.array([213, 212, 210], np.float32)
d0 = np.sqrt(((A - grey) ** 2).sum(2))
print('corner samples', A[5,5], A[5,1270], A[715,5], A[715,1270], A[360,5])
bgmask = d0 < 14
# smooth background estimate: average of bg pixels in big neighbourhood
w = ndimage.uniform_filter(bgmask.astype(np.float32), 61)
bgf = np.stack([ndimage.uniform_filter(A[:,:,c]*bgmask, 61) for c in range(3)], 2) / np.maximum(w[...,None], 1e-3)
bgf[w < 0.02] = grey
d = np.sqrt(((A - bgf) ** 2).sum(2))
# saturation helps keep greyish smoke: smoke is darker than bg
lum = A.mean(2); bl = bgf.mean(2)
dark = np.clip((bl - lum) / 40.0, 0, 1)
alpha = np.clip((d - 8.0) / 22.0, 0, 1)
alpha = np.maximum(alpha, dark)
crops = {
 'heli_gunner': (15, 0, 670, 265),
 'heli_damaged': (690, 0, 1280, 272),
 'heli_crash': (40, 225, 490, 535),
 'jet_a': (495, 278, 965, 392),
 'jet_b': (585, 388, 1050, 482),
 'bomb': (425, 540, 605, 665),
 'explosion_big': (840, 395, 1270, 715),
}
import os
OUT = sys.argv[2]; os.makedirs(OUT, exist_ok=True)
for name, (x0, y0, x1, y1) in crops.items():
    a = alpha[y0:y1, x0:x1].copy()
    # keep only components that are reasonably large
    m = a > 0.2
    dil = ndimage.binary_dilation(m, iterations=7)
    lab, n = ndimage.label(dil)
    sizes = ndimage.sum(m, lab, range(1, n + 1))
    big = int(np.argmax(sizes)) + 1
    keep = np.zeros(n + 1, bool); keep[big] = True
    if name == 'explosion_big':
        H, W = a.shape
        for i in range(1, n + 1):
            ys, xs = np.nonzero(lab == i)
            touches = ys.min() == 0 or xs.min() == 0 or ys.max() == H - 1 or xs.max() == W - 1
            if not touches: keep[i] = True
    a = a * keep[lab]
    # feather any edge the crop cut through
    H, W = a.shape
    yy, xx = np.mgrid[0:H, 0:W]
    edge = np.minimum(np.minimum(yy, H - 1 - yy), np.minimum(xx, W - 1 - xx)).astype(np.float32)
    a = a * np.clip(edge / 18.0, 0, 1)
    rgb = A[y0:y1, x0:x1]
    # de-fringe: unmix background from semi-transparent pixels
    b = bgf[y0:y1, x0:x1]
    aa = np.maximum(a, 1e-3)[..., None]
    fg = np.clip((rgb - b * (1 - aa)) / aa, 0, 255)
    fg = np.where(a[..., None] > 0.95, rgb, fg)
    out = np.dstack([fg, a * 255]).astype(np.uint8)
    im = Image.fromarray(out, 'RGBA')
    bbox = im.getbbox(); im = im.crop(bbox)
    im.save(os.path.join(OUT, name + '.png')); print(name, im.size, bbox)

A2 = np.asarray(Image.open(os.path.join(OUT, 'heli_gunner.png'))).copy()
A2[140:212, 556:, 3] = 0
Image.fromarray(A2).save(os.path.join(OUT, 'heli_idle.png'))
