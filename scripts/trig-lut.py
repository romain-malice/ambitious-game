import math
import argparse


def gen_mif(filename, values, data_width):
    depth = len(values)
    addr_width = int(math.ceil(math.log2(depth)))
    with open(filename, "w") as f:
        f.write(f"DEPTH = {depth};\n")
        f.write(f"WIDTH = {data_width};\n")
        f.write(f"ADDRESS_RADIX = UNS;\n")
        f.write(f"DATA_RADIX = DEC;\n")
        f.write(f"CONTENT BEGIN\n")
        for i, v in enumerate(values):
            f.write(f"    {i} : {v};\n")
        f.write(f"END;\n")


def main():
    parser = argparse.ArgumentParser(description="Generate sin/cos LUT .mif files")
    parser.add_argument(
        "--depth", type=int, default=256, help="Number of LUT entries (default: 256)"
    )
    parser.add_argument(
        "--frac-bits",
        type=int,
        default=10,
        help="Fixed-point fractional bits (default: 10)",
    )
    parser.add_argument("--cos-out", type=str, default="cos_lut.mif")
    parser.add_argument("--sin-out", type=str, default="sin_lut.mif")
    args = parser.parse_args()

    DEPTH = args.depth
    FRAC_BITS = args.frac_bits
    SCALE = 2**FRAC_BITS
    # +1 bit for sign
    DATA_WIDTH = FRAC_BITS + 1

    cos_vals = []
    sin_vals = []

    for i in range(DEPTH):
        angle = 2 * math.pi * i / DEPTH
        cos_fixed = int(round(math.cos(angle) * SCALE))
        sin_fixed = int(round(math.sin(angle) * SCALE))

        # Clamp to signed range [-SCALE, SCALE]
        cos_fixed = max(-SCALE, min(SCALE, cos_fixed))
        sin_fixed = max(-SCALE, min(SCALE, sin_fixed))

        # Store as two's complement unsigned for .mif
        if cos_fixed < 0:
            cos_fixed += 2**DATA_WIDTH
        if sin_fixed < 0:
            sin_fixed += 2**DATA_WIDTH

        cos_vals.append(cos_fixed)
        sin_vals.append(sin_fixed)

    gen_mif(args.cos_out, cos_vals, DATA_WIDTH)
    gen_mif(args.sin_out, sin_vals, DATA_WIDTH)

    print(f"Generated {args.cos_out} and {args.sin_out}")
    print(f"  Depth      : {DEPTH} entries")
    print(f"  FRAC_BITS  : {FRAC_BITS}")
    print(f"  Data width : {DATA_WIDTH} bits (signed, two's complement)")
    print(f"  Scale      : {SCALE} (= 1.0)")
    print(
        f"  Usage in VHDL: index with top {int(math.log2(DEPTH))} bits of your lookAngle"
    )


if __name__ == "__main__":
    main()
