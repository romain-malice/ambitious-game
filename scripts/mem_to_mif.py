#!/usr/bin/env python3
"""
mem_to_mif.py — Convert Verilog .mem files to Altera/Intel .mif files.

.mem format  : plain hex values, one per line (optionally with @address markers)
.mif format  : Memory Initialization File used by Quartus / ModelSim

Usage:
    python mem_to_mif.py input.mem output.mif [--depth N] [--width N]

If --depth / --width are omitted they are inferred from the file contents.
"""

import argparse
import math
import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

def parse_mem(path: Path) -> dict[int, str]:
    """
    Read a .mem file and return {address: hex_string} (no leading zeros stripped).

    Supports:
      - Blank lines and // comments
      - @ADDR  address markers (hex)
      - One hex word per line
    """
    data: dict[int, str] = {}
    addr = 0

    with path.open() as fh:
        for raw in fh:
            line = raw.split("//")[0].strip()   # strip comments
            if not line:
                continue

            if line.startswith("@"):            # address marker
                addr = int(line[1:], 16)
                continue

            # Each space-separated token on the line is one word
            for token in line.split():
                if not re.fullmatch(r"[0-9A-Fa-f_]+", token):
                    print(f"[warn] Skipping unrecognised token: {token!r}", file=sys.stderr)
                    continue
                data[addr] = token.replace("_", "")
                addr += 1

    return data


# ---------------------------------------------------------------------------
# Writer
# ---------------------------------------------------------------------------

def write_mif(data: dict[int, str], out_path: Path, depth: int, width: int) -> None:
    """Write an Altera .mif file for the given data dictionary."""

    # Pad every value to the correct number of hex digits
    hex_digits = math.ceil(width / 4)

    with out_path.open("w") as fh:
        fh.write(f"DEPTH = {depth};\n")
        fh.write(f"WIDTH = {width};\n")
        fh.write("\n")
        fh.write("ADDRESS_RADIX = HEX;\n")
        fh.write("DATA_RADIX = HEX;\n")
        fh.write("\n")
        fh.write("CONTENT BEGIN\n")

        for addr in range(depth):
            value = data.get(addr, "0")
            padded = value.zfill(hex_digits)
            addr_field = format(addr, "X")
            fh.write(f"    {addr_field} : {padded};\n")

        fh.write("END;\n")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def infer_width(data: dict[int, str]) -> int:
    """Infer bit-width from the longest hex value present."""
    if not data:
        return 8
    max_hex_len = max(len(v) for v in data.values())
    bits = max_hex_len * 4
    # Round up to the nearest power-of-two (common widths: 8, 16, 32, 64 …)
    return max(8, 1 << math.ceil(math.log2(bits))) if bits > 0 else 8


def infer_depth(data: dict[int, str]) -> int:
    """Infer memory depth as the next power-of-two above the highest address."""
    if not data:
        return 256
    max_addr = max(data.keys())
    return 1 << math.ceil(math.log2(max_addr + 1)) if max_addr > 0 else 256


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert a Verilog .mem file to an Altera .mif file."
    )
    parser.add_argument("input",  type=Path, help="Source .mem file")
    parser.add_argument("output", type=Path, nargs="?",
                        help="Destination .mif file (default: same name as input)")
    parser.add_argument("--depth", type=int, default=None,
                        help="Memory depth in words (default: inferred)")
    parser.add_argument("--width", type=int, default=None,
                        help="Word width in bits  (default: inferred)")
    args = parser.parse_args()

    if not args.input.exists():
        sys.exit(f"Error: input file '{args.input}' not found.")

    out_path = args.output or args.input.with_suffix(".mif")

    print(f"Reading  {args.input} …")
    data = parse_mem(args.input)

    if not data:
        print("[warn] No data found in .mem file — generating empty .mif.")

    depth = args.depth if args.depth is not None else infer_depth(data)
    width = args.width if args.width is not None else infer_width(data)

    # Warn about addresses that exceed the declared depth
    out_of_range = [a for a in data if a >= depth]
    if out_of_range:
        print(f"[warn] {len(out_of_range)} address(es) exceed depth={depth} and will be omitted.",
              file=sys.stderr)

    print(f"Writing  {out_path}  (depth={depth}, width={width}) …")
    write_mif(data, out_path, depth, width)
    print("Done.")


if __name__ == "__main__":
    main()
