# Builds the Zyrumi's Libram project icon from "Bookmark" by Lorc
# (https://game-icons.net/1x1/lorc/bookmark.html, CC BY 3.0, credited in the
# README and the CurseForge description): gold on a purple tile.
# Writes art/curseforge-icon.png (512 x 512) and a 64 x 64 preview.
# Run: python -I tools/make_icon.py
import os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "art")
SRC = os.path.join(ART, "source", "lorc-bookmark.png")  # white on transparent, 512 x 512

SIZE = 512
INSET = 0.80   # the icon takes 80% of the tile
RADIUS = 72
PURPLE = ((76, 40, 120), (30, 14, 52))       # tile: middle, edges
GOLD = ((255, 232, 150), (214, 160, 40))     # icon: top, bottom


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def main():
    mask = Image.open(SRC).convert("RGBA").getchannel("A")
    mask = mask.resize((round(SIZE * INSET),) * 2, Image.LANCZOS)

    tile = Image.new("RGB", (SIZE, SIZE))
    px = tile.load()
    c = (SIZE - 1) / 2
    far = (2 * c * c) ** 0.5
    for y in range(SIZE):
        for x in range(SIZE):
            px[x, y] = mix(*PURPLE, min(1.0, (((x - c) ** 2 + (y - c) ** 2) ** 0.5) / far))

    gold = Image.new("RGB", (1, mask.height))
    for y in range(mask.height):
        gold.putpixel((0, y), mix(*GOLD, y / (mask.height - 1)))
    gold = gold.resize(mask.size)
    off = (SIZE - mask.width) // 2
    tile.paste(gold, (off, off), mask)

    corners = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(corners).rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], RADIUS, fill=255)
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(tile, (0, 0), corners)
    out.save(os.path.join(ART, "curseforge-icon.png"))
    out.resize((64, 64), Image.LANCZOS).save(os.path.join(ART, "curseforge-icon-64.png"))
    print("saved", os.path.normpath(os.path.join(ART, "curseforge-icon.png")))


if __name__ == "__main__":
    main()
