#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parent
SOURCE = ROOT / "source-screenshots"
OUT = ROOT / "screenshots" / "iphone-17-pro-max"
PREVIEWS = ROOT / "previews"
WEB_ASSETS = PROJECT / "zhuzhiliao" / "assets"

PHONE_W, PHONE_H = 1320, 2868
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
    d.rounded_rectangle((x, y, x + w, y + h), radius=78, fill=(29, 28, 24), outline=(226, 209, 168), width=8)
    inset = 24
    screen_box = (x + inset, y + inset, w - inset * 2, h - inset * 2)
    screen = cover(screenshot, (screen_box[2], screen_box[3])).convert("RGBA")
    paste_rounded(base, screen, (screen_box[0], screen_box[1]), 58)
    island_w, island_h = round(w * 0.34), 42
    d.rounded_rectangle(
        (x + (w - island_w) // 2, y + 42, x + (w + island_w) // 2, y + 42 + island_h),
        radius=24,
        fill=(5, 5, 5, 235),
    )


def make_screenshot(filename: str, lang: str, title: str, subtitle: str, source_name: str, accent: str, feature: str) -> Image.Image:
    source = Image.open(SOURCE / source_name)
    bg = cover(source, (PHONE_W, PHONE_H)).filter(ImageFilter.GaussianBlur(20))
    bg = ImageEnhance.Brightness(bg).enhance(0.58).convert("RGBA")
    overlay = gradient((PHONE_W, PHONE_H), (6, 48, 31), (246, 205, 105))
    bg = Image.blend(bg, overlay, 0.32)
    d = ImageDraw.Draw(bg)

    title_font = font(ZH_FONT if lang == "zh" else SERIF_FONT, 98 if lang == "zh" else 92)
    subtitle_font = font(ZH_FONT if lang == "zh" else TEXT_FONT, 42)
    feature_font = font(ZH_FONT if lang == "zh" else TEXT_FONT, 32)

    d.text((92, 112), "Bamboo Cicada: Chinese Folk Sound Toy", font=font(SERIF_FONT, 32), fill=(255, 239, 184, 235))
    y = draw_wrapped(d, title, (88, 184), 980, title_font, (255, 246, 220), line_gap=20)
    y = draw_wrapped(d, subtitle, (92, y + 26), 900, subtitle_font, (255, 235, 184), line_gap=10)

    phone_h = 1848
    phone_w = round(phone_h * 1320 / 2868)
    draw_phone_frame(bg, source, ((PHONE_W - phone_w) // 2, 750, phone_w, phone_h))

    pill_y = 2630
    d.rounded_rectangle((88, pill_y, PHONE_W - 88, pill_y + 104), radius=52, fill=(255, 246, 220, 232))
    d.text((134, pill_y + 30), feature, font=feature_font, fill=(96, 35, 18))

    for i in range(3):
        r = 46 + i * 34
        d.ellipse((PHONE_W - 190 - r, pill_y + 52 - r, PHONE_W - 190 + r, pill_y + 52 + r), outline=(170, 34, 26, 80 - i * 20), width=4)
    d.ellipse((PHONE_W - 208, pill_y + 34, PHONE_W - 172, pill_y + 70), fill=(174, 32, 26))

    bg.save(OUT / filename)
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
        img.save(WEB_ASSETS / filename)


def make_contact_sheet(images: list[Image.Image], filename: str) -> None:
    thumb_w = 220
    thumb_h = round(thumb_w * PHONE_H / PHONE_W)
    sheet = Image.new("RGB", (thumb_w * len(images), thumb_h), (245, 238, 216))
    for i, image in enumerate(images):
        sheet.paste(image.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS).convert("RGB"), (i * thumb_w, 0))
    sheet.save(PREVIEWS / filename)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    WEB_ASSETS.mkdir(parents=True, exist_ok=True)

    zh = [
        make_screenshot("zh_01_摇一摇听见夏天.png", "zh", "摇一摇，听见夏天", "竹林里的竹知了随手势旋转，发出近似鸣蝉的声音。", "game-zh.png", "red", "中华民间声玩"),
        make_screenshot("zh_02_震动反馈跟随节奏.png", "zh", "震动反馈跟随节奏", "启动、旋转、加速，每一次节奏都有轻巧触感。", "game-zh.png", "red", "Haptic Feedback"),
        make_screenshot("zh_03_中华传统民间童玩.png", "zh", "中华传统民间童玩", "竹、纸、细绳，把手上的节奏变成夏日声响。", "toy-closeup.png", "red", "竹知了 · Bamboo Cicada"),
        make_screenshot("zh_04_卷轴中的文化介绍.png", "zh", "卷轴中的文化介绍", "了解竹知了的材料、玩法和朴素巧思。", "intro-zh.png", "red", "民间童玩介绍"),
        make_screenshot("zh_05_中英双语体验.png", "zh", "中英双语体验", "给孩子、课堂与文化展示一个轻巧入口。", "intro-en.png", "red", "中文 / English"),
    ]
    en = [
        make_screenshot("en_01_shake-to-hear-summer.png", "en", "Shake to Hear Summer", "Spin a bamboo cicada in a living bamboo forest.", "game-zh.png", "red", "Chinese folk sound toy"),
        make_screenshot("en_02_haptics-follow-the-rhythm.png", "en", "Haptics Follow the Rhythm", "Feel start pulses, spinning motion, and beat-like vibration.", "game-zh.png", "red", "Haptic Feedback"),
        make_screenshot("en_03_a-chinese-folk-toy.png", "en", "A Chinese Folk Toy", "Bamboo, paper, and cord turn hand rhythm into sound.", "toy-closeup.png", "red", "Bamboo Cicada"),
        make_screenshot("en_04_scroll-inspired-introduction.png", "en", "Scroll-Inspired Introduction", "Learn the materials, play pattern, and folk background.", "intro-en.png", "red", "Traditional toy story"),
        make_screenshot("en_05_bilingual-experience.png", "en", "Bilingual Experience", "A small cultural moment for families, classrooms, and calm play.", "intro-zh.png", "red", "Chinese / English"),
    ]
    make_contact_sheet(zh, "iphone-17-pro-max_zh_contact_sheet.png")
    make_contact_sheet(en, "iphone-17-pro-max_en_contact_sheet.png")

    for src, dst in [
        ("zh_01_摇一摇听见夏天.png", "screenshot-zh-shake.png"),
        ("zh_02_震动反馈跟随节奏.png", "screenshot-zh-haptics.png"),
        ("zh_03_中华传统民间童玩.png", "screenshot-zh-toy.png"),
        ("en_01_shake-to-hear-summer.png", "screenshot-en-shake.png"),
        ("en_02_haptics-follow-the-rhythm.png", "screenshot-en-haptics.png"),
        ("en_03_a-chinese-folk-toy.png", "screenshot-en-toy.png"),
    ]:
        Image.open(OUT / src).save(WEB_ASSETS / dst)

    make_social_cards()


if __name__ == "__main__":
    main()
