#!/usr/bin/env python3
"""Convert a flat little-endian binary image into 32-bit word hex for $readmemh.

Usage:
    bin2hex.py <input.bin> <output.hex> [base_address]

The output contains one 32-bit hexadecimal word per line, suitable for
Verilog/SystemVerilog $readmemh into a 32-bit memory array.
"""
import sys
import struct

def main():
    if len(sys.argv) < 3:
        print("usage: bin2hex.py <input.bin> <output.hex> [base_address]", file=sys.stderr)
        return 2
    inp = sys.argv[1]
    outp = sys.argv[2]
    base = int(sys.argv[3], 0) if len(sys.argv) > 3 else 0

    with open(inp, "rb") as f:
        data = f.read()

    # Pad to a whole number of 32-bit words.
    if len(data) % 4:
        data = data + b"\x00" * (4 - (len(data) % 4))

    with open(outp, "w") as f:
        # Emit an address record for non-zero base addresses.
        if base:
            f.write("@%08x\n" % base)
        for i in range(0, len(data), 4):
            word = struct.unpack_from("<I", data, i)[0]
            f.write("%08x\n" % word)
    return 0

if __name__ == "__main__":
    sys.exit(main())
