"""Regenerates scripts/sprite_meta.gd from the PNGs in assets/sprites/.
Run from the project root: python3 tools/art/sprite_meta.py
Feet-anchored sprites use (w/2, h-8); pickups, FX, open chutes and the mid-air
death pose are centre-anchored (see ART_PROMPTS.md)."""
import os
import numpy as np
from PIL import Image

CENTRE = ("food_", "power_", "fx_", "parachute_open", "paratrooper_death")

# 0.3.0: outlined sprites keep the anchor and opaque box of the original figure
# (tools/art/bake_outlines.py records them), so the outline never changes scale.
_OUTLINED = {}
if os.path.exists("assets/sprites/outline_v030.json"):
    import json
    _OUTLINED = {k: v["meta"] for k, v in json.load(open("assets/sprites/outline_v030.json")).items()}

def rows(folder, all_centre=False):
    out = []
    for f in sorted(os.listdir(folder)):
        if not f.endswith(".png"):
            continue
        n = f[:-4]
        if n in _OUTLINED:
            out.append(f'\t"{n}": [{", ".join(map(str, _OUTLINED[n]))}],')
            continue
        im = Image.open(os.path.join(folder, f))
        w, h = im.size
        a = np.asarray(im.convert("RGBA"))[:, :, 3]
        ys, xs = np.nonzero(a > 40)
        if all_centre or n.startswith(CENTRE):
            ax, ay = w // 2, h // 2
        else:
            ax, ay = w // 2, h - 8
        out.append(f'\t"{n}": [{w}, {h}, {ax}, {ay}, {xs.min()}, {ys.min()}, {xs.max() + 1}, {ys.max() + 1}],')
    return out

lines = ["extends RefCounted",
         "## Generated from the sprite masters (tools/art/sprite_meta.py): canvas size,",
         "## anchor (feet or centre) and the tight box of opaque pixels for every sprite.",
         "## [w, h, anchor_x, anchor_y, used_x0, used_y0, used_x1, used_y1]", "", "const UNITS := {"]
lines += rows("assets/sprites/units") + ["}", "", "const VEHICLES := {"]
lines += rows("assets/sprites/vehicles", True) + ["}"]
open("scripts/sprite_meta.gd", "w").write("\n".join(lines) + "\n")
