#!/usr/bin/env python3
"""Contact sheet of the weapon icons (store order) on a dark HUD panel and on a checkerboard."""
import json, sys
from PIL import Image, ImageDraw, ImageFont
root = sys.argv[1]; out = sys.argv[2]; mode = sys.argv[3] if len(sys.argv) > 3 else "dark"
d = json.load(open(f"{root}/data/weapons.json"))
items = [(w["id"], w["name"], w["category"]) for w in d["weapons"]] + [("air_strike", "Air Strike", "special")]
cols, cw, ch = 5, 380, 230
rows = (len(items) + cols - 1) // cols
sheet = Image.new("RGB", (cols * cw, rows * ch + 60), (24, 20, 16))
dr = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    big = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 28)
except Exception:
    font = big = ImageFont.load_default()
dr.text((16, 14), "FIREBREAK 0.3.0 - weapon icons (%s background)" % mode, fill=(255, 200, 110), font=big)
for i, (wid, name, cat) in enumerate(items):
    x, y = (i % cols) * cw, (i // cols) * ch + 60
    if mode == "checker":
        for cy in range(0, ch, 20):
            for cx in range(0, cw, 20):
                c = (200, 200, 200) if (cx // 20 + cy // 20) % 2 else (90, 90, 90)
                dr.rectangle([x + cx, y + cy, x + cx + 19, y + cy + 19], fill=c)
    else:
        dr.rectangle([x + 6, y + 6, x + cw - 6, y + ch - 6], fill=(13, 10, 8), outline=(120, 85, 50), width=2)
    ic = Image.open(f"{root}/assets/ui/weapons/{wid}.png")
    k = min((cw - 40) / ic.width, (ch - 70) / ic.height)
    ic = ic.resize((int(ic.width * k), int(ic.height * k)), Image.LANCZOS)
    sheet.paste(ic, (x + (cw - ic.width) // 2, y + 14 + (ch - 70 - ic.height) // 2), ic)
    dr.text((x + 16, y + ch - 46), f"{name}", fill=(255, 220, 160), font=font)
    dr.text((x + cw - 16 - dr.textlength(cat.upper(), font=font), y + ch - 46), cat.upper(), fill=(150, 130, 110), font=font)
sheet.save(out)
print(out, sheet.size)
