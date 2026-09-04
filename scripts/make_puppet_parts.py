"""Slice the shared paper-cutout dog into registered fill / line / spot / eye PNGs."""

from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "scripts" / "puppet-style-ref.png"
OUT = ROOT / "DogCompanion" / "DogCompanion" / "Assets.xcassets"


def write_png(path: Path, image: Image.Image) -> None:
    image = image.convert("RGBA")
    width, height = image.size
    raw = b"".join(b"\x00" + image.crop((0, y, width, y + 1)).tobytes() for y in range(height))

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    payload = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )
    path.write_bytes(payload)


def imageset(name: str, image: Image.Image) -> None:
    folder = OUT / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    png_name = f"{name}.png"
    write_png(folder / png_name, image)
    (folder / "Contents.json").write_text(
        """{
  "images" : [
    { "filename" : "%s", "idiom" : "universal", "scale" : "1x" },
    { "idiom" : "universal", "scale" : "2x" },
    { "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "template-rendering-intent" : "original" }
}
"""
        % png_name,
        encoding="utf-8",
    )


def pixels(image: Image.Image) -> list[tuple[int, int, int, int]]:
    return list(image.getdata())


def opaque_bounds(data: list[tuple[int, int, int, int]], width: int, height: int) -> tuple[int, int, int, int]:
    min_x, min_y, max_x, max_y = width, height, 0, 0
    for y in range(height):
        row = y * width
        for x in range(width):
            if data[row + x][3] > 24:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    return min_x, min_y, max_x, max_y


def luminance(r: int, g: int, b: int) -> float:
    return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0


def part_weight(part: str, nx: float, ny: float) -> float:
    # Side-sitting dog facing right: tail left, head upper-right, legs bottom.
    if part == "tail":
        return max(0.0, 1.15 - nx * 2.4 - abs(ny - 0.48) * 0.6)
    if part == "head":
        return max(0.0, 1.2 - math.hypot(nx - 0.72, ny - 0.22) * 2.1)
    if part == "nearEar":
        return max(0.0, 1.15 - math.hypot(nx - 0.58, ny - 0.10) * 3.4)
    if part == "farEar":
        return max(0.0, 1.15 - math.hypot(nx - 0.78, ny - 0.08) * 3.6)
    if part == "frontLeg":
        return max(0.0, 1.2 - math.hypot(nx - 0.70, ny - 0.86) * 2.6)
    if part == "backLeg":
        return max(0.0, 1.2 - math.hypot(nx - 0.42, ny - 0.86) * 2.5)
    if part == "belly":
        return max(0.0, 1.1 - math.hypot(nx - 0.58, ny - 0.62) * 2.8)
    if part == "eye":
        return max(0.0, 1.3 - math.hypot(nx - 0.80, ny - 0.24) * 8.0)
    if part == "body":
        return max(0.0, 0.85 - abs(nx - 0.52) * 0.5 - abs(ny - 0.55) * 0.35)
    return 0.0


def winner(nx: float, ny: float) -> str:
    parts = ("tail", "farEar", "nearEar", "eye", "head", "frontLeg", "backLeg", "belly", "body")
    best = "body"
    score = -1.0
    for part in parts:
        value = part_weight(part, nx, ny)
        if value > score:
            score = value
            best = part
    return best


def knockout_paper(src: Image.Image) -> Image.Image:
    src = src.convert("RGBA")
    width, height = src.size
    data = pixels(src)
    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    dest = out.load()
    for y in range(height):
        for x in range(width):
            r, g, b, _ = data[y * width + x]
            if r > 236 and g > 236 and b > 236:
                continue
            paper = min(r, g, b)
            if paper > 220 and abs(r - g) < 12 and abs(g - b) < 12:
                continue
            dest[x, y] = (r, g, b, 255)
    return out


def extract_layers(src: Image.Image) -> dict[str, Image.Image]:
    src = src.convert("RGBA")
    width, height = src.size
    data = pixels(src)
    min_x, min_y, max_x, max_y = opaque_bounds(data, width, height)
    box_w = max(1, max_x - min_x)
    box_h = max(1, max_y - min_y)

    fills: dict[str, Image.Image] = {}
    lines: dict[str, Image.Image] = {}
    names = ("tail", "backLeg", "body", "belly", "frontLeg", "farEar", "nearEar", "head", "eye")
    for name in names:
        fills[name] = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        lines[name] = Image.new("RGBA", (width, height), (0, 0, 0, 0))

    fill_px = {name: fills[name].load() for name in names}
    line_px = {name: lines[name].load() for name in names}
    spots = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    spots_px = spots.load()

    for y in range(height):
        for x in range(width):
            r, g, b, a = data[y * width + x]
            if a < 24:
                continue
            nx = (x - min_x) / box_w
            ny = (y - min_y) / box_h
            part = winner(nx, ny)
            lum = luminance(r, g, b)
            is_line = lum < 0.28 and a > 80
            if part == "eye" or (part == "head" and lum < 0.22 and nx > 0.68 and 0.16 < ny < 0.34):
                fill_px["eye"][x, y] = (255, 255, 255, a)
                if lum < 0.45:
                    line_px["eye"][x, y] = (20, 16, 12, a)
                continue
            if is_line:
                line_px[part][x, y] = (28, 22, 16, min(255, a + 40))
            else:
                fill_px[part][x, y] = (255, 255, 255, a)
            # Cream chest as extra belly coverage.
            if part in {"body", "belly"} and lum > 0.78 and g > r - 10:
                fill_px["belly"][x, y] = (255, 255, 255, a)
            # Spot mask: darker blobs on the back, not the cream belly.
            if part in {"body", "tail", "head"} and 0.32 < lum < 0.62 and nx < 0.7:
                if ((x * 13 + y * 7) % 47) < 9:
                    spots_px[x, y] = (255, 255, 255, int(a * 0.85))

    # Soft overlap at joints so rotations do not flash a hole.
    body = fills["body"]
    for donor, extra in (("head", 0.18), ("frontLeg", 0.14), ("backLeg", 0.14), ("tail", 0.12)):
        dilate_into(fills[donor], body, extra)

    layers = {f"puppet_fill_{name}": fills[name] for name in names}
    layers.update({f"puppet_line_{name}": lines[name] for name in names})
    layers["puppet_spots"] = spots
    return layers


def dilate_into(part: Image.Image, body: Image.Image, amount: float) -> None:
    width, height = part.size
    part_px = part.load()
    body_px = body.load()
    radius = max(2, int(min(width, height) * amount * 0.04))
    opaque = [
        (x, y)
        for y in range(0, height, 2)
        for x in range(0, width, 2)
        if part_px[x, y][3] > 40
    ]
    for x, y in opaque:
        for dy in range(-radius, radius + 1):
            yy = y + dy
            if yy < 0 or yy >= height:
                continue
            for dx in range(-radius, radius + 1):
                xx = x + dx
                if xx < 0 or xx >= width:
                    continue
                if dx * dx + dy * dy > radius * radius:
                    continue
                if part_px[xx, yy][3] < 20 and body_px[xx, yy][3] > 40:
                    a = body_px[xx, yy][3] // 2
                    part_px[xx, yy] = (255, 255, 255, a)


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"missing source {SRC}")
    src = knockout_paper(Image.open(SRC))
    width, height = src.size
    side = max(width, height)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(src, ((side - width) // 2, (side - height) // 2), src)
    canvas = canvas.resize((512, 512), Image.Resampling.LANCZOS)

    layers = extract_layers(canvas)
    preview = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    order = [
        "puppet_fill_tail",
        "puppet_line_tail",
        "puppet_fill_backLeg",
        "puppet_line_backLeg",
        "puppet_fill_body",
        "puppet_fill_belly",
        "puppet_spots",
        "puppet_line_body",
        "puppet_fill_frontLeg",
        "puppet_line_frontLeg",
        "puppet_fill_farEar",
        "puppet_line_farEar",
        "puppet_fill_head",
        "puppet_fill_nearEar",
        "puppet_line_nearEar",
        "puppet_line_head",
        "puppet_fill_eye",
        "puppet_line_eye",
    ]
    tinted_body = layers["puppet_fill_body"].copy()
    tinted_body = tint(tinted_body, (196, 122, 64, 255))
    preview.alpha_composite(tinted_body)
    for name in order:
        layer = layers[name]
        if name.startswith("puppet_fill_") and name != "puppet_fill_body":
            color = (232, 214, 186, 255) if "belly" in name or "eye" in name else (196, 122, 64, 255)
            preview.alpha_composite(tint(layer, color))
        else:
            preview.alpha_composite(layer)

    for name, image in layers.items():
        imageset(name, image)
    imageset("puppet_preview", preview)
    print(f"wrote {len(layers)} layers to {OUT}")


def tint(image: Image.Image, color: tuple[int, int, int, int]) -> Image.Image:
    out = image.copy()
    px = out.load()
    width, height = out.size
    cr, cg, cb, _ = color
    for y in range(height):
        for x in range(width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (cr, cg, cb, a)
    return out


if __name__ == "__main__":
    main()
