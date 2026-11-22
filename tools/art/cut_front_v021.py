"""Cut the 0.2.1 front-facing enemy poses from the generated sheets.
Objects are found as connected components on the grey sheet, sorted left to right.
Usage: python3 cut_front_v021.py <sheets_dir> <out_dir> <pipeline_dir>
<pipeline_dir> holds process_sprites.py (the rembg cut-out pipeline used for the
0.2.0 sprites; kept with the art working files, not shipped with the game).
Needs rembg (isnet-general-use model), numpy, scipy, Pillow, OpenCV."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, sys.argv[3] if len(sys.argv) > 3 else str(Path(__file__).parent))
import process_sprites as P
from rembg import new_session

G = Path(sys.argv[1])
OUT = Path(sys.argv[2])
CANOPY = Path(__file__).resolve().parents[2] / "assets/sprites/units/parachute_open.png"
session = new_session("isnet-general-use")

def objects(path, min_area=4000):
    rgb = np.array(Image.open(path).convert("RGB"))
    bg = P.sample_bg(rgb)
    fg = ~P.flood_background(rgb, bg, tol=24.0)
    lab, n = ndimage.label(ndimage.binary_dilation(fg, iterations=6))
    boxes = []
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        area = int((lab[sl] == i).sum())
        if area >= min_area:
            boxes.append((sl[1].start, sl[0].start, sl[1].stop, sl[0].stop))
    boxes.sort()
    return rgb, bg, boxes

def cut(rgb, bg, box, pad=14):
    h, w, _ = rgb.shape
    x0, y0, x1, y1 = max(0, box[0]-pad), max(0, box[1]-pad), min(w, box[2]+pad), min(h, box[3]+pad)
    crop = rgb[y0:y1, x0:x1].copy()
    rgba = P.cutout_from_rgb(crop, session, bg=bg)
    rgba = P.keep_main_components(rgba)
    # Enclosed background (between straps, arms, legs) is not reached by the
    # border flood fill: clear background-coloured blobs inside the figure.
    d = P.color_dist(crop, bg)
    sat = crop.max(axis=2).astype(int) - crop.min(axis=2).astype(int)
    hole = (d < 20) & (sat < 14)
    lab, n = ndimage.label(hole)
    if n:
        sizes = ndimage.sum(hole, lab, range(1, n + 1))
        big = np.zeros(n + 1, bool); big[1:] = sizes >= 30
        kill = ndimage.binary_dilation(big[lab], iterations=1)
        a = rgba[:, :, 3].astype(float)
        a[kill] = 0
        rgba[:, :, 3] = a.astype(np.uint8)
    return P.crop_tight(rgba, pad=2), (x0, y0)

def flash_point(rgba):
    """Centre of the brightest warm pixels (painted muzzle flash), tight-crop coords."""
    r, g, b, a = [rgba[:, :, i].astype(float) for i in range(4)]
    m = (r > 235) & (g > 170) & (b < 170) & (a > 128)
    if m.sum() < 6:
        return None
    ys, xs = np.where(m)
    return float(xs.mean()), float(ys.mean())

def save_group(items, anchor="feet"):
    cw = max(P.needed_canvas(x[1], anchor)[0] for x in items)
    ch = max(P.needed_canvas(x[1], anchor)[1] for x in items)
    info = {}
    for name, rgba in items:
        canvas, anc = P.place_on_canvas(rgba, cw, ch, anchor)
        P.save_png(OUT / f"{name}.png", canvas)
        fp = flash_point(canvas)
        info[name] = {"size": (cw, ch), "anchor": anc, "flash": fp}
        print(name, cw, ch, anc, "flash", fp)
    return info

if __name__ == "__main__":
    rgb, bg, boxes = objects(G / "front_riflemen.jpg")
    print("riflemen boxes", boxes)
    assert len(boxes) == 6, boxes
    c = [cut(rgb, bg, b)[0] for b in boxes]
    save_group([("rifleman_front_aim", c[0]), ("rifleman_front_fire", c[1]),
                ("rifleman_tq_aim", c[4]), ("rifleman_tq_fire", c[5])])
    save_group([("rifleman_kneel_front", c[2]), ("rifleman_kneel_front_flash", c[3])])
    rgb, bg, boxes = objects(G / "front_mg_para.jpg")
    print("mg boxes", boxes)
    m = [cut(rgb, bg, b)[0] for b in boxes[:2]]
    save_group([("mg_front", m[0]), ("mg_front_flash", m[1])])
    rgb, bg, boxes = objects(G / "front_para.jpg")
    print("para boxes", boxes)
    p = [cut(rgb, bg, b)[0] for b in boxes[:2]]
    # Risers run off the top of the sheet: put the existing open canopy over them.
    canopy = np.array(Image.open(CANOPY))
    canopy = P.crop_tight(canopy, pad=0)
    out = []
    for name, body in (("paratrooper_front", p[0]), ("paratrooper_front_flash", p[1])):
        bh, bw = body.shape[:2]
        cwid = int(bw * 1.55)
        can = np.array(Image.fromarray(canopy).resize((cwid, int(canopy.shape[0] * cwid / canopy.shape[1])), Image.Resampling.LANCZOS))
        overlap = int(can.shape[0] * 0.10)
        H = can.shape[0] + bh - overlap
        W = max(cwid, bw)
        comp = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        comp.alpha_composite(Image.fromarray(body), ((W - bw) // 2, H - bh))
        comp.alpha_composite(Image.fromarray(can), ((W - cwid) // 2, 0))
        out.append((name, np.array(comp)))
    save_group(out)
