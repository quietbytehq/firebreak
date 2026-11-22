#!/usr/bin/env python3
"""Contact sheet of the 0.3.1 first-person weapon views (store order) on a dusk-coloured
panel or a checkerboard. With --marks the muzzle (and launcher rear) points are drawn."""
import json, sys
from PIL import Image, ImageDraw, ImageFont
root, out = sys.argv[1], sys.argv[2]
mode = "checker" if "--checker" in sys.argv else "dusk"; marks = "--marks" in sys.argv
d = json.load(open(f"{root}/data/weapons.json")); fp = json.load(open(f"{root}/data/fp_weapons.json"))["views"]
items = [(w["id"], w["name"]) for w in d["weapons"]] + [("air_strike", "Air Strike")]
cols, cell = 5, 340
rows = (len(items) + cols - 1) // cols
sheet = Image.new("RGB", (cols * cell, rows * (cell + 34) + 60), (24, 20, 16))
dr = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    big = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 28)
except Exception:
    font = big = ImageFont.load_default()
dr.text((16, 14), "FIREBREAK 0.3.1 - first-person weapon views (%s)" % mode, fill=(255, 200, 110), font=big)
for i, (wid, name) in enumerate(items):
    x, y = (i % cols) * cell, (i // cols) * (cell + 34) + 60
    if mode == "checker":
        for cy in range(0, cell, 20):
            for cx in range(0, cell, 20):
                c = (200, 200, 200) if (cx // 20 + cy // 20) % 2 else (90, 90, 90)
                dr.rectangle([x + cx, y + cy, x + cx + 19, y + cy + 19], fill=c)
    else:
        for r in range(cell):
            t = r / cell
            dr.line([(x, y + r), (x + cell - 1, y + r)], fill=(int(150 - 90 * t), int(90 - 50 * t), int(60 - 30 * t)))
    im = Image.open(f"{root}/assets/sprites/fp/{wid}.png").resize((cell - 10, cell - 10), Image.LANCZOS)
    sheet.paste(im, (x + 5, y + 5), im)
    if marks:
        for key, col in (("muzzle", (255, 255, 0)), ("rear", (0, 255, 255))):
            if key in fp[wid]:
                px, py = x + 5 + fp[wid][key][0] * (cell - 10), y + 5 + fp[wid][key][1] * (cell - 10)
                dr.ellipse([px - 7, py - 7, px + 7, py + 7], outline=col, width=3)
    dr.text((x + 10, y + cell + 4), name, fill=(240, 230, 210), font=font)
sheet.save(out)
print(out, sheet.size)
