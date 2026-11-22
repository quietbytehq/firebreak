#!/usr/bin/env python3
"""Cuts the 0.3.1 first-person weapon views out of their flat grey backgrounds.

Usage: cut_fp.py RAW_DIR OUT_DIR [--size 640] [names...]
Same background removal as cut_icons.py, but the square canvas is kept (not
cropped) so the muzzle points in data/fp_weapons.json stay valid, and the
bottom 7% of the picture fades out where the arms leave the frame (the HUD
weapon bar sits over that part of the screen).
"""
import os, sys, argparse
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cut_icons import cut

def fp(path, size=640, fade=0.07):
    img, bg = cut(path, max_side=size, crop=False)
    if img.size != (size, size):
        img = img.resize((size, size), Image.LANCZOS)
    a = np.asarray(img).astype(np.float32)
    h = a.shape[0]; n = max(1, int(h * fade))
    ramp = np.linspace(1.0, 0.0, n, dtype=np.float32)
    a[h - n:, :, 3] *= ramp[:, None]
    return Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA"), bg

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("raw"); ap.add_argument("out"); ap.add_argument("--size", type=int, default=640)
    ap.add_argument("names", nargs="*")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    names = a.names or sorted(os.path.splitext(f)[0] for f in os.listdir(a.raw))
    for n in names:
        src = next(os.path.join(a.raw, n + e) for e in (".jpg", ".png") if os.path.exists(os.path.join(a.raw, n + e)))
        img, bg = fp(src, a.size)
        img.save(os.path.join(a.out, n + ".png"), optimize=True)
        print(n, img.size, "bg", bg.round(1).tolist())
