# Draws the Zyrumi's Libram project icon (original artwork from plain shapes,
# no game assets). Writes art/curseforge-icon.png (512 x 512) and a 64 x 64
# preview. Run: python -I tools/make_icon.py
import math, os
from PIL import Image, ImageDraw, ImageFilter

S = 2048            # drawn large, scaled down for smooth edges
OUT = 512
HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "art")

INDIGO = (24, 20, 52)
INDIGO_LIGHT = (52, 40, 98)
GOLD = (240, 196, 86)
GOLD_DARK = (176, 128, 40)
GOLD_LIGHT = (255, 232, 160)
LEATHER = (124, 30, 62)
LEATHER_DARK = (78, 16, 38)
LEATHER_LIGHT = (158, 52, 86)
PAGES = (244, 232, 204)
PAGES_LINE = (204, 188, 156)
RIBBON = (232, 104, 150)
RIBBON_DARK = (170, 60, 100)


def rounded(draw, box, r, fill, outline=None, width=0):
    draw.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


def main():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    # Background: rounded square, darker at the edges.
    bg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(bg)
    rounded(d, (0, 0, S - 1, S - 1), 300, INDIGO)
    for i in range(40):  # soft lighter centre
        t = i / 40
        r = int(S * 0.62 * (1 - t))
        c = tuple(int(INDIGO[k] + (INDIGO_LIGHT[k] - INDIGO[k]) * t) for k in range(3))
        d.ellipse((S // 2 - r, S // 2 - r - 60, S // 2 + r, S // 2 + r - 60), fill=c)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, S - 1, S - 1), radius=300, fill=255)
    bg.putalpha(mask)
    img = Image.alpha_composite(img, bg)

    # Warm glow behind the book.
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((420, 330, S - 420, S - 330), fill=(255, 200, 90, 120))
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    glow.putalpha(Image.composite(glow.getchannel("A"), Image.new("L", (S, S), 0), mask))
    img = Image.alpha_composite(img, glow)

    d = ImageDraw.Draw(img)
    # Book box
    L, T, R, B = 540, 360, 1540, 1700

    # Drop shadow
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((L + 50, T + 70, R + 70, B + 80), radius=70, fill=(0, 0, 0, 150))
    sh = sh.filter(ImageFilter.GaussianBlur(40))
    img = Image.alpha_composite(img, sh)
    d = ImageDraw.Draw(img)

    # Page block showing on the right and bottom
    rounded(d, (L + 70, T + 40, R + 46, B + 40), 50, PAGES)
    for k in range(8):
        y = T + 140 + k * 175
        d.line((R + 2, y, R + 40, y), fill=PAGES_LINE, width=10)
    for k in range(4):
        x = L + 300 + k * 250
        if x < R:
            d.line((x, B + 4, x, B + 36), fill=PAGES_LINE, width=10)

    # Cover
    rounded(d, (L, T, R, B), 70, LEATHER)
    # Spine band on the left
    rounded(d, (L, T, L + 150, B), 70, LEATHER_DARK)
    d.rectangle((L + 80, T, L + 150, B), fill=LEATHER_DARK)
    for y in (T + 230, B - 230):
        d.rectangle((L + 10, y - 28, L + 150, y + 28), fill=GOLD_DARK)
        d.rectangle((L + 10, y - 16, L + 150, y + 16), fill=GOLD)
    # Soft highlight on the cover
    hl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(hl).rounded_rectangle((L + 200, T + 40, R - 60, T + 420), radius=60, fill=LEATHER_LIGHT + (90,))
    hl = hl.filter(ImageFilter.GaussianBlur(50))
    img = Image.alpha_composite(img, hl)
    d = ImageDraw.Draw(img)

    # Gold frame inset on the cover
    rounded(d, (L + 210, T + 90, R - 90, B - 90), 40, None, outline=GOLD_DARK, width=34)
    rounded(d, (L + 210, T + 90, R - 90, B - 90), 40, None, outline=GOLD, width=18)

    # Corner guards (cover corners on the right side)
    for (cx, cy, sx, sy) in ((R, T, -1, 1), (R, B, -1, -1)):
        pts = [(cx, cy), (cx + sx * 260, cy), (cx, cy + sy * 260)]
        d.polygon(pts, fill=GOLD_DARK)
        pts2 = [(cx + sx * 14, cy + sy * 14), (cx + sx * 220, cy + sy * 14), (cx + sx * 14, cy + sy * 220)]
        d.polygon(pts2, fill=GOLD)
        d.ellipse((cx + sx * 70 - 26, cy + sy * 70 - 26, cx + sx * 70 + 26, cy + sy * 70 + 26), fill=GOLD_LIGHT)

    # Seal: a sunburst in a ring, centred on the cover frame
    cx, cy = (L + 210 + R - 90) // 2, (T + 90 + B - 90) // 2
    rays = 16
    outer, inner = 330, 210
    pts = []
    for i in range(rays * 2):
        a = math.pi * i / rays - math.pi / 2
        rr = outer if i % 2 == 0 else inner
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=GOLD_DARK)
    pts = []
    for i in range(rays * 2):
        a = math.pi * i / rays - math.pi / 2
        rr = (outer - 26) if i % 2 == 0 else (inner - 10)
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=GOLD)
    d.ellipse((cx - 190, cy - 190, cx + 190, cy + 190), fill=GOLD_DARK)
    d.ellipse((cx - 165, cy - 165, cx + 165, cy + 165), fill=LEATHER_DARK)
    d.ellipse((cx - 120, cy - 120, cx + 120, cy + 120), fill=GOLD)
    d.ellipse((cx - 70, cy - 70, cx + 70, cy + 70), fill=GOLD_LIGHT)

    # Ribbon bookmark hanging below the book
    rx = L + 760
    d.polygon([(rx - 70, B - 40), (rx + 70, B - 40), (rx + 70, B + 230), (rx, B + 170), (rx - 70, B + 230)], fill=RIBBON)
    d.polygon([(rx + 20, B - 40), (rx + 70, B - 40), (rx + 70, B + 230), (rx + 20, B + 190)], fill=RIBBON_DARK)

    out = img.resize((OUT, OUT), Image.LANCZOS)
    os.makedirs(ART, exist_ok=True)
    out.save(os.path.join(ART, "curseforge-icon.png"))
    out.resize((64, 64), Image.LANCZOS).save(os.path.join(ART, "curseforge-icon-64.png"))
    print("saved", os.path.normpath(os.path.join(ART, "curseforge-icon.png")))


if __name__ == "__main__":
    main()
