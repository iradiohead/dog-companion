"""Replay CutoutImageProcessor.chromaKeyCutout on bundled hand-drawn PNGs.

Run from repo root:
    python scripts/simulate_chroma_cutout.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent / "cutout-sim"


def luma(r: float, g: float, b: float) -> float:
    return 0.299 * r + 0.587 * g + 0.114 * b


def chroma(r: float, g: float, b: float) -> float:
    return max(r, g, b) - min(r, g, b)


def warmth(r: float, g: float, b: float) -> float:
    return r - b


def estimate_background(px: list, w: int, h: int) -> tuple[float, float, float]:
    sample = max(4, min(w, h) // 16)
    corners = [
        (0, 0),
        (max(0, w - sample), 0),
        (0, max(0, h - sample)),
        (max(0, w - sample), max(0, h - sample)),
    ]
    tr = tg = tb = n = 0.0
    for ox, oy in corners:
        for y in range(oy, min(oy + sample, h)):
            for x in range(ox, min(ox + sample, w)):
                r, g, b, _ = px[y * w + x]
                tr += r
                tg += g
                tb += b
                n += 1
    return (tr / n, tg / n, tb / n)


def current_is_subject(p) -> bool:
    r, g, b, _ = p
    if warmth(r, g, b) >= 14 or chroma(r, g, b) > 18:
        return True
    return luma(r, g, b) < 205


def current_is_paper(p, minimum_luma: float) -> bool:
    if current_is_subject(p):
        return False
    return luma(p[0], p[1], p[2]) >= minimum_luma


def relative_is_paper(p, bg, max_dist: float = 20) -> bool:
    r, g, b, _ = p
    dr, dg, db = r - bg[0], g - bg[1], b - bg[2]
    if dr * dr + dg * dg + db * db > max_dist * max_dist:
        return False
    if luma(r, g, b) < luma(*bg) - 12:
        return False
    if chroma(r, g, b) > chroma(*bg) + 14:
        return False
    return True


def relative_is_subject(p, bg) -> bool:
    r, g, b, _ = p
    if luma(r, g, b) < luma(*bg) - 8:
        return True
    return chroma(r, g, b) > chroma(*bg) + 12


def flood(px, w, h, predicate):
    out = [list(p) for p in px]
    visited = [False] * (w * h)
    q = [0, w - 1, (h - 1) * w, h * w - 1]
    while q:
        i = q.pop()
        if visited[i]:
            continue
        visited[i] = True
        if not predicate(px[i]):
            continue
        out[i][0] = out[i][1] = out[i][2] = out[i][3] = 0
        x, y = i % w, i // w
        if x > 0:
            q.append(i - 1)
        if x + 1 < w:
            q.append(i + 1)
        if y > 0:
            q.append(i - w)
        if y + 1 < h:
            q.append(i + w)
    return out


def restore(original, pixels, keep):
    for i, src in enumerate(original):
        if keep(src):
            pixels[i] = [src[0], src[1], src[2], 255]


def peel(pixels, w, h, keep_subject, passes=3):
    for _ in range(passes):
        to_clear = []
        for i, p in enumerate(pixels):
            if p[3] <= 12 or keep_subject(p):
                continue
            x, y = i % w, i // w
            touch = x == 0 or y == 0 or x == w - 1 or y == h - 1
            if not touch:
                if (
                    pixels[i - 1][3] <= 12
                    or pixels[i + 1][3] <= 12
                    or pixels[i - w][3] <= 12
                    or pixels[i + w][3] <= 12
                ):
                    touch = True
            if touch:
                to_clear.append(i)
        for i in to_clear:
            pixels[i] = [0, 0, 0, 0]


def drop_islands(pixels, w, h):
    visited = [False] * (w * h)
    islands = []
    largest = 0
    for start in range(w * h):
        if visited[start] or pixels[start][3] <= 12:
            continue
        stack = [start]
        island = []
        while stack:
            i = stack.pop()
            if visited[i]:
                continue
            visited[i] = True
            if pixels[i][3] <= 12:
                continue
            island.append(i)
            x, y = i % w, i // w
            if x > 0:
                stack.append(i - 1)
            if x + 1 < w:
                stack.append(i + 1)
            if y > 0:
                stack.append(i - w)
            if y + 1 < h:
                stack.append(i + w)
        if island:
            islands.append(island)
            largest = max(largest, len(island))
    min_keep = max(64, largest // 12)
    for island in islands:
        if len(island) < min_keep:
            for i in island:
                pixels[i] = [0, 0, 0, 0]


def trim(pixels, w, h, padding=8):
    xs, ys = [], []
    for i, p in enumerate(pixels):
        if p[3] > 12:
            xs.append(i % w)
            ys.append(i // w)
    if not xs:
        return None
    minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)
    minx = max(0, minx - padding)
    miny = max(0, miny - padding)
    maxx = min(w - 1, maxx + padding)
    maxy = min(h - 1, maxy + padding)
    tw, th = maxx - minx + 1, maxy - miny + 1
    out = []
    for y in range(miny, maxy + 1):
        for x in range(minx, maxx + 1):
            out.append(pixels[y * w + x])
    return out, tw, th


def solidify(pixels):
    for p in pixels:
        a = p[3]
        if a > 4:
            p[3] = 255
        else:
            p[0] = p[1] = p[2] = p[3] = 0


def run_current(px, w, h):
    original = [tuple(p) for p in px]

    def apply(min_luma):
        flooded = flood(original, w, h, lambda p: current_is_paper(p, min_luma))
        restore(original, flooded, current_is_subject)
        return flooded

    pixels = apply(220)
    cleared = sum(1 for p in pixels if p[3] <= 12) / (w * h)
    if cleared < 0.05:
        pixels = apply(205)
        cleared = sum(1 for p in pixels if p[3] <= 12) / (w * h)
    peel(pixels, w, h, current_is_subject)
    drop_islands(pixels, w, h)
    trimmed = trim(pixels, w, h)
    if trimmed is None:
        return None, cleared
    out, tw, th = trimmed
    solidify(out)
    return (out, tw, th), cleared


def run_relative(px, w, h):
    original = [tuple(p) for p in px]
    bg = estimate_background(original, w, h)
    pixels = None
    cleared = 0.0
    for distance in (20, 32, 44):
        pixels = flood(original, w, h, lambda p, d=distance: relative_is_paper(p, bg, d))
        restore(original, pixels, lambda p: relative_is_subject(p, bg))
        cleared = sum(1 for p in pixels if p[3] <= 12) / (w * h)
        if cleared >= 0.08:
            break
    peel(pixels, w, h, lambda p: relative_is_subject(p, bg))
    drop_islands(pixels, w, h)
    trimmed = trim(pixels, w, h)
    if trimmed is None:
        return None, cleared, bg
    out, tw, th = trimmed
    solidify(out)
    return (out, tw, th), cleared, bg


def simulate_device_warm(px):
    warmed = []
    for r, g, b, a in px:
        if luma(r, g, b) >= 235 and chroma(r, g, b) <= 20:
            nr = min(255, r)
            ng = max(0, g - 6)
            nb = max(0, b - 20)
            warmed.append((nr, ng, nb, a))
        else:
            warmed.append((r, g, b, a))
    return warmed


def save_rgba(pixels, w, h, path: Path, checker=True):
    img = Image.new("RGBA", (w, h))
    img.putdata([tuple(p) for p in pixels])
    if checker:
        bg = Image.new("RGBA", (w, h))
        cell = 16
        for y in range(h):
            for x in range(w):
                light = ((x // cell) + (y // cell)) % 2 == 0
                c = (210, 210, 210, 255) if light else (150, 150, 150, 255)
                bg.putpixel((x, y), c)
        img = Image.alpha_composite(bg, img)
    img.save(path)


def summarize(label, result, w, h):
    if result[0] is None:
        print(f"{label}: FAILED trim, cleared_ratio={result[1]:.4f}")
        return
    (pixels, tw, th), cleared = result[0], result[1]
    opaque = sum(1 for p in pixels if p[3] > 200)
    print(
        f"{label}: canvas {w}x{h} -> {tw}x{th}, "
        f"cleared_before_trim={cleared:.3f}, opaque={opaque}, "
        f"opaque_ratio={opaque / (tw * th):.3f}"
    )


def main():
    folder = ROOT / "resource" / "金毛"
    src = next(folder.glob("hand-drawn-sit-*.png"))
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    px = list(img.getdata())
    OUT.mkdir(parents=True, exist_ok=True)

    print("source", src.name, w, h)
    bg = estimate_background(px, w, h)
    print("corner bg", tuple(round(v, 2) for v in bg), "warmth", round(warmth(*bg), 2))

    current = run_current(px, w, h)
    summarize("current / file", current, w, h)

    relative = run_relative(px, w, h)
    summarize("relative / file", (relative[0], relative[1]), w, h)
    print("relative used bg", tuple(round(v, 2) for v in relative[2]))

    warmed = simulate_device_warm(px)
    wbg = estimate_background(warmed, w, h)
    print(
        "device-warm corner bg",
        tuple(round(v, 2) for v in wbg),
        "warmth",
        round(warmth(*wbg), 2),
        "subject_corners",
        current_is_subject(warmed[0]),
    )
    current_w = run_current(warmed, w, h)
    summarize("current / device-warm", current_w, w, h)
    relative_w = run_relative(warmed, w, h)
    summarize("relative / device-warm", (relative_w[0], relative_w[1]), w, h)

    if current[0]:
        save_rgba(*current[0], OUT / "current-file.png")
    if relative[0]:
        save_rgba(*relative[0], OUT / "relative-file.png")
    if current_w[0]:
        save_rgba(*current_w[0], OUT / "current-device-warm.png")
    else:
        print("current / device-warm produced no cutout (this is the device failure)")
    if relative_w[0]:
        save_rgba(*relative_w[0], OUT / "relative-device-warm.png")

    print("wrote", OUT)


if __name__ == "__main__":
    main()
