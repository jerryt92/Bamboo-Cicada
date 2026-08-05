#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parent
SOURCE = ROOT / "source-screenshots"
SCREENSHOTS = ROOT / "screenshots"
PREVIEWS = ROOT / "previews"
WEB_ASSETS = PROJECT / "zhuzhiliao" / "assets"

IPHONE_SIZE = (1242, 2688)
IPHONE_MOCKUP_RATIO = 1320 / 2868
SOCIAL_W, SOCIAL_H = 1600, 900

ZH_FONT = "/System/Library/Fonts/Hiragino Sans GB.ttc"
SERIF_FONT = "/System/Library/Fonts/NewYork.ttf"
TEXT_FONT = "/System/Library/Fonts/SFNS.ttf"


def font(path: str, size: int, index: int = 0) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size=size, index=index)


def cover(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    img = img.convert("RGB")
    scale = max(size[0] / img.width, size[1] / img.height)
    resized = img.resize((round(img.width * scale), round(img.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def contain(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    img = img.convert("RGBA")
    scale = min(size[0] / img.width, size[1] / img.height)
    return img.resize((round(img.width * scale), round(img.height * scale)), Image.Resampling.LANCZOS)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def paste_rounded(base: Image.Image, img: Image.Image, box: tuple[int, int], radius: int) -> None:
    mask = rounded_mask(img.size, radius)
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    layer.paste(img.convert("RGBA"), box, mask)
    base.alpha_composite(layer)


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(size[1]):
        t = y / max(1, size[1] - 1)
        color = tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(size[0]):
            px[x, y] = color
    return img.convert("RGBA")


def wrap_tokens(text: str) -> tuple[list[str], bool]:
    if any("\u4e00" <= c <= "\u9fff" for c in text):
        return re.findall(r"[A-Za-z0-9]+(?:[-'][A-Za-z0-9]+)*|[^\s]", text), True
    return text.split(), False


def draw_wrapped(draw: ImageDraw.ImageDraw, text: str, xy: tuple[int, int], width: int, fnt, fill, line_gap=12):
    words, compact = wrap_tokens(text)
    lines: list[str] = []
    current = ""
    for word in words:
        sep = ""
        if current and not compact:
            sep = " "
        elif current and compact and current[-1].isascii() and word[0].isascii():
            sep = " "
        candidate = word if not current else current + sep + word
        if draw.textbbox((0, 0), candidate, font=fnt)[2] <= width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)

    x, y = xy
    for line in lines:
        draw.text((x, y), line, font=fnt, fill=fill)
        y += draw.textbbox((0, 0), line, font=fnt)[3] + line_gap
    return y


def draw_phone_frame(base: Image.Image, screenshot: Image.Image, box: tuple[int, int, int, int], shadow=True) -> None:
    x, y, w, h = box
    if shadow:
        shade = Image.new("RGBA", (w + 80, h + 80), (0, 0, 0, 0))
        sd = ImageDraw.Draw(shade)
        sd.rounded_rectangle((40, 40, w + 40, h + 40), radius=72, fill=(0, 0, 0, 120))
        shade = shade.filter(ImageFilter.GaussianBlur(22))
        base.alpha_composite(shade, (x - 40, y - 20))

    d = ImageDraw.Draw(base)
    radius = max(42, round(w * 0.115))
    outline = max(5, round(w * 0.012))
    inset = max(16, round(w * 0.035))
    d.rounded_rectangle((x, y, x + w, y + h), radius=radius, fill=(29, 28, 24), outline=(226, 209, 168), width=outline)
    screen_box = (x + inset, y + inset, w - inset * 2, h - inset * 2)
    screen = cover(screenshot, (screen_box[2], screen_box[3])).convert("RGBA")
    paste_rounded(base, screen, (screen_box[0], screen_box[1]), max(32, radius - inset))
    island_w, island_h = round(w * 0.34), max(30, round(h * 0.023))
    d.rounded_rectangle(
        (x + (w - island_w) // 2, y + round(h * 0.023), x + (w + island_w) // 2, y + round(h * 0.023) + island_h),
        radius=max(16, island_h // 2),
        fill=(5, 5, 5, 235),
    )


def make_screenshot(
    output_dir: Path,
    size: tuple[int, int],
    filename: str,
    lang: str,
    title: str,
    subtitle: str,
    source_name: str,
    feature: str,
) -> Image.Image:
    canvas_w, canvas_h = size
    source = Image.open(SOURCE / source_name)
    bg = cover(source, size).filter(ImageFilter.GaussianBlur(20))
    bg = ImageEnhance.Brightness(bg).enhance(0.58).convert("RGBA")
    overlay = gradient(size, (6, 48, 31), (246, 205, 105))
    bg = Image.blend(bg, overlay, 0.32)
    d = ImageDraw.Draw(bg)

    scale = canvas_h / IPHONE_SIZE[1]
    wide = canvas_w / canvas_h > 0.6
    margin_x = round(canvas_w * (0.07 if not wide else 0.08))
    title_width = round(canvas_w * (0.74 if not wide else 0.46))
    title_font = font(ZH_FONT if lang == "zh" else SERIF_FONT, round((92 if lang == "zh" else 82) * scale))
    subtitle_font = font(ZH_FONT if lang == "zh" else TEXT_FONT, round(39 * scale))
    feature_font = font(ZH_FONT if lang == "zh" else TEXT_FONT, round(30 * scale))

    brand = "Bamboo Cicada: Chinese Folk Sound Toy"
    d.text((margin_x, round(104 * scale)), brand, font=font(SERIF_FONT, max(22, round(28 * scale))), fill=(255, 239, 184, 235))
    y = draw_wrapped(d, title, (margin_x, round(174 * scale)), title_width, title_font, (255, 246, 220), line_gap=round(18 * scale))
    y = draw_wrapped(d, subtitle, (margin_x, y + round(24 * scale)), title_width, subtitle_font, (255, 235, 184), line_gap=round(10 * scale))

    phone_h = round(canvas_h * (0.66 if not wide else 0.76))
    phone_w = round(phone_h * IPHONE_MOCKUP_RATIO)
    phone_x = round((canvas_w - phone_w) * (0.5 if not wide else 0.68))
    phone_y = round(canvas_h * (0.26 if not wide else 0.17))
    draw_phone_frame(bg, source, (phone_x, phone_y, phone_w, phone_h))

    pill_h = round(96 * scale)
    pill_y = canvas_h - round(160 * scale)
    d.rounded_rectangle((margin_x, pill_y, canvas_w - margin_x, pill_y + pill_h), radius=pill_h // 2, fill=(255, 246, 220, 232))
    d.text((margin_x + round(42 * scale), pill_y + round(28 * scale)), feature, font=feature_font, fill=(96, 35, 18))

    for i in range(3):
        r = round((42 + i * 31) * scale)
        cx = canvas_w - margin_x - round(96 * scale)
        cy = pill_y + pill_h // 2
        d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(170, 34, 26, 80 - i * 20), width=max(3, round(4 * scale)))
    dot_r = round(17 * scale)
    d.ellipse((cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r), fill=(174, 32, 26))

    bg.convert("RGB").save(output_dir / filename)
    return bg


def make_social_cards() -> None:
    base = cover(Image.open(WEB_ASSETS / "hero-promo-base.png"), (SOCIAL_W, SOCIAL_H)).convert("RGBA")
    for lang, filename, title, subtitle, cta in [
        ("zh", "promo-social-zh.png", "竹知了: 中华民间声玩", "把中华民间声玩装进 iPhone", "震动反馈 · 鸣蝉声 · 竹林童玩"),
        ("en", "promo-social-en.png", "Bamboo Cicada: Chinese Folk Sound Toy", "A Chinese folk sound toy for iPhone", "Haptics · Cicada sound · Bamboo forest play"),
    ]:
        img = base.copy()
        shade = Image.new("RGBA", img.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shade)
        sd.rectangle((780, 0, SOCIAL_W, SOCIAL_H), fill=(8, 35, 25, 138))
        img = Image.alpha_composite(img, shade)
        d = ImageDraw.Draw(img)
        title_font = font(ZH_FONT if lang == "zh" else SERIF_FONT, 64 if lang == "zh" else 58)
        sub_font = font(ZH_FONT if lang == "zh" else TEXT_FONT, 50 if lang == "zh" else 44)
        cta_font = font(ZH_FONT if lang == "zh" else TEXT_FONT, 32)
        y = draw_wrapped(d, title, (860, 226), 620, title_font, (255, 245, 210), line_gap=10)
        draw_wrapped(d, subtitle, (864, y + 32), 560, sub_font, (255, 230, 165), line_gap=12)
        d.rounded_rectangle((864, 590, 1464, 674), radius=42, fill=(174, 32, 26, 236))
        d.text((906, 614), cta, font=cta_font, fill=(255, 246, 220))
        img.convert("RGB").save(WEB_ASSETS / filename)


def make_contact_sheet(images: list[Image.Image], filename: str, source_size: tuple[int, int]) -> None:
    thumb_w = 220
    thumb_h = round(thumb_w * source_size[1] / source_size[0])
    sheet = Image.new("RGB", (thumb_w * len(images), thumb_h), (245, 238, 216))
    for i, image in enumerate(images):
        sheet.paste(image.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS).convert("RGB"), (i * thumb_w, 0))
    sheet.save(PREVIEWS / filename)


def main() -> None:
    iphone_dir = SCREENSHOTS / "iphone-6.5"
    iphone_dir.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    WEB_ASSETS.mkdir(parents=True, exist_ok=True)

    specs = [
        ("zh_01_摇一摇听见夏天.png", "zh", "摇一摇，听见夏天", "竹林里的竹知了随手势旋转，发出近似鸣蝉的声音。", "game-zh.png", "中华民间声玩"),
        ("zh_02_震动反馈跟随节奏.png", "zh", "震动反馈跟随节奏", "启动、旋转、加速，每一次节奏都有轻巧触感。", "game-zh.png", "Haptic Feedback"),
        ("zh_03_中华传统民间童玩.png", "zh", "中华传统民间童玩", "竹、纸、细绳，把手上的节奏变成夏日声响。", "toy-closeup.png", "竹知了 · Bamboo Cicada"),
        ("en_01_shake-to-hear-summer.png", "en", "Shake to Hear Summer", "Spin a bamboo cicada in a living bamboo forest.", "game-zh.png", "Chinese folk sound toy"),
        ("en_02_haptics-follow-the-rhythm.png", "en", "Haptics Follow the Rhythm", "Feel start pulses, spinning motion, and beat-like vibration.", "game-zh.png", "Haptic Feedback"),
        ("en_03_a-chinese-folk-toy.png", "en", "A Chinese Folk Toy", "Bamboo, paper, and cord turn hand rhythm into sound.", "toy-closeup.png", "Bamboo Cicada"),
    ]

    generated: dict[tuple[str, str], Image.Image] = {}
    for filename, lang, title, subtitle, source_name, feature in specs:
        generated[("iphone", filename)] = make_screenshot(iphone_dir, IPHONE_SIZE, filename, lang, title, subtitle, source_name, feature)

    make_contact_sheet([generated[("iphone", s[0])] for s in specs[:3]], "iphone-6.5_zh_contact_sheet.png", IPHONE_SIZE)
    make_contact_sheet([generated[("iphone", s[0])] for s in specs[3:]], "iphone-6.5_en_contact_sheet.png", IPHONE_SIZE)

    for src, dst in [
        ("zh_01_摇一摇听见夏天.png", "screenshot-zh-shake.png"),
        ("zh_02_震动反馈跟随节奏.png", "screenshot-zh-haptics.png"),
        ("zh_03_中华传统民间童玩.png", "screenshot-zh-toy.png"),
        ("en_01_shake-to-hear-summer.png", "screenshot-en-shake.png"),
        ("en_02_haptics-follow-the-rhythm.png", "screenshot-en-haptics.png"),
        ("en_03_a-chinese-folk-toy.png", "screenshot-en-toy.png"),
    ]:
        Image.open(iphone_dir / src).save(WEB_ASSETS / dst)

    make_social_cards()


if __name__ == "__main__":
    main()
