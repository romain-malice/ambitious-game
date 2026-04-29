#!/usr/bin/env python3
"""
image_to_mif.py — Convert a JPG or PNG image to a .mif file using a 16-color palette.

Each pixel is mapped to the closest color in the palette (RGB444, 4-bit index).
The output MIF encodes one pixel index per address, line by line (row-major order).

Usage:
    python image_to_mif.py <input_image> [output.mif]

If no output path is given, the output is placed next to the input with a .mif extension.
"""

import sys
import os
import math
from PIL import Image

# ---------------------------------------------------------------------------
# Palette: 16 entries parsed from palette.mif (RGB444 → scaled to 0-255)
# Index → (R, G, B) in 0-255 range
# ---------------------------------------------------------------------------
PALETTE = {
    0x0: (  0,   0,   0),
    0x1: ( 34,  51,  85),
    0x2: (136,  34,  85),
    0x3: (  0, 136,  85),
    0x4: (187,  85,  51),
    0x5: (102,  85,  85),
    0x6: (204, 204, 204),
    0x7: (255, 255, 255),
    0x8: (255,   0,  85),
    0x9: (255, 170,   0),
    0xA: (255, 255,  34),
    0xB: (  0, 238,  51),
    0xC: ( 51, 187, 255),
    0xD: (136, 119, 170),
    0xE: (255, 119, 187),
    0xF: (255, 204, 170),
}


def closest_palette_index(r: int, g: int, b: int) -> int:
    """Return the palette index whose color is closest to (r, g, b) in RGB space."""
    best_idx = 0
    best_dist = float('inf')
    for idx, (pr, pg, pb) in PALETTE.items():
        dist = (r - pr) ** 2 + (g - pg) ** 2 + (b - pb) ** 2
        if dist < best_dist:
            best_dist = dist
            best_idx = idx
            if dist == 0:
                break  # exact match, no need to continue
    return best_idx


def image_to_mif(input_path: str, output_path: str) -> None:
    img = Image.open(input_path).convert("RGB")
    img = img.resize((200, 150), Image.LANCZOS)
    width, height = img.size  # always 200x150
    pixels = img.load()
    total_pixels = width * height

    # Number of address bits needed (minimum 1)
    addr_bits = max(1, math.ceil(math.log2(total_pixels))) if total_pixels > 1 else 1

    print(f"Image size : {width} x {height} = {total_pixels} pixels")
    print(f"Output     : {output_path}")

    with open(output_path, "w") as f:
        f.write(f"-- Converted from: {os.path.basename(input_path)}\n")
        f.write(f"-- Image size: {width}x{height} pixels, row-major order\n")
        f.write(f"-- Color depth: 4-bit palette index (16 colors)\n\n")
        f.write(f"DEPTH = {total_pixels};\n")
        f.write(f"WIDTH = 4;\n\n")
        f.write(f"ADDRESS_RADIX = HEX;\n")
        f.write(f"DATA_RADIX = HEX;\n\n")
        f.write(f"CONTENT BEGIN\n")

        addr = 0
        for y in range(height):
            for x in range(width):
                r, g, b = pixels[x, y]
                idx = closest_palette_index(r, g, b)
                f.write(f"    {addr:X} : {idx:X};\n")
                addr += 1

        f.write("END;\n")

    print(f"Done. Written {total_pixels} pixel entries.")


def main():
    if len(sys.argv) < 2:
        print("Usage: python image_to_mif.py <input_image> [output.mif]")
        sys.exit(1)

    input_path = sys.argv[1]

    if not os.path.isfile(input_path):
        print(f"Error: file not found: {input_path}")
        sys.exit(1)

    ext = os.path.splitext(input_path)[1].lower()
    if ext not in (".jpg", ".jpeg", ".png"):
        print(f"Warning: expected .jpg or .png, got '{ext}'. Proceeding anyway.")

    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        base = os.path.splitext(input_path)[0]
        output_path = base + ".mif"

    image_to_mif(input_path, output_path)


if __name__ == "__main__":
    main()
