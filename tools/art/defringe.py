"""Removes the light-grey sheet background left around a cut-out (0.2.1).
Pixels close to the background grey lose alpha in proportion and get their
colour un-mixed from it; saturated fire and darker smoke are untouched.
Usage: python3 tools/art/defringe.py <in.png> <out.png>"""
import sys
import numpy as np
from PIL import Image, ImageFilter

src, dst = sys.argv[1], sys.argv[2]
im = np.array(Image.open(src).convert("RGBA")).astype(np.float32)
rgb, a = im[:, :, :3], im[:, :, 3] / 255.0
sat = rgb.max(axis=2) - rgb.min(axis=2)
lum = rgb.mean(axis=2)
# Background grey: median of bright, desaturated, semi-transparent edge pixels.
edge = (a > 0.05) & (a < 0.95) & (sat < 18) & (lum > 160)
bg = np.median(rgb[edge], axis=0) if edge.sum() > 50 else np.array([216.0, 216.0, 216.0])
d = np.linalg.norm(rgb - bg, axis=2)
f = np.clip((d - 18.0) / 75.0, 0.0, 1.0)
f = np.where(sat > 40, 1.0, f)          # fire / sparks stay
na = a * f
fs = np.maximum(f, 0.25)[:, :, None]
nrgb = np.clip((rgb - bg * (1.0 - fs)) / fs, 0, 255)
# Soften the new edge a touch.
al = Image.fromarray((na * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
na = np.minimum(na * 255, np.array(al).astype(np.float32) * 1.15)
out = np.dstack([nrgb, np.clip(na, 0, 255)]).astype(np.uint8)
Image.fromarray(out, "RGBA").save(dst, optimize=True)
print("bg", bg.round(1), "edge px", int(edge.sum()))
