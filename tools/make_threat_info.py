"""Draw the threat explainer for the CurseForge gallery (no game screenshot:
too busy to capture while tanking). Uses the addon's own icons from Media/.

Usage: python tools/make_threat_info.py <out.png>
"""
import os
import sys
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from gallery_style import BG, GOLD, TEXT, MUTED, font, wrap, header

MEDIA = os.path.join(HERE, "..", "Media")
W, H = 1536, 708
COL_W = 440
COL_X = [64, 548, 1032]
PLATE_Y = 250
ICON = 56

# (icon, mob name, mob level, health share, name shown beside the icon, title, body)
COLUMNS = [
    ("ThreatMine", "Kobold Tunneler", 18, 0.85, None, "Yours",
     "The mob is on you and your lead is safe."),
    ("ThreatSlipping", "Kobold Geomancer", 18, 0.60, None, "Slipping",
     "Still on you, but someone is about to pull it off. Hit it again "
     "before it goes."),
    ("ThreatLoose", "Kobold Miner", 17, 0.95, "Ashfen", "Not yours",
     "Someone else has it, and their name is beside the icon, so you know "
     "who to rescue."),
]

NOTES = [
    ("Only when it matters",
     "Shows in combat, in a group. Solo, a mob on you is no news, so "
     "nothing shows. Needs enemy nameplates on (V)."),
    ("Your target's portrait",
     "The same icon sits on the corner of your target's portrait. Hover it "
     "for the numbers: your lead over the next person, or your share of "
     "the holder's threat."),
    ("Not the tank?",
     "The warning marks mobs that are on you, and the half shield warns "
     "you before you pull aggro off your tank."),
]


def icon(name, size):
    im = Image.open(os.path.join(MEDIA, name + ".tga")).convert("RGBA")
    return im.resize((size, size), Image.LANCZOS)


def nameplate(img, d, cx, y, name, level, share):
    """A plain enemy nameplate: name, red health bar, level box."""
    bar_w, bar_h = 230, 20
    x0 = cx - bar_w // 2
    name_f = font(19, True)
    tw = d.textlength(name, font=name_f)
    d.text((cx - tw / 2, y - 28), name, font=name_f, fill=(255, 255, 255),
           stroke_width=2, stroke_fill=(0, 0, 0))
    d.rectangle([x0 - 3, y - 3, x0 + bar_w + 3, y + bar_h + 3], fill=(0, 0, 0))
    d.rectangle([x0, y, x0 + bar_w, y + bar_h], fill=(60, 10, 10))
    d.rectangle([x0, y, x0 + int(bar_w * share), y + bar_h], fill=(200, 20, 20))
    d.rectangle([x0, y, x0 + int(bar_w * share), y + 5], fill=(235, 70, 60))
    lx = x0 + bar_w + 8
    d.rectangle([lx, y - 1, lx + 30, y + bar_h + 1], fill=(0, 0, 0), outline=(90, 90, 70))
    lvl = str(level)
    lw = d.textlength(lvl, font=font(15, True))
    d.text((lx + 15 - lw / 2, y + 1), lvl, font=font(15, True), fill=(120, 230, 90))
    return y - 28  # top of the name


def main(out):
    img = Image.new("RGBA", (W, H), BG + (255,))
    d = ImageDraw.Draw(img)
    header(d, "Zyrumi's Libram: threat for tanks",
           "A small icon above every enemy in the fight tells you at a glance "
           "which mobs you hold. Shape, not just colour.")

    # the "scene" band behind the nameplates
    d.rounded_rectangle([40, 110, W - 40, 340], radius=12, fill=(34, 30, 26))

    head_f, body_f = font(24, True), font(18)
    for x, (ic, mob, lvl, share, who, title, body) in zip(COL_X, COLUMNS):
        cx = x + COL_W // 2
        name_top = nameplate(img, d, cx, PLATE_Y, mob, lvl, share)
        iy = name_top - ICON - 8
        img.alpha_composite(icon(ic, ICON), (cx - ICON // 2, iy))
        if who:
            d.text((cx + ICON // 2 + 6, iy + ICON // 2 - 14), who, font=font(22, True),
                   fill=(255, 115, 115), stroke_width=2, stroke_fill=(0, 0, 0))

        # explanation under the scene, with the icon again as a key
        ty = 372
        img.alpha_composite(icon(ic, 40), (x, ty))
        d.text((x + 52, ty + 4), title, font=head_f, fill=GOLD)
        for i, line in enumerate(wrap(d, body, body_f, COL_W - 10)):
            d.text((x, ty + 54 + i * 26), line, font=body_f, fill=TEXT)

    # notes strip
    d.line([(40, 548), (W - 40, 548)], fill=(70, 62, 52), width=2)
    note_h, note_b = font(19, True), font(16)
    for x, (title, body) in zip(COL_X, NOTES):
        d.text((x, 570), title, font=note_h, fill=GOLD)
        for i, line in enumerate(wrap(d, body, note_b, COL_W - 10)):
            d.text((x, 602 + i * 23), line, font=note_b, fill=MUTED)

    img.convert("RGB").save(out)
    print(out, img.size)


if __name__ == "__main__":
    main(sys.argv[1])
