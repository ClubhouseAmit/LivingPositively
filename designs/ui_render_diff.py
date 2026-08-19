#!/usr/bin/env python3
"""
Measure a rendered UI image into "ink bands" so a design export and a real
app screenshot can be diffed numerically instead of by eye.

Why this exists: comparing a Figma *node box* (from figma_full_dump.json)
against a *rendered screenshot* is apples-to-oranges — a text node's box
carries auto-height/line-height slack that the painted glyphs do not. Running
the SAME scan over both images makes every number ink-to-ink and therefore
comparable. See designs/figma_diff_process.md Step 5.

A "band" is a run of consecutive scanlines containing any non-background
pixel. For each band it reports, in *logical* units (physical / scale):
    y range, height, gap to the previous band, and left/right inset.

Usage:
    # app screenshot from a 3x device
    python3 designs/ui_render_diff.py shot.png --scale 3
    # figma export of a 360x800 frame rendered at 2x
    python3 designs/ui_render_diff.py design.png --scale 2 --skip-top 60
    # side-by-side gap table
    python3 designs/ui_render_diff.py design.png --scale 2 \
        --against shot.png --against-scale 3

Options:
    --skip-top N   ignore the first N logical px (status bar / notch).
    --min-h N      ignore bands thinner than N logical px (default 1.5);
                   raise it to drop 1px dividers, lower it to keep them.
    --bg x,y       sample the background colour at this physical pixel
                   instead of the default probe point.

Requires Pillow (already used elsewhere in this repo's tooling).
"""
import argparse
import sys

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    sys.exit("Pillow is required: pip3 install Pillow")


def measure(path, scale, skip_top=0, min_h=1.5, bg_probe=None, stride=2, tol=8):
    """Return [(y0, y1, x_left, x_right), ...] in physical px."""
    im = Image.open(path).convert("RGB")
    w, h = im.size
    px = im.load()
    bg = px[bg_probe[0], bg_probe[1]] if bg_probe else px[6, int(h * 0.55)]

    bands, cur = [], None
    for y in range(int(skip_top * scale), h):
        xs = [
            x
            for x in range(0, w, stride)
            if any(abs(px[x, y][i] - bg[i]) > tol for i in range(3))
        ]
        if xs and cur is None:
            cur = [y, y, min(xs), max(xs)]
        elif xs and cur:
            cur[1] = y
            cur[2] = min(cur[2], min(xs))
            cur[3] = max(cur[3], max(xs))
        elif not xs and cur:
            if cur[1] - cur[0] > min_h * scale:
                bands.append(tuple(cur))
            cur = None
    if cur and cur[1] - cur[0] > min_h * scale:
        bands.append(tuple(cur))
    return bands, w, h, bg


def report(path, scale, bands, w, h, label):
    print(f"== {label}: {path}  viewport {w / scale:.0f}x{h / scale:.0f} logical")
    print(f"  {'y range':>15s} {'h':>6s} {'gap':>6s} {'Lins':>7s} {'Rins':>7s}")
    prev = None
    rows = []
    for y0, y1, xl, xr in bands:
        gap = None if prev is None else (y0 - prev) / scale
        rows.append(gap)
        gap_s = "" if gap is None else f"{gap:6.1f}"
        print(
            f"  {y0 / scale:6.1f}-{y1 / scale:6.1f} {(y1 - y0) / scale:6.1f} "
            f"{gap_s:>6s} {xl / scale:7.1f} {(w - xr) / scale:7.1f}"
        )
        prev = y1
    return rows


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image")
    ap.add_argument("--scale", type=float, required=True)
    ap.add_argument("--skip-top", type=float, default=0)
    ap.add_argument("--min-h", type=float, default=1.5)
    ap.add_argument("--bg", type=str, default=None, help="x,y physical probe point")
    ap.add_argument("--against", type=str, default=None)
    ap.add_argument("--against-scale", type=float, default=None)
    ap.add_argument("--against-skip-top", type=float, default=0)
    a = ap.parse_args()

    bg = tuple(int(v) for v in a.bg.split(",")) if a.bg else None
    bands, w, h, _ = measure(a.image, a.scale, a.skip_top, a.min_h, bg)
    gaps_a = report(a.image, a.scale, bands, w, h, "A")

    if a.against:
        scale_b = a.against_scale or a.scale
        bands_b, wb, hb, _ = measure(a.against, scale_b, a.against_skip_top, a.min_h)
        print()
        gaps_b = report(a.against, scale_b, bands_b, wb, hb, "B")
        print()
        print("== gap deltas (B - A), by band index")
        print("   NOTE: only meaningful where both sides have the SAME element")
        print("   sequence. Different content (extra/missing rows, wrapped vs")
        print("   single-line text) shifts indices — check before trusting.")
        for i, (ga, gb) in enumerate(zip(gaps_a, gaps_b)):
            if ga is None or gb is None:
                continue
            print(f"   band {i:2d}:  A {ga:6.1f}   B {gb:6.1f}   delta {gb - ga:+6.1f}")


if __name__ == "__main__":
    main()
