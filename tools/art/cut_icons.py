#!/usr/bin/env python3
"""Cuts 0.3.0 weapon icons and the cash pickup out of their flat grey backgrounds.

Usage: cut_icons.py RAW_DIR OUT_DIR [--max 512] [names...]
Background colour is estimated from the image border; every near-background
region connected to the border becomes transparent, with a soft 2 px edge and
background colour removed from semi-transparent edge pixels.
"""
import sys, os, argparse
import numpy as np
from PIL import Image
from scipy import ndimage

def cut(path, max_side=512, t0=14.0, t1=40.0, pad=6, crop=True):
    im = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    h, w, _ = im.shape
    border = np.concatenate([im[:4].reshape(-1, 3), im[-4:].reshape(-1, 3), im[:, :4].reshape(-1, 3), im[:, -4:].reshape(-1, 3)])
    bg = np.median(border, axis=0)
    dist = np.sqrt(((im - bg) ** 2).sum(-1))
    cand = dist < t1
    # Flood from the border through a strict, opened mask so thin gaps in the
    # ink outline cannot leak the fill into grey metal parts.
    core = ndimage.binary_opening(dist < 24.0, iterations=2)
    lab, n = ndimage.label(core)
    edge_labels = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bgmask = ndimage.binary_dilation(np.isin(lab, list(edge_labels)), iterations=3) & cand
    # Enclosed holes (trigger guards, stock cut-outs): flat regions that are
    # almost exactly the background grey are background too.
    holes = dist < 16.0
    hl, hn = ndimage.label(holes & ~bgmask)
    for i in range(1, hn + 1):
        reg = hl == i
        if reg.sum() < 80 or dist[reg].mean() >= 9.0 or dist[reg].std() >= 5.0: continue
        ring = ndimage.binary_dilation(reg, iterations=4) & ~ndimage.binary_dilation(reg, iterations=1)
        lum = im[ring].mean(-1)
        if (lum < 85).mean() > 0.6:   # a real hole is ringed by the dark ink outline
            grown = ndimage.binary_dilation(reg, iterations=2) & cand
            bgmask |= grown
    # Soft alpha only inside the background-connected region near the subject.
    alpha = np.ones((h, w), np.float32)
    soft = np.clip((dist - t0) / (t1 - t0), 0.0, 1.0)
    alpha[bgmask] = soft[bgmask]
    near = ndimage.binary_dilation(~bgmask, iterations=3)
    alpha[bgmask & ~near] = 0.0
    # Small specks of noise in the background: drop components under 60 px.
    solid = alpha > 0.5
    lab2, n2 = ndimage.label(solid)
    if n2:
        sizes = ndimage.sum(solid, lab2, range(1, n2 + 1))
        for i, s in enumerate(sizes, 1):
            if s < 60: alpha[lab2 == i] = 0.0
    a = alpha[..., None]
    rgb = np.where(a > 0.01, (im - (1 - a) * bg) / np.maximum(a, 0.01), 0)
    rgb = np.clip(rgb, 0, 255)
    out = np.concatenate([rgb, alpha[..., None] * 255], -1).astype(np.uint8)
    if crop:
        ys, xs = np.where(alpha > 0.05)
        y0, y1 = max(0, ys.min() - pad), min(h, ys.max() + pad + 1)
        x0, x1 = max(0, xs.min() - pad), min(w, xs.max() + pad + 1)
    else:   # keep the full canvas (first-person views keep fixed coordinates)
        y0, y1, x0, x1 = 0, h, 0, w
    img = Image.fromarray(out[y0:y1, x0:x1], "RGBA")
    k = min(1.0, max_side / max(img.size))
    if k < 1.0:
        img = img.resize((round(img.size[0] * k), round(img.size[1] * k)), Image.LANCZOS)
    return img, bg

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("raw"); ap.add_argument("out"); ap.add_argument("--max", type=int, default=512)
    ap.add_argument("names", nargs="*")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    names = a.names or sorted(os.path.splitext(f)[0] for f in os.listdir(a.raw))
    for n in names:
        src = next(os.path.join(a.raw, n + e) for e in (".jpg", ".png") if os.path.exists(os.path.join(a.raw, n + e)))
        img, bg = cut(src, a.max)
        img.save(os.path.join(a.out, n + ".png"), optimize=True)
        print(n, img.size, "bg", bg.round(1).tolist())
