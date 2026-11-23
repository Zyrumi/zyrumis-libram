"""Shared look for the CurseForge gallery images (annotate_reminders, make_threat_info)."""
from PIL import ImageFont

BG = (20, 17, 14)
GOLD = (255, 209, 0)
TEXT = (235, 230, 220)
MUTED = (165, 158, 145)
LINE = (255, 209, 0)

FONT = "C:/Windows/Fonts/segoeui.ttf"
FONT_B = "C:/Windows/Fonts/segoeuib.ttf"


def font(size, bold=False):
    return ImageFont.truetype(FONT_B if bold else FONT, size)


def wrap(draw, text, fnt, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        test = (cur + " " + w).strip()
        if draw.textlength(test, font=fnt) <= width:
            cur = test
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def header(draw, title, subtitle):
    draw.text((24, 18), title, font=font(30, True), fill=GOLD)
    draw.text((24, 56), subtitle, font=font(18), fill=MUTED)
