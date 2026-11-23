"""Annotate the in-game reminder screenshot for the CurseForge gallery.

Usage: python tools/annotate_reminders.py <in.png> <out.png>
Coordinates below are in the original screenshot's pixels (423x245 crop).
"""
import os
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gallery_style import BG, GOLD, TEXT, LINE, font, wrap, header

SCALE = 2
LEFT, RIGHT, TOP, BOTTOM = 330, 360, 90, 30

# (target x, y in the original shot (an icon edge, so the icon stays visible), side, label y on the canvas, title, body)
CALLOUTS = [
    (114, 52, "left", 120, "Your aura",
     "Shows only when your aura is off. Click the icon to cast it."),
    (197, 52, "right", 120, "Group blessings",
     "One icon per group member missing your blessing, with their name "
     "under it. Click it, or press your buff key to bless the next one."),
    (277, 121, "right", 300, "Cleanse button",
     "Beside each party frame. A coloured edge and a letter (M, P, D) "
     "show what you can remove. Faded = nothing to remove."),
    (119, 210, "left", 420, "Tank / DPS",
     "One click swaps gear set, action bar page and Righteous Fury."),
]


def main(src, dst):
    shot = Image.open(src).convert("RGB")
    shot = shot.resize((shot.width * SCALE, shot.height * SCALE), Image.LANCZOS)
    W = LEFT + shot.width + RIGHT
    H = TOP + shot.height + BOTTOM
    img = Image.new("RGB", (W, H), BG)
    img.paste(shot, (LEFT, TOP))
    d = ImageDraw.Draw(img)

    head_f, body_f = font(21, True), font(17)
    header(d, "Zyrumi's Libram: reminders", "Icons appear only when something is missing. "
           "When everything is up, nothing is on screen.")

    pad, box_w = 22, None
    for tx, ty, side, ly, title, body in CALLOUTS:
        px, py = LEFT + tx * SCALE, TOP + ty * SCALE
        box_w = (LEFT if side == "left" else RIGHT) - 2 * pad
        x0 = pad if side == "left" else LEFT + shot.width + pad
        lines = wrap(d, body, body_f, box_w)
        d.text((x0, ly), title, font=head_f, fill=GOLD)
        for i, line in enumerate(lines):
            d.text((x0, ly + 30 + i * 22), line, font=body_f, fill=TEXT)
        # leader line from the title row to the target
        ax = x0 + box_w + 6 if side == "left" else x0 - 6
        ay = ly + 14
        d.line([(ax, ay), (px, py)], fill=LINE, width=3)
        d.ellipse([px - 5, py - 5, px + 5, py + 5], fill=LINE)

    img.save(dst)
    print(dst, img.size)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
