#!/usr/bin/env python3
"""Bakes a dark comic-style outline into the character, villager, helicopter and
pickup sprites (Firebreak 0.3.0) and updates scripts/sprite_meta.gd to match.

Run once from the project root: python3 tools/art/bake_outlines.py ORIG_DIR
ORIG_DIR holds the un-outlined masters (units/ and vehicles/); the outlined
PNGs are written to assets/sprites/. Every canvas grows by P px on each side,
the anchor and opaque box move by P, and the opaque box stays the original
figure so in-game scale (figure height between top and feet) is unchanged.

Outline width in master pixels = 3.5 px / on-screen scale at the near band,
clamped to 2..8, so it reads as about 3-4 px on the nearest figures and shrinks
with depth (far figures are drawn smaller, so their outline is thinner too).
Flash frames use the outline of their non-flash pose so the muzzle flash itself
is not outlined. Writes assets/sprites/outline_v030.json for sprite_meta.py.
"""
import json, os, re, sys, math
import numpy as np
from PIL import Image
from scipy import ndimage

NEAR = 1.08          # near band scale (data/stages/stage_01.json)
HELI_SCALE = float(os.environ.get("HELI_SCALE", "1.0"))
TARGET = {"rifleman": 360.0, "kneel": 250.0, "villager": 340.0, "mg": 240.0, "paratrooper": 350.0}
PARA_TOTAL_H = 712.0
ONSCREEN_PX = 3.5
INK = (18, 13, 10)

def load_meta(path):
    src = open(path).read()
    out = {}
    for m in re.finditer(r'"(\w+)": \[(\d+), (\d+), (\d+), (\d+), (\d+), (\d+), (\d+), (\d+)\]', src):
        out[m.group(1)] = [int(x) for x in m.groups()[1:]]
    return src, out

def fig_h(meta, n): return meta[n][3] - meta[n][5]

def near_scale(n, meta):
    if n.startswith(("rifleman_front", "rifleman_tq")): return NEAR * TARGET["rifleman"] / fig_h(meta, "rifleman_front_aim")
    if n.startswith("rifleman_kneel_front"): return NEAR * TARGET["kneel"] / fig_h(meta, "rifleman_kneel_front")
    if n.startswith("rifleman_kneel"): return NEAR * TARGET["kneel"] / fig_h(meta, "rifleman_kneel")
    if n.startswith("rifleman_"): return NEAR * TARGET["rifleman"] / fig_h(meta, "rifleman_aim")
    if n.startswith("villager_"):
        kind = n.split("_")[1]
        return NEAR * TARGET["villager"] / fig_h(meta, f"villager_{kind}_walk_01")
    if n.startswith("paratrooper_front"): return NEAR * PARA_TOTAL_H / fig_h(meta, "paratrooper_front")
    if n.startswith("paratrooper_"): return NEAR * TARGET["paratrooper"] / fig_h(meta, "paratrooper_body")
    if n.startswith("mg_"): return NEAR * TARGET["mg"] / fig_h(meta, "mg_front")
    if n.startswith(("food_", "power_")):
        m = meta[n]; used = max(m[6] - m[4], m[7] - m[5])
        return (104.0 if n.startswith("food_") else 118.0) / used
    if n.startswith("heli_"): return HELI_SCALE * (1.25 if n == "heli_crash" else 1.0)
    raise KeyError(n)

def wanted(n):
    if n.startswith(("rifleman_", "villager_", "paratrooper_", "mg_", "heli_")): return True
    if n.startswith(("food_", "power_")) and n not in ("food_parachute", "food_crate_chute"): return True
    return False

def outline(rgba, w, mask_src=None):
    a = rgba[..., 3].astype(np.float32) / 255.0
    base = (mask_src if mask_src is not None else a) > 0.5
    d = ndimage.distance_transform_edt(~base)
    oa = np.clip(w + 0.5 - d, 0.0, 1.0)
    oa[base] = 1.0 if mask_src is None else oa[base]
    out_a = a + (1 - a) * oa
    ink = np.array(INK, np.float32)
    rgb = rgba[..., :3].astype(np.float32)
    out_rgb = (rgb * a[..., None] + ink * (oa * (1 - a))[..., None]) / np.maximum(out_a[..., None], 1e-4)
    return np.dstack([np.clip(out_rgb, 0, 255), out_a * 255]).astype(np.uint8)

def main(orig):
    meta_path = "scripts/sprite_meta.gd"
    src, meta = load_meta(meta_path)
    record = {}
    for group in ("units", "vehicles"):
        for f in sorted(os.listdir(os.path.join(orig, group))):
            if not f.endswith(".png"): continue
            n = f[:-4]
            if n not in meta or not wanted(n): continue
            k = near_scale(n, meta)
            w = min(8.0, max(2.0, ONSCREEN_PX / k))
            P = int(math.ceil(w)) + 2
            im = np.asarray(Image.open(os.path.join(orig, group, f)).convert("RGBA"))
            pad = np.zeros((im.shape[0] + 2 * P, im.shape[1] + 2 * P, 4), np.uint8)
            pad[P:-P, P:-P] = im
            mask_src = None
            if n.endswith("_flash") and os.path.exists(os.path.join(orig, group, n[:-6] + ".png")):
                b = np.asarray(Image.open(os.path.join(orig, group, n[:-6] + ".png")).convert("RGBA"))
                if b.shape == im.shape:
                    mb = np.zeros(pad.shape[:2], np.float32); mb[P:-P, P:-P] = b[..., 3] / 255.0
                    mask_src = mb
            out = outline(pad, w, mask_src)
            Image.fromarray(out, "RGBA").save(os.path.join("assets/sprites", group, f), optimize=True)
            m = meta[n]
            new = [m[0] + 2 * P, m[1] + 2 * P, m[2] + P, m[3] + P, m[4] + P, m[5] + P, m[6] + P, m[7] + P]
            src = src.replace('"%s": [%s]' % (n, ", ".join(map(str, m))), '"%s": [%s]' % (n, ", ".join(map(str, new))))
            record[n] = {"pad": P, "width_px": round(w, 2), "near_scale": round(k, 3), "meta": new}
            print(f"{n:28s} near k {k:5.2f}  outline {w:4.1f} master px  pad {P}")
    open(meta_path, "w").write(src)
    json.dump(record, open("assets/sprites/outline_v030.json", "w"), indent=1)

if __name__ == "__main__":
    main(sys.argv[1])
