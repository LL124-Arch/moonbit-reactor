"""Fail CI when the MoonBit compiler is older than the supported baseline."""

from __future__ import annotations

import re
import subprocess
import sys


MINIMUM_VERSION = (0, 10, 9)


def main() -> int:
    output = subprocess.check_output(["moonc", "-v"], text=True).strip()
    match = re.search(r"v(\d+)\.(\d+)\.(\d+)", output)
    if match is None:
        print(f"Unable to parse MoonBit compiler version: {output}")
        return 1

    version = tuple(map(int, match.groups()))
    if version < MINIMUM_VERSION:
        print(f"MoonBit compiler must be >= v0.10.9, got: {output}")
        return 1

    print(f"MoonBit compiler requirement satisfied: {output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
