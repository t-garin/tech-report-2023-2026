"""Check figures in ../imgs for colorblind friendliness.

Simulates deuteranopia ("d"), protanopia ("p") and tritanopia ("t") on every
PNG figure (simplified LMS color-vision simulation via daltonize), saves the
simulated images to cvd_out/, and flags figures where the dominant colors
become confusable (pairwise CIELAB distance below CONFUSABLE_DE).

Usage:
    uv run --isolated --with daltonize --with setuptools python colorblind_check.py
    uv run --isolated --with daltonize --with setuptools python colorblind_check.py --selftest
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image
from daltonize.daltonize import simulate

IMGS = Path(__file__).resolve().parent.parent / "imgs"
OUT = Path(__file__).resolve().parent / "cvd_out"
CVD = {"d": "deuteranopia", "p": "protanopia", "t": "tritanopia"}
CONFUSABLE_DE = 30.0  # pairwise CIELAB ΔE below this is likely confusable
NORMAL_DE = 40.0  # pairwise CIELAB ΔE above this is clearly distinct in normal vision
PALETTE_SIZE = 8  # most frequent colors kept per figure
PALETTE_MIN_FRACTION = 0.01  # ignore colors covering less than 1% of pixels


def confusable(de_normal: float, de_cvd: float) -> bool:
    """Clearly distinct in normal vision, but not under the simulated CVD."""
    return de_normal > NORMAL_DE and de_cvd < CONFUSABLE_DE


def load(path: Path) -> np.ndarray:
    """Load an image as float RGB in [0, 1], composited on white."""
    img = Image.open(path)
    if img.mode in ("RGBA", "LA") or "transparency" in img.info:
        img = Image.alpha_composite(
            Image.new("RGBA", img.size, (255, 255, 255, 255)), img.convert("RGBA")
        )
    return np.asarray(img.convert("RGB"), dtype=float) / 255.0


def srgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    """sRGB in [0, 1] (..., 3) -> CIELAB (D65)."""
    rgb = np.asarray(rgb, dtype=float)
    linear = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    xyz = np.stack(
        [
            linear @ np.array([0.4124564, 0.3575761, 0.1804375]),
            linear @ np.array([0.2126729, 0.7151522, 0.0721750]),
            linear @ np.array([0.0193339, 0.1191920, 0.9503041]),
        ],
        axis=-1,
    )
    xyz = xyz / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > (6 / 29) ** 3, xyz ** (1 / 3), xyz / (3 * (6 / 29) ** 2) + 4 / 29)
    return np.stack(
        [
            116 * f[..., 1] - 16,
            500 * (f[..., 0] - f[..., 1]),
            200 * (f[..., 1] - f[..., 2]),
        ],
        axis=-1,
    )


def delta_e(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.linalg.norm(srgb_to_lab(a) - srgb_to_lab(b)))


def palette(arr: np.ndarray) -> list[np.ndarray]:
    """The most frequent colors of an image (32 levels per channel)."""
    q = (arr * 31).round().astype(int).reshape(-1, 3)
    idx = q[:, 0] * 1024 + q[:, 1] * 32 + q[:, 2]
    counts = np.bincount(idx, minlength=32**3)
    floor = PALETTE_MIN_FRACTION * q.shape[0]
    top = np.argpartition(counts, -PALETTE_SIZE)[-PALETTE_SIZE:]
    top = top[counts[top] >= floor]
    top = top[np.argsort(-counts[top])]
    return [
        (np.array([i // 1024, (i // 32) % 32, i % 32]) + 0.5) / 31.0
        for i in top
    ]


def check_figure(path: Path, lines: list[str]) -> None:
    arr = load(path)
    cols = palette(arr)
    lines.append(f"{path.name}: {len(cols)} dominant colors")
    for cvd, name in CVD.items():
        sim = simulate(arr, cvd)
        Image.fromarray((sim * 255).round().astype(np.uint8)).save(
            OUT / f"{path.stem}_{cvd}.png"
        )
        sim_cols = [simulate(c[None, None, :], cvd)[0, 0] for c in cols]
        flags = [
            (de_cvd, i, j)
            for i, c in enumerate(sim_cols)
            for j, c2 in enumerate(sim_cols)
            if i < j
            for de_cvd in [delta_e(c, c2)]
            if confusable(delta_e(cols[i], cols[j]), de_cvd)
        ]
        if flags:
            lines.append(
                f"  {name:12s} ⚠ "
                + "; ".join(
                    f"ΔE {de:4.1f}: ({cols[i].round(2)}) vs ({cols[j].round(2)})"
                    for de, i, j in sorted(flags)
                )
            )
        else:
            lines.append(f"  {name:12s} ok")


def selftest() -> None:
    """Sanity checks: pure red/green collapse under deuteranopia."""
    red = np.array([1.0, 0.0, 0.0])
    green = np.array([0.0, 1.0, 0.0])
    assert abs(delta_e(red, green) - 170.6) < 5, "LAB conversion wrong"
    sim_red = simulate(red[None, None, :], "d")[0, 0]
    sim_green = simulate(green[None, None, :], "d")[0, 0]
    assert confusable(delta_e(red, green), delta_e(sim_red, sim_green)), "red/green not flagged"
    print(f"selftest ok: red/green ΔE {delta_e(red, green):.1f} -> "
          f"{delta_e(sim_red, sim_green):.1f} under deuteranopia")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--selftest", action="store_true")
    args = parser.parse_args()
    if args.selftest:
        selftest()
        return

    OUT.mkdir(exist_ok=True)
    lines = [f"Colorblindness check of {IMGS} ({OUT})", ""]
    for path in sorted(IMGS.glob("*.png")):
        check_figure(path, lines)
        lines.append("")
    summary = OUT / "summary.txt"
    summary.write_text("\n".join(lines))
    print("\n".join(lines))
    print(f"summary written to {summary}")


if __name__ == "__main__":
    main()
