#!/usr/bin/env python3
"""Bakes a sticker-style outline (thin dark inner line, thin white outer edge)
into the character, villager, helicopter and pickup sprites (Firebreak 0.3.2)
and updates scripts/sprite_meta.gd to match.

Run from the project root:
  python3 tools/art/bake_outlines.py ORIG_DIR
ORIG_DIR holds the un-outlined masters (units/ and vehicles/). Outlined PNGs
are written to assets/sprites/. Every canvas grows by P px on each side, the
anchor and opaque box move by P, and the opaque box stays the original figure
so in-game scale (figure height between top and feet) is unchanged.

On-screen width at the near band is about 1 px dark + 2 px white. Width in
master pixels = those on-screen sizes divided by the sprite's near-band scale,
so farther (smaller) figures get a proportionally thinner outline. Flash frames
reuse the outline of their non-flash pose so the muzzle flash itself is not
outlined. Writes assets/sprites/outline_v032.json for the record.
"""
import json, os, re, sys, math
import numpy as np
from PIL import Image
from scipy import ndimage

NEAR = 1.08
HELI_SCALE = float(os.environ.get("HELI_SCALE", "0.75"))
TARGET = {"rifleman": 360.0, "kneel": 250.0, "villager": 340.0, "mg": 240.0, "paratrooper": 350.0}
PARA_TOTAL_H = 712.0
ONSCREEN_DARK = 1.0
ONSCREEN_WHITE = 2.0
INK = np.array((18, 13, 10), np.float32)
WHITE = np.array((255, 255, 255), np.float32)

def load_meta(path):
    src = open(path).read()
    out = {}
    for m in re.finditer(r'"(\w+)": \[(\d+), (\d+), (\d+), (\d+), (\d+), (\d+), (\d+), (\d+)\]', src):
        out[m.group(1)] = [int(x) for x in m.groups()[1:]]
    return src, out

def fig_h(meta, n):
    return meta[n][3] - meta[n][5]

def near_scale(n, meta):
    if n.startswith(("rifleman_front", "rifleman_tq")):
        return NEAR * TARGET["rifleman"] / fig_h(meta, "rifleman_front_aim")
    if n.startswith("rifleman_kneel_front"):
        return NEAR * TARGET["kneel"] / fig_h(meta, "rifleman_kneel_front")
    if n.startswith("rifleman_kneel"):
        return NEAR * TARGET["kneel"] / fig_h(meta, "rifleman_kneel")
    if n.startswith("rifleman_"):
        return NEAR * TARGET["rifleman"] / fig_h(meta, "rifleman_aim")
    if n.startswith("villager_"):
        kind = n.split("_")[1]
        return NEAR * TARGET["villager"] / fig_h(meta, f"villager_{kind}_walk_01")
    if n.startswith("paratrooper_front"):
        return NEAR * PARA_TOTAL_H / fig_h(meta, "paratrooper_front")
    if n.startswith("paratrooper_"):
        return NEAR * TARGET["paratrooper"] / fig_h(meta, "paratrooper_body")
    if n.startswith("mg_"):
        return NEAR * TARGET["mg"] / fig_h(meta, "mg_front")
    if n.startswith(("food_", "power_")):
        m = meta[n]
        used = max(m[6] - m[4], m[7] - m[5])
        return (104.0 if n.startswith("food_") else 118.0) / used
    if n.startswith("heli_"):
        return HELI_SCALE * (1.25 if n == "heli_crash" else 1.0)
    raise KeyError(n)

def wanted(n):
    if n.startswith(("rifleman_", "villager_", "paratrooper_", "mg_", "heli_")):
        return True
    if n.startswith(("food_", "power_")) and n not in ("food_parachute", "food_crate_chute"):
        return True
    return False

def sticker(rgba, w_dark, w_white, mask_src=None):
    a = rgba[..., 3].astype(np.float32) / 255.0
    base = (mask_src if mask_src is not None else a) > 0.5
    d = ndimage.distance_transform_edt(~base)
    dark_a = np.clip(w_dark + 0.5 - d, 0.0, 1.0)
    white_a = np.clip(w_dark + w_white + 0.5 - d, 0.0, 1.0)
    # Soft rings outside the figure (or outside the body mask for flash frames).
    dark_ring = dark_a * (1.0 - a)
    white_ring = np.clip(white_a - dark_a, 0.0, 1.0) * (1.0 - a)
    out_a = np.clip(a + dark_ring + white_ring, 0.0, 1.0)
    rgb = rgba[..., :3].astype(np.float32)
    out_rgb = rgb * a[..., None] + INK * dark_ring[..., None] + WHITE * white_ring[..., None]
    out_rgb = out_rgb / np.maximum(out_a[..., None], 1e-4)
    return np.dstack([np.clip(out_rgb, 0, 255), out_a * 255]).astype(np.uint8)

def main(orig):
    meta_path = "scripts/sprite_meta.gd"
    src, meta = load_meta(meta_path)
    record = {}
    for group in ("units", "vehicles"):
        group_dir = os.path.join(orig, group)
        if not os.path.isdir(group_dir):
            continue
        for f in sorted(os.listdir(group_dir)):
            if not f.endswith(".png"):
                continue
            n = f[:-4]
            if n not in meta or not wanted(n):
                continue
            k = near_scale(n, meta)
            w_dark = min(4.0, max(0.7, ONSCREEN_DARK / k))
            w_white = min(6.0, max(1.2, ONSCREEN_WHITE / k))
            P = int(math.ceil(w_dark + w_white)) + 2
            im = np.asarray(Image.open(os.path.join(orig, group, f)).convert("RGBA"))
            pad = np.zeros((im.shape[0] + 2 * P, im.shape[1] + 2 * P, 4), np.uint8)
            pad[P:-P, P:-P] = im
            mask_src = None
            if n.endswith("_flash"):
                base_name = n[:-6] + ".png"
                base_path = os.path.join(orig, group, base_name)
                if os.path.exists(base_path):
                    b = np.asarray(Image.open(base_path).convert("RGBA"))
                    if b.shape == im.shape:
                        mb = np.zeros(pad.shape[:2], np.float32)
                        mb[P:-P, P:-P] = b[..., 3] / 255.0
                        mask_src = mb
            out = sticker(pad, w_dark, w_white, mask_src)
            dest = os.path.join("assets/sprites", group, f)
            Image.fromarray(out, "RGBA").save(dest, optimize=True)
            m = meta[n]
            new = [m[0] + 2 * P, m[1] + 2 * P, m[2] + P, m[3] + P, m[4] + P, m[5] + P, m[6] + P, m[7] + P]
            src = src.replace('"%s": [%s]' % (n, ", ".join(map(str, m))),
                              '"%s": [%s]' % (n, ", ".join(map(str, new))))
            record[n] = {
                "pad": P,
                "dark_px": round(w_dark, 2),
                "white_px": round(w_white, 2),
                "near_scale": round(k, 3),
                "meta": new,
            }
            print(f"{n:28s} near k {k:5.2f}  dark {w_dark:4.1f}  white {w_white:4.1f}  pad {P}")
    open(meta_path, "w").write(src)
    json.dump(record, open("assets/sprites/outline_v032.json", "w"), indent=1)
    print("wrote", len(record), "outlined sprites")

if __name__ == "__main__":
    main(sys.argv[1])
